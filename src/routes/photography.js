import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';
import { Errors } from '../utils/errors.js';
import { createCheckout, PRODUCTS } from '../services/monetization.js';

const router = Router();

const PACKAGES = [
  { id: 'basic', name: 'جلسة تصوير أساسية', price: PRODUCTS['photography:basic'].price, includes: ['حتى 10 صور', 'معاينة ميدانية', 'تسليم خلال 48 ساعة'], duration: '~1 ساعة' },
  { id: 'premium', name: 'جلسة تصوير احترافية', price: PRODUCTS['photography:premium'].price, includes: ['حتى 25 صورة', 'صور بزوايا واسعة', 'فيديو قصير', 'جولة 360° أساسية', 'تسليم خلال 72 ساعة'], duration: '~3 ساعات' }
];

router.get('/packages', (req, res) => {
  res.json({ success: true, packages: PACKAGES });
});

router.get('/bookings', protect, async (req, res) => {
  try {
    const bookings = await sql`
      SELECT id, "propertyId", "packageId", date, address, status, "createdAt"
      FROM photography_bookings WHERE "userId" = ${req.user.id}
      ORDER BY "createdAt" DESC LIMIT 20
    `;
    res.json({ success: true, bookings });
  } catch (err) {
    console.error('List bookings error:', err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

// Creates a pending booking + a payment checkout; confirmed after payment.
router.post('/book', protect, async (req, res) => {
  try {
    const { propertyId, date, address, packageId } = req.body;
    const pkg = PACKAGES.find((p) => p.id === packageId);
    if (!pkg) return res.status(400).json(Errors.custom('INVALID_PACKAGE', 'باقة التصوير غير موجودة').toJSON());
    if (!date) return res.status(400).json(Errors.custom('MISSING_DATE', 'يرجى تحديد الموعد').toJSON());

    const [prop] = await sql`SELECT id, "agentUserId" FROM properties WHERE id = ${propertyId}`;
    if (!prop) return res.status(404).json(Errors.notFound('العقار').toJSON());
    if (prop.agentUserId !== req.user.id && req.user.role !== 'admin' && req.user.role !== 'owner') {
      return res.status(403).json(Errors.forbidden('غير مصرح بهذا العقار').toJSON());
    }

    const [booking] = await sql`
      INSERT INTO photography_bookings ("userId", "propertyId", date, address, status)
      VALUES (${req.user.id}, ${propertyId}, ${date}, ${address || null}, 'pending')
      RETURNING id, "propertyId", date, status
    `;

    const checkout = await createCheckout({
      userId: req.user.id,
      productId: `photography:${pkg.id}`,
      productRef: String(booking.id)
    });

    res.json({ success: true, booking, package: pkg, ...checkout });
  } catch (err) {
    const map = { 400: 'INVALID_REQUEST', 403: 'FORBIDDEN', 404: 'NOT_FOUND', 502: 'PAYMENT_GATEWAY_ERROR' };
    res.status(err.status || 500).json(Errors.custom(map[err.status] || 'INTERNAL', err.message || 'خطأ داخلي').toJSON());
  }
});

export default router;
