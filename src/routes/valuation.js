import { Router } from 'express';
import { protect } from '../middleware/auth.js';
import { Errors } from '../utils/errors.js';
import { createCheckout, PRODUCTS } from '../services/monetization.js';
import aiRoutes from './ai.js';
import valuationReportRoutes from './valuationReports.js';

const router = Router();

// تقييم عقاري مدفوع: ينشئ دفعاً، وعند إتمامه يُحفظ تقرير تقييم كامل في valuation_reports.
router.post('/purchase', protect, async (req, res) => {
  try {
    const { propertyId } = req.body;
    if (!propertyId) return res.status(400).json(Errors.custom('MISSING_PROPERTY', 'معرف العقار مطلوب').toJSON());
    const product = PRODUCTS['valuation:report'];
    const result = await createCheckout({ userId: req.user.id, productId: 'valuation:report', propertyId });
    res.json({ success: true, ...result, product: { name: product.name, price: product.price } });
  } catch (err) {
    const map = { 400: 'INVALID_PRODUCT', 403: 'FORBIDDEN', 404: 'NOT_FOUND', 502: 'PAYMENT_GATEWAY_ERROR' };
    res.status(err.status || 500).json(Errors.custom(map[err.status] || 'INTERNAL', err.message || 'خطأ داخلي').toJSON());
  }
});

// تجميع مجموعة Valuation API: /estimate + /match + سجل التقارير المحفوظة.
router.use(aiRoutes);
router.use(valuationReportRoutes);

export default router;
