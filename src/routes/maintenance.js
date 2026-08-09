import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';
import { Errors } from '../utils/errors.js';

const router = Router();

const STATUSES = ['pending', 'assigned', 'in_progress', 'completed', 'cancelled'];

// قائمة طلبات الصيانة للمستخدم الحالي.
router.get('/', protect, async (req, res) => {
  try {
    const rows = await sql`
      SELECT m.*, p.title AS "propertyTitle", v.name AS "vendorName"
      FROM maintenance_requests m
      LEFT JOIN properties p ON p.id = m."propertyId"
      LEFT JOIN vendors v ON v.id = m."assignedVendorId"
      WHERE m."userId" = ${req.user.id}
      ORDER BY m.id DESC
    `;
    res.json({ success: true, requests: rows });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

// إنشاء طلب صيانة.
router.post('/', protect, async (req, res) => {
  try {
    const { propertyId, category, title, description = '', priority = 'medium' } = req.body;
    if (!category || !title) {
      return res.status(400).json({ code: 'VALIDATION_ERROR', message: 'الفئة والعنوان مطلوبان' });
    }
    const allowed = ['سباكة', 'كهرباء', 'تكييف', 'عمارة', 'عام'];
    if (!allowed.includes(category)) {
      return res.status(400).json({ code: 'VALIDATION_ERROR', message: 'فئة غير صالحة' });
    }
    if (!['low', 'medium', 'high', 'urgent'].includes(priority)) {
      return res.status(400).json({ code: 'VALIDATION_ERROR', message: 'أولوية غير صالحة' });
    }
    if (propertyId) {
      const [property] = await sql`SELECT id FROM properties WHERE id = ${Number(propertyId)}`;
      if (!property) return res.status(404).json(Errors.notFound('العقار').toJSON());
    }
    const [request] = await sql`
      INSERT INTO maintenance_requests ("userId", "propertyId", category, title, description, priority)
      VALUES (${req.user.id}, ${propertyId ? Number(propertyId) : null}, ${category}, ${title}, ${description}, ${priority})
      RETURNING *
    `;
    res.status(201).json({ success: true, request });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

// تحديث حالة طلب صيانة (المالك فقط).
router.patch('/:id/status', protect, async (req, res) => {
  try {
    const { status } = req.body;
    if (!STATUSES.includes(status)) {
      return res.status(400).json({ code: 'VALIDATION_ERROR', message: 'حالة غير صالحة' });
    }
    const [request] = await sql`
      UPDATE maintenance_requests
      SET status = ${status},
          "completedAt" = CASE WHEN ${status} = 'completed' THEN NOW() ELSE "completedAt" END,
          "updatedAt" = NOW()
      WHERE id = ${Number(req.params.id)} AND "userId" = ${req.user.id}
      RETURNING *
    `;
    if (!request) return res.status(404).json(Errors.notFound('الطلب').toJSON());
    res.json({ success: true, request });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

export default router;
