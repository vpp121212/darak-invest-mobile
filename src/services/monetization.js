import sql from '../config/database.js';
import { evaluateAVM } from './avm.js';
import { cacheDelPrefix } from './cache.js';

export const PRODUCTS = {
  'subscription:basic': { name: 'الباقة الأساسية', price: 0, category: 'subscription', days: 30, packageId: 'basic' },
  'subscription:pro': { name: 'الباقة الاحترافية', price: 99, category: 'subscription', days: 30, packageId: 'pro' },
  'subscription:enterprise': { name: 'باقة المؤسسات', price: 299, category: 'subscription', days: 30, packageId: 'enterprise' },
  'featured:listing': { name: 'إبراز إعلان (أسبوع)', price: 19, category: 'featured', days: 7 },
  'advertiser:starter': { name: 'باقة المعلن المبتدئة', price: 149, category: 'advertiser', credits: 5, packageId: 'starter' },
  'advertiser:premium': { name: 'باقة المعلن الاحترافية', price: 399, category: 'advertiser', credits: 20, packageId: 'premium' },
  'valuation:report': { name: 'تقرير تقييم عقاري', price: 49, category: 'valuation' },
  'photography:basic': { name: 'جلسة تصوير أساسية', price: 149, category: 'photography' },
  'photography:premium': { name: 'جلسة تصوير احترافية', price: 299, category: 'photography' }
};

const PACKAGE_TO_PRODUCT = { basic: 'subscription:basic', pro: 'subscription:pro', enterprise: 'subscription:enterprise' };

export function productForPackage(packageId) {
  return PACKAGE_TO_PRODUCT[packageId] || null;
}

export function catalog() {
  return Object.entries(PRODUCTS).map(([id, p]) => ({ id, ...p }));
}

const addDays = (days) => new Date(Date.now() + days * 86400000).toISOString().split('T')[0];
const addDaysIso = (days) => new Date(Date.now() + days * 86400000).toISOString();

async function assertPropertyAccess(userId, propertyId, role) {
  if (!propertyId) return null;
  const [prop] = await sql`SELECT id, "agentUserId" FROM properties WHERE id = ${propertyId}`;
  if (!prop) {
    const err = new Error('عقار غير موجود');
    err.status = 404;
    throw err;
  }
  if (prop.agentUserId !== userId && role !== 'admin' && role !== 'owner') {
    const err = new Error('غير مصرح بهذا العقار');
    err.status = 403;
    throw err;
  }
  return prop;
}

export async function createCheckout({ userId, productId, propertyId = null, productRef = null }) {
  const product = PRODUCTS[productId];
  if (!product) {
    const err = new Error('المنتج غير موجود');
    err.status = 400;
    throw err;
  }
  if (product.price === 0) {
    const err = new Error('هذا المنتج مجاني ولا يتطلب دفع');
    err.status = 400;
    throw err;
  }
  const [user] = await sql`SELECT name, email, phone, role FROM users WHERE id = ${userId}`;
  if (!user) {
    const err = new Error('المستخدم غير موجود');
    err.status = 404;
    throw err;
  }
  await assertPropertyAccess(userId, propertyId, user.role);

  const ref = propertyId ? String(propertyId) : productRef;
  const description = product.name;

  // Tap gateway — يستخدم تلقائيًا عند تعيين TAP_SECRET_KEY (إضافة اختيارية).
  if (process.env.TAP_SECRET_KEY) {
    try {
      const [payment] = await sql`
        INSERT INTO payments ("userId", amount, currency, status, "packageId", description, "productType", "productRef")
        VALUES (${userId}, ${product.price}, 'SAR', 'pending', 'none', ${description}, ${productId}, ${ref})
        RETURNING id
      `;
      const tapRes = await fetch('https://api.tap.company/v2/charges', {
        method: 'POST',
        headers: {
          'Authorization': 'Bearer ' + process.env.TAP_SECRET_KEY,
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          amount: product.price,
          currency: 'SAR',
          description,
          customer: {
            first_name: user.name || '',
            email: user.email || '',
            phone: { country_code: '966', number: user.phone || '' }
          },
          source: { id: 'src_all' },
          reference: { transaction: `darak-${payment.id}-${Date.now()}` },
          metadata: { paymentId: String(payment.id), userId: String(userId), productId, productRef: ref },
          post: { url: process.env.TAP_WEBHOOK_URL || 'https://darak-invest-backend-j6hy.onrender.com/api/payments/webhook' },
          redirect: { url: process.env.TAP_REDIRECT_URL || 'https://vpp121212.github.io/darak-invest-mobile/?payment=result' }
        })
      });
      const charge = await tapRes.json();
      if (!tapRes.ok) throw new Error(charge.errors?.[0]?.description || charge.message || 'Tap error');

      await sql`UPDATE payments SET "tapChargeId" = ${charge.id} WHERE id = ${payment.id}`;
      return { success: true, redirectUrl: charge.transaction?.url, id: charge.id, testMode: false };
    } catch (e) {
      console.error('Tap error:', e.message);
      const err = new Error('فشل الاتصال ببوابة الدفع');
      err.status = 502;
      throw err;
    }
  }

  if (process.env.MOYASAR_SECRET_KEY) {
    try {
      const moyasarRes = await fetch('https://api.moyasar.com/v1/invoices', {
        method: 'POST',
        headers: {
          'Authorization': 'Basic ' + Buffer.from(process.env.MOYASAR_SECRET_KEY + ':').toString('base64'),
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          amount: Math.round(product.price * 100),
          currency: 'SAR',
          description,
          callback_url: process.env.MOYASAR_CALLBACK_URL || 'https://darak-invest-backend-j6hy.onrender.com/api/payments/callback',
          metadata: { userId: String(userId), productId, productRef: ref }
        })
      });
      const invoice = await moyasarRes.json();
      if (!moyasarRes.ok) throw new Error(invoice.message || 'Moyasar error');

      await sql`
        INSERT INTO payments ("userId", amount, currency, status, "packageId", "moyasarId", description, "productType", "productRef")
        VALUES (${userId}, ${product.price}, 'SAR', 'pending', 'none', ${invoice.id}, ${description}, ${productId}, ${ref})
      `;
      return { success: true, invoiceUrl: invoice.url, id: invoice.id, testMode: false };
    } catch (e) {
      console.error('Moyasar error:', e.message);
      const err = new Error('فشل الاتصال ببوابة الدفع');
      err.status = 502;
      throw err;
    }
  }

  const [payment] = await sql`
    INSERT INTO payments ("userId", amount, currency, status, "packageId", description, "productType", "productRef")
    VALUES (${userId}, ${product.price}, 'SAR', 'pending', 'none', ${description}, ${productId}, ${ref})
    RETURNING id
  `;
  return { success: true, paymentId: payment.id, amount: product.price, testMode: true };
}

export async function fulfill(payment) {
  let productId = payment.productType || 'subscription';
  if (!PRODUCTS[productId]) {
    productId = PACKAGE_TO_PRODUCT[payment.packageId] || 'subscription:basic';
  }
  const product = PRODUCTS[productId];
  if (!product) return;

  const { userId, productRef } = payment;
  const now = new Date().toISOString();

  switch (product.category) {
    case 'subscription':
      await sql`
        UPDATE users SET package = ${product.packageId}, "packageExpiry" = ${addDays(product.days)} WHERE id = ${userId}
      `;
      break;
    case 'featured':
      if (productRef) {
        await sql`
          UPDATE properties SET "isFeatured" = 1, "featuredAt" = ${now}, "featuredExpiresAt" = ${addDaysIso(product.days)}
          WHERE id = ${productRef}
        `;
        await cacheDelPrefix('propsall');
      }
      break;
    case 'advertiser':
      await sql`
        UPDATE users SET "adCredits" = COALESCE("adCredits", 0) + ${product.credits}, "adPackage" = ${product.packageId}
        WHERE id = ${userId}
      `;
      break;
    case 'valuation': {
      if (productRef) {
        const [prop] = await sql`SELECT * FROM properties WHERE id = ${productRef}`;
        if (prop) {
          const val = await evaluateAVM({
            city: prop.city, district: prop.district, type: prop.type, purpose: prop.purpose,
            area: prop.area, rooms: prop.rooms, baths: prop.baths, year: prop.year, age: prop.age, price: prop.price
          });
          await sql`
            INSERT INTO valuation_reports ("userId", "propertyId", title, details, estimate, "minPrice", "maxPrice", confidence, "pulseData")
            VALUES (${userId}, ${productRef}, ${`تقرير تقييم: ${prop.title}`}, ${JSON.stringify(val.factors || [])},
              ${val.estimate || 0}, ${val.min || 0}, ${val.max || 0}, ${val.confidence || 0}, ${JSON.stringify(val)})
          `;
        }
      }
      break;
    }
    case 'photography':
      if (productRef) {
        await sql`
          UPDATE photography_bookings SET status = 'confirmed', "confirmedAt" = ${now}, "packageId" = ${productId}
          WHERE id = ${productRef} AND "userId" = ${userId}
        `;
      }
      break;
  }
}
