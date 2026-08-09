import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';
import { Errors } from '../utils/errors.js';

const router = Router();

// قائمة تقارير التقييم للمستخدم الحالي.
router.get('/', protect, async (req, res) => {
  try {
    const rows = await sql`
      SELECT v.*, p.title AS "propertyTitle"
      FROM valuation_reports v
      LEFT JOIN properties p ON p.id = v."propertyId"
      WHERE v."userId" = ${req.user.id}
      ORDER BY v.id DESC
    `;
    res.json({ success: true, reports: rows });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

// حفظ تقرير تقييم عقاري.
router.post('/', protect, async (req, res) => {
  try {
    const { propertyId, title = '', details = [], estimate = 0, minPrice = 0, maxPrice = 0, confidence = 0, pulseData = {} } = req.body;
    if (!estimate) {
      return res.status(400).json({ code: 'VALIDATION_ERROR', message: 'قيمة التقدير مطلوبة' });
    }
    if (propertyId) {
      const [property] = await sql`SELECT id FROM properties WHERE id = ${Number(propertyId)}`;
      if (!property) return res.status(404).json(Errors.notFound('العقار').toJSON());
    }
    const [report] = await sql`
      INSERT INTO valuation_reports ("userId", "propertyId", title, details, estimate, minPrice, maxPrice, confidence, "pulseData")
      VALUES (${req.user.id}, ${propertyId ? Number(propertyId) : null}, ${title}, ${JSON.stringify(details)}, ${estimate}, ${minPrice}, ${maxPrice}, ${confidence}, ${JSON.stringify(pulseData)})
      RETURNING *
    `;
    res.status(201).json({ success: true, report });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

// تفاصيل تقرير واحد (المالك فقط).
router.get('/:id', protect, async (req, res) => {
  try {
    const [report] = await sql`
      SELECT * FROM valuation_reports WHERE id = ${Number(req.params.id)} AND "userId" = ${req.user.id}
    `;
    if (!report) return res.status(404).json(Errors.notFound('التقرير').toJSON());
    res.json({ success: true, report });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

export default router;
