import { Router } from 'express';
import sql from '../config/database.js';

const router = Router();

const SOURCES = [
  {
    name: 'منصة البيانات المفتوحة — الهيئة العامة للعقار',
    url: 'https://rega.gov.sa/البيانات-المفتوحة',
    description: 'مؤشرات الإيجار والبيع على مستوى المدن والأحياء (متوسط الأسعار وعدد العقود)',
    update: 'ربع سنوي'
  },
  {
    name: 'المؤشرات العقارية — الهيئة العامة للعقار',
    url: 'https://rei.rega.gov.sa',
    description: 'مؤشرات أسعار العقار ومتوسط أسعار المتر على مستوى الأحياء للمدن الرئيسية',
    update: 'ربع سنوي'
  },
  {
    name: 'الرئاسة العامة للإحصاء (GASTAT)',
    url: 'https://stats.gov.sa',
    description: 'مؤشر أسعار العقار في المملكة (مؤشر الإسكان) والنشرات الإحصائية الدورية',
    update: 'ربع سنوي'
  },
  {
    name: 'بوابة عقارات السعودية',
    url: 'https://saudiproperties.rega.gov.sa',
    description: 'منصة العرض الرسمية للعقارات السكنية والتجارية',
    update: 'مباشر'
  },
  {
    name: 'منصة إيجار',
    url: 'https://ejar.sa',
    description: 'تسجيل عقود الإيجار الموثقة وبيانات سوق الإيجار',
    update: 'مباشر'
  },
  {
    name: 'بنك البيانات الوطني — البيانات المفتوحة',
    url: 'https://open.data.gov.sa',
    description: 'مجموعات البيانات المفتوحة لجميع الجهات الحكومية',
    update: 'مباشر'
  }
];

router.get('/sources', (req, res) => {
  res.json({ success: true, sources: SOURCES });
});

router.get('/official', async (req, res) => {
  try {
    const { city, district, type = 'rent', limit = 12 } = req.query;
    const conditions = [];
    const params = [];
    if (city) { params.push(city); conditions.push(`city = $${params.length}`); }
    if (district) { params.push(district); conditions.push(`district = $${params.length}`); }
    params.push(type);
    conditions.push(`indicator_type = $${params.length}`);
    params.push(limit);
    conditions.push(`deals > 0`);
    const where = conditions.length ? 'WHERE ' + conditions.join(' AND ') : '';
    const rows = await sql.unsafe(`
      SELECT indicator_type, year, quarter, region, city, district, property_type, category, deals, avg_value, avg_per_m2, source, source_url, notes
      FROM official_indicators ${where}
      ORDER BY year DESC, quarter DESC, deals DESC
      LIMIT $${params.length}
    `, params);
    res.json({
      success: true,
      indicators: rows,
      disclaimer: 'بيانات رسمية من الهيئة العامة للعقار — منصة البيانات المفتوحة. للمراجعة الكاملة اضغط على المصدر.'
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'خطأ داخلي' });
  }
});

router.get('/district/:district', async (req, res) => {
  try {
    const clean = req.params.district.replace(/^(حي\s+)/, '');
    const rows = await sql`
      SELECT year, quarter, region, city, district, property_type, deals, avg_value, avg_per_m2, source, source_url
      FROM official_indicators
      WHERE indicator_type = 'rent' AND deals > 0 AND (district = ${clean} OR district = ${'حي ' + clean})
      ORDER BY year DESC, quarter DESC, deals DESC
      LIMIT 20
    `;
    if (!rows.length) {
      return res.json({ success: true, indicators: [], disclaimer: 'لا توجد بيانات رسمية منشورة لهذا الحي في فترة التحديث الحالية' });
    }
    res.json({
      success: true,
      indicators: rows,
      disclaimer: 'بيانات رسمية من الهيئة العامة للعقار — الربع الأول 2026'
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'خطأ داخلي' });
  }
});

router.get('/city/:city', async (req, res) => {
  try {
    const rows = await sql`
      SELECT year, quarter, region, city, district, property_type, deals, avg_value, avg_per_m2, source, source_url
      FROM official_indicators
      WHERE city = ${req.params.city} AND deals > 0
      ORDER BY year DESC, quarter DESC, deals DESC
      LIMIT 30
    `;
    res.json({
      success: true,
      indicators: rows,
      disclaimer: 'بيانات رسمية من الهيئة العامة للعقار — منصة البيانات المفتوحة'
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'خطأ داخلي' });
  }
});

export default router;
