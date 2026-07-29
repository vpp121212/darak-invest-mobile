import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';
import { Errors } from '../utils/errors.js';

const router = Router();

const PACKAGES = {
  basic: { name: 'الأساسي', price: 0 },
  pro: { name: 'الاحترافي', price: 99 },
  enterprise: { name: 'المؤسسات', price: 299 }
};

router.get('/config', (req, res) => {
  res.json({
    publishableKey: process.env.MOYASAR_PUBLISHABLE_KEY || '',
    testMode: !process.env.MOYASAR_PUBLISHABLE_KEY
  });
});

router.post('/create-intent', protect, async (req, res) => {
  try {
    const { packageId } = req.body;
    const pkg = PACKAGES[packageId];
    if (!pkg) return res.status(400).json(Errors.custom('INVALID_PACKAGE', 'الباقة غير موجودة').toJSON());
    if (pkg.price === 0) return res.status(400).json(Errors.custom('FREE_PACKAGE', 'الباقة مجانية لا تتطلب دفع').toJSON());

    const [user] = await sql`SELECT name, email, phone FROM users WHERE id = ${req.user.id}`;
    if (!user) return res.status(404).json(Errors.custom('USER_NOT_FOUND', 'المستخدم غير موجود').toJSON());

    const amount = pkg.price * 100;
    if (process.env.MOYASAR_SECRET_KEY) {
      try {
        const moyasarRes = await fetch('https://api.moyasar.com/v1/invoices', {
          method: 'POST',
          headers: {
            'Authorization': 'Basic ' + Buffer.from(process.env.MOYASAR_SECRET_KEY + ':').toString('base64'),
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            amount,
            currency: 'SAR',
            description: `باقة ${pkg.name} - شهر واحد`,
            callback_url: process.env.MOYASAR_CALLBACK_URL || 'https://darak-invest-backend-j6hy.onrender.com/api/payments/callback',
            metadata: { userId: String(req.user.id), packageId }
          })
        });
        const invoice = await moyasarRes.json();
        if (!moyasarRes.ok) throw new Error(invoice.message || 'Moyasar error');

        await sql`
          INSERT INTO payments ("userId", amount, currency, status, "packageId", "moyasarId", description)
          VALUES (${req.user.id}, ${pkg.price}, 'SAR', 'pending', ${packageId}, ${invoice.id}, ${`باقة ${pkg.name}`})
        `;
        return res.json({ success: true, invoiceUrl: invoice.url, id: invoice.id, testMode: false });
      } catch (e) {
        console.error('Moyasar error:', e);
        return res.status(502).json(Errors.custom('PAYMENT_GATEWAY_ERROR', 'فشل الاتصال ببوابة الدفع').toJSON());
      }
    }

    const [payment] = await sql`
      INSERT INTO payments ("userId", amount, currency, status, "packageId", description)
      VALUES (${req.user.id}, ${pkg.price}, 'SAR', 'pending', ${packageId}, ${`باقة ${pkg.name}`})
      RETURNING id
    `;
    res.json({ success: true, paymentId: payment.id, amount: pkg.price, testMode: true });
  } catch (err) {
    console.error('Create intent error:', err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

router.post('/confirm', protect, async (req, res) => {
  try {
    const { paymentId, card } = req.body;

    if (process.env.MOYASAR_SECRET_KEY) {
      return res.status(400).json(Errors.custom('USE_MOYASAR', 'استخدم بوابة الدفع لإتمام الدفع').toJSON());
    }

    if (!card || !card.number || !card.cvc || !card.month || !card.year) {
      return res.status(400).json(Errors.custom('INVALID_CARD', 'بيانات البطاقة غير مكتملة').toJSON());
    }

    const [payment] = await sql`SELECT * FROM payments WHERE id = ${paymentId} AND "userId" = ${req.user.id} AND status = 'pending'`;
    if (!payment) return res.status(404).json(Errors.custom('PAYMENT_NOT_FOUND', 'الدفعة غير موجودة').toJSON());

    const pkg = PACKAGES[payment.packageId];
    if (!pkg) return res.status(400).json(Errors.custom('INVALID_PACKAGE', 'الباقة غير موجودة').toJSON());

    await sql`
      UPDATE payments SET status = 'paid', "paymentMethod" = 'card', "paidAt" = NOW() WHERE id = ${paymentId}
    `;

    await sql`
      UPDATE users SET package = ${payment.packageId}, "packageExpiry" = ${new Date(Date.now() + 30 * 86400000).toISOString().split('T')[0]} WHERE id = ${req.user.id}
    `;

    res.json({ success: true, message: 'تم الدفع والاشتراك بنجاح ✓', package: pkg });
  } catch (err) {
    console.error('Confirm payment error:', err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

router.post('/callback', async (req, res) => {
  try {
    const { id, status, metadata } = req.body;
    if (!id) return res.status(400).json({ error: 'Missing id' });

    if (status === 'paid') {
      const userId = metadata?.userId;
      const packageId = metadata?.packageId;
      if (userId && packageId) {
        await sql`UPDATE payments SET status = 'paid', "paidAt" = NOW() WHERE "moyasarId" = ${id}`;
        await sql`UPDATE users SET package = ${packageId}, "packageExpiry" = ${new Date(Date.now() + 30 * 86400000).toISOString().split('T')[0]} WHERE id = ${userId}`;
      }
    }
    res.json({ success: true });
  } catch (err) {
    console.error('Callback error:', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

export default router;
