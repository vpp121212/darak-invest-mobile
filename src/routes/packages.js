import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';

const router = Router();

const packages = [
  { id: 'basic', name: 'الأساسي', price: 0, period: 'مجاني', features: ['إعلان واحد', 'صور حتى 5', 'عرض أساسي'], limit: 1 },
  { id: 'pro', name: 'الاحترافي', price: 99, period: '/شهري', features: ['10 إعلانات', 'صور حتى 15', 'دعم أولوية', 'إحصائيات', ' badges موثق'], limit: 10 },
  { id: 'enterprise', name: 'المؤسسات', price: 299, period: '/شهري', features: ['إعلانات غير محدودة', 'صور غير محدودة', 'مدير حساب مخصص', 'API access', 'تقرير مبيعات', ' badge حصري'], limit: -1 }
];

router.get('/', (req, res) => {
  res.json({ success: true, packages });
});

router.post('/subscribe', protect, async (req, res) => {
  try {
    const { packageId } = req.body;
    const pkg = packages.find(p => p.id === packageId);
    if (!pkg) return res.status(400).json({ error: 'الباقة غير موجودة' });
    if (pkg.price > 0) {
      return res.status(400).json({ code: 'PAID_PACKAGE', error: 'الباقات المدفوعة تتطلب الدفع عبر بوابة الدفع' });
    }
    await sql`
      UPDATE users SET package = 'basic', "packageExpiry" = NULL WHERE id = ${req.user.id}
    `;
    res.json({ success: true, message: 'تم الاشتراك بنجاح', package: pkg });
  } catch (err) { res.status(500).json({ error: 'خطأ داخلي' }); }
});

export default router;
