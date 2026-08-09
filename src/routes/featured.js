import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';
import { Errors } from '../utils/errors.js';
import { createCheckout, PRODUCTS } from '../services/monetization.js';
import { cacheDelPrefix } from '../services/cache.js';

const router = Router();
const FEATURED = PRODUCTS['featured:listing'];

router.get('/config', async (req, res) => {
  res.json({
    success: true,
    price: FEATURED.price,
    durationDays: FEATURED.days,
    name: FEATURED.name
  });
});

// Uses a purchased advertiser credit instead of a new payment.
router.post('/boost', protect, async (req, res) => {
  try {
    const { propertyId } = req.body;
    if (!propertyId) return res.status(400).json(Errors.custom('MISSING_PROPERTY', 'معرف العقار مطلوب').toJSON());

    const [prop] = await sql`SELECT id, "agentUserId" FROM properties WHERE id = ${propertyId}`;
    if (!prop) return res.status(404).json(Errors.notFound('العقار').toJSON());
    if (prop.agentUserId !== req.user.id && req.user.role !== 'admin' && req.user.role !== 'owner') {
      return res.status(403).json(Errors.forbidden('غير مصرح بهذا العقار').toJSON());
    }

    const [user] = await sql`SELECT "adCredits", "adPackage" FROM users WHERE id = ${req.user.id}`;
    if (!user || (user.adCredits || 0) <= 0) {
      return res.status(400).json(Errors.custom('NO_CREDITS', 'لا تملك رصيد إبرازات. اشترِ باقة معلن أو ادفع مقابل إبراز.').toJSON());
    }

    await sql`UPDATE users SET "adCredits" = "adCredits" - 1 WHERE id = ${req.user.id}`;
    await sql`
      UPDATE properties SET "isFeatured" = 1, "featuredAt" = NOW(), "featuredExpiresAt" = NOW() + INTERVAL '7 days'
      WHERE id = ${propertyId}
    `;
    await cacheDelPrefix('propsall');

    res.json({ success: true, message: 'تم إبراز الإعلان لمدة 7 أيام ✓', remainingCredits: (user.adCredits || 0) - 1 });
  } catch (err) {
    console.error('Boost error:', err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

// Direct purchase of a single featured slot.
router.post('/purchase', protect, async (req, res) => {
  try {
    const { propertyId } = req.body;
    if (!propertyId) return res.status(400).json(Errors.custom('MISSING_PROPERTY', 'معرف العقار مطلوب').toJSON());
    const result = await createCheckout({ userId: req.user.id, productId: 'featured:listing', propertyId });
    res.json({ success: true, ...result, product: { name: FEATURED.name, price: FEATURED.price, durationDays: FEATURED.days } });
  } catch (err) {
    const map = { 400: 'INVALID_PRODUCT', 403: 'FORBIDDEN', 404: 'NOT_FOUND', 502: 'PAYMENT_GATEWAY_ERROR' };
    res.status(err.status || 500).json(Errors.custom(map[err.status] || 'INTERNAL', err.message || 'خطأ داخلي').toJSON());
  }
});

export default router;
