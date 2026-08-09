import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';
import { Errors } from '../utils/errors.js';
import { createCheckout, fulfill, productForPackage, PRODUCTS } from '../services/monetization.js';

const router = Router();

router.get('/config', (req, res) => {
  res.json({
    publishableKey: process.env.MOYASAR_PUBLISHABLE_KEY || '',
    testMode: !process.env.MOYASAR_PUBLISHABLE_KEY
  });
});

router.get('/', protect, async (req, res) => {
  try {
    const payments = await sql`
      SELECT id, amount, currency, status, "packageId", "productType", "productRef", description, "paymentMethod", "paidAt", "createdAt"
      FROM payments WHERE "userId" = ${req.user.id}
      ORDER BY "createdAt" DESC LIMIT 30
    `;
    res.json({ success: true, payments });
  } catch (err) {
    console.error('List payments error:', err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

// Accepts productId (e.g. featured:listing, advertiser:starter, valuation:report, photography:premium)
// OR legacy packageId (basic/pro/enterprise) for subscription purchases.
router.post('/create-intent', protect, async (req, res) => {
  try {
    const { packageId, productId, propertyId, productRef } = req.body;
    let pid = productId;
    if (!pid && packageId) pid = productForPackage(packageId);
    if (!pid) return res.status(400).json(Errors.custom('INVALID_PRODUCT', 'المنتج غير موجود').toJSON());

    const result = await createCheckout({ userId: req.user.id, productId: pid, propertyId, productRef });
    return res.json({ success: true, ...result });
  } catch (err) {
    const map = { 400: 'INVALID_PRODUCT', 403: 'FORBIDDEN', 404: 'NOT_FOUND', 502: 'PAYMENT_GATEWAY_ERROR' };
    res.status(err.status || 500).json(Errors.custom(map[err.status] || 'INTERNAL', err.message || 'خطأ داخلي').toJSON());
  }
});

router.post('/test-complete', protect, async (req, res) => {
  try {
    if (process.env.MOYASAR_SECRET_KEY) {
      return res.status(400).json(Errors.custom('USE_MOYASAR', 'استخدم بوابة الدفع لإتمام الدفع').toJSON());
    }

    const { paymentId } = req.body;
    const [payment] = await sql`SELECT * FROM payments WHERE id = ${paymentId} AND "userId" = ${req.user.id} AND status = 'pending'`;
    if (!payment) return res.status(404).json(Errors.custom('PAYMENT_NOT_FOUND', 'الدفعة غير موجودة').toJSON());

    await fulfill(payment);
    await sql`
      UPDATE payments SET status = 'paid', "paymentMethod" = 'test', "paidAt" = NOW() WHERE id = ${paymentId}
    `;

    res.json({
      success: true,
      message: 'تم إتمام العملية تجريبياً ✓',
      product: PRODUCTS[payment.productType] || { name: 'المنتج' }
    });
  } catch (err) {
    console.error('Complete test payment error:', err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

router.all('/callback', async (req, res) => {
  try {
    const id = req.body && req.body.id ? req.body.id : req.query && req.query.id;
    if (!id) return res.status(400).json({ error: 'Missing id' });

    if (!process.env.MOYASAR_SECRET_KEY) return res.json({ success: true, ignored: true });

    const moyasarRes = await fetch(`https://api.moyasar.com/v1/invoices/${encodeURIComponent(id)}`, {
      headers: {
        'Authorization': 'Basic ' + Buffer.from(process.env.MOYASAR_SECRET_KEY + ':').toString('base64')
      }
    });
    if (!moyasarRes.ok) return res.status(502).json({ error: 'Verification failed' });
    const invoice = await moyasarRes.json();

    let paid = invoice.status === 'paid';
    if (paid) {
      const [payment] = await sql`SELECT * FROM payments WHERE "moyasarId" = ${id} AND status = 'pending'`;
      if (payment) {
        await fulfill(payment);
        await sql`UPDATE payments SET status = 'paid', "paidAt" = NOW() WHERE id = ${payment.id}`;
      } else {
        paid = false;
      }
    }

    if (req.accepts('html')) {
      return res.redirect(`/?payment=${paid ? 'success' : 'failed'}`);
    }
    res.json({ success: true, paid });
  } catch (err) {
    console.error('Callback error:', err);
    if (req.accepts('html')) return res.redirect('/?payment=failed');
    res.status(500).json({ error: 'Internal error' });
  }
});

export default router;
