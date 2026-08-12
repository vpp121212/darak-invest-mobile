/**
 * Darak Invest — Tap Payment Webhook Handler
 * المسار: POST /api/payments/webhook
 *
 * الوظيفة: استقبال تأكيدات الدفع من بوابة Tap وتحديث حالة الدفع ومنح
 * المنتج (fulfill) وإشعار المستخدم، بشكل آمن وتلقائي مع منع التكرار.
 *
 * الأمان (إلزامي):
 *   Tap يوقّع كل إشعار برأس "hashstring" — وهو HMAC-SHA256 (hex) فوق
 *   سلسلة حقول محددة من الـ payload باستخدام TAP_SECRET_KEY.
 *   المرجع: https://developers.tap.company/docs/webhook (Validate the webhook)
 *   كما نتحقق كاحتياط من رأس "hash" (HMAC فوق الـ raw body) لأن بعض
 *   الإعدادات ترسله أيضًا.
 *
 * متغيرات البيئة المطلوبة:
 *   TAP_SECRET_KEY   — المفتاح السري من لوحة Tap (sk_test_... / sk_live_...)
 *   TAP_WEBHOOK_URL  — عنوان هذا الـ endpoint (يُرسل ضمن post.url عند إنشاء الدفعة)
 *   TAP_REDIRECT_URL — صفحة العودة بعد الدفع
 *
 * ملاحظة: عند عدم تعيين TAP_SECRET_KEY:
 *   - في بيئة الإنتاج (NODE_ENV=production) نرفض الإشعارات (401) — لا نقبل
 *     طلبات غير موقّعة.
 *   - في بيئة التطوير نسمح بها مع تحذير لتسهيل الاختبار.
 */
import { Router } from 'express';
import express from 'express';
import crypto from 'crypto';
import sql from '../config/database.js';
import { fulfill } from '../services/monetization.js';

const router = Router();

// عدد الخانات العشرية القياسية لعملات Tap (الافتراضي: 2).
const DECIMAL_PLACES = { KWD: 3, BHD: 3, OMR: 3, JOD: 3 };

export function formatTapAmount(amount, currency = 'SAR') {
  const n = Number(amount);
  if (!Number.isFinite(n)) return String(amount);
  return n.toFixed(DECIMAL_PLACES[currency] || 2);
}

/**
 * بناء السلسلة التي يوقّع عليها Tap (hashstring) حسب التوثيق الرسمي:
 * x_id + id + x_amount + amount + x_currency + currency
 *   + x_gateway_reference + reference.gateway
 *   + x_payment_reference + reference.payment
 *   + x_status + status + x_created + transaction.created
 */
export function buildTapHashString(payload) {
  const id = payload?.id ?? '';
  const amount = formatTapAmount(payload?.amount, payload?.currency);
  const currency = payload?.currency ?? '';
  const gatewayRef = payload?.reference?.gateway ?? '';
  const paymentRef = payload?.reference?.payment ?? '';
  const status = payload?.status ?? '';
  const created = payload?.transaction?.created ?? payload?.created ?? '';
  return (
    'x_id' + id +
    'x_amount' + amount +
    'x_currency' + currency +
    'x_gateway_reference' + gatewayRef +
    'x_payment_reference' + paymentRef +
    'x_status' + status +
    'x_created' + created
  );
}

export function hmacHex(data, secret) {
  return crypto.createHmac('sha256', secret).update(data).digest('hex');
}

function safeEqual(a, b) {
  const ba = Buffer.from(a || '');
  const bb = Buffer.from(b || '');
  return ba.length === bb.length && crypto.timingSafeEqual(ba, bb);
}

/**
 * التحقق من توقيع الإشعار.
 * 1) hashstring: HMAC-SHA256(سلسلة الحقول المبنية) — الطريقة الرسمية.
 * 2) hash:       HMAC-SHA256(raw body) — احتياط لبعض الإعدادات.
 */
export function verifyTapSignature({ payload, rawBody, headers, env = process.env }) {
  const secret = env.TAP_SECRET_KEY;
  if (!secret) {
    if (env.NODE_ENV === 'production') return false;
    console.warn('[webhook] ⚠️ TAP_SECRET_KEY غير مضبوط — قبول الإشعار بدون تحقق (بيئة تطوير فقط)');
    return true;
  }

  const hashstring = headers['hashstring'];
  const rawHash = headers['hash'];
  const toBeHashed = buildTapHashString(payload);

  if (hashstring && safeEqual(hashstring, hmacHex(toBeHashed, secret))) return true;
  if (rawHash && rawBody && safeEqual(rawHash, hmacHex(rawBody.toString('utf8'), secret))) return true;

  console.warn('[webhook] ❌ توقيع غير صالح:', { hashstring, rawHash, toBeHashed });
  return false;
}

async function notify(userId, title, message, type = 'payment') {
  if (!userId) return;
  try {
    await sql`INSERT INTO notifications ("userId", title, message, type)
              VALUES (${userId}, ${title}, ${message}, ${type})`;
  } catch (err) {
    console.error('[webhook][notify]', err.message);
  }
}

/**
 * POST /api/payments/webhook — يستقبل payload من Tap.
 * نستخدم express.raw() للحصول على الـ raw body (مطلوب للتحقق من التوقيع)
 * قبل أي JSON parser.
 */
router.post('/', express.raw({ type: () => true, limit: '1mb' }), async (req, res) => {
  const rawBody = req.body;

  let payload;
  try {
    payload = JSON.parse(rawBody.toString('utf8'));
  } catch {
    return res.status(400).json({ error: 'Invalid JSON body' });
  }

  if (!verifyTapSignature({ payload, rawBody, headers: req.headers })) {
    return res.status(401).json({ error: 'Invalid signature' });
  }

  const chargeId = payload.id;
  const status = payload.status;
  const metadata = payload.metadata || {};

  try {
    // 1. تحديد الدفعة المرتبطة بالعملية.
    let payment = null;
    if (metadata.paymentId && Number.isFinite(Number(metadata.paymentId))) {
      [payment] = await sql`SELECT * FROM payments WHERE id = ${Number(metadata.paymentId)}`;
    }
    if (!payment && chargeId) {
      [payment] = await sql`SELECT * FROM payments WHERE "tapChargeId" = ${chargeId}`;
    }

    // 2. معالجة الحالة وتحديث قاعدة البيانات.
    switch (status) {
      case 'CAPTURED':
      case 'AUTHORIZED': {
        if (!payment) {
          // عملية غير معروفة (لم تُنشأ دفعة لدينا أو وصلت خارج الترتيب).
          // نؤكد الاستلام بـ 200 حتى لا يعيد Tap الإرسال.
          console.warn(`[webhook] عملية غير معروفة: ${chargeId}`);
          return res.json({ success: true, acknowledged: true });
        }
        if (payment.status === 'pending') {
          // Guard الشرط status='pending' يضمن عدم التكرار عند وصول الإشعار مرتين.
          const [updated] = await sql`
            UPDATE payments SET status = 'paid', "tapChargeId" = ${chargeId},
              "paymentMethod" = 'tap', "paidAt" = NOW()
            WHERE id = ${payment.id} AND status = 'pending'
            RETURNING *
          `;
          if (updated) {
            await fulfill(updated);
            await notify(payment.userId, 'تم الدفع بنجاح', 'تم استلام دفعتك بنجاح وإتمام طلبك ✓');
            console.log(`✅ نجاح الدفع للعملية: ${chargeId} — دفعة #${payment.id} محققة.`);
          }
        }
        break;
      }

      case 'FAILED':
      case 'DECLINED':
      case 'TIMEDOUT':
      case 'RESTRICTED':
      case 'CANCELLED':
      case 'VOID': {
        const failed = !['CANCELLED', 'VOID'].includes(status);
        if (payment && payment.status === 'pending') {
          await sql`
            UPDATE payments SET status = ${failed ? 'failed' : 'cancelled'},
              "tapChargeId" = ${chargeId}
            WHERE id = ${payment.id} AND status = 'pending'
          `;
        }
        console.warn(`[webhook] عملية ${status}: ${chargeId}`);
        break;
      }

      default:
        // INITIATED / ABANDONED / UNKNOWN — لا يتطلب إجراء.
        console.log(`[webhook] حالة لا تتطلب إجراء: ${status} (${chargeId})`);
        break;
    }

    // 3. تأكيد الاستلام للبوابة (يمنع إعادة الإرسال).
    res.json({ success: true });
  } catch (err) {
    // 500 فقط لخطأ تقني يدفع البوابة لإعادة المحاولة.
    console.error('[webhook] خطأ أثناء المعالجة:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
