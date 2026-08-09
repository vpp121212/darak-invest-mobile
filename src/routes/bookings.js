import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';
import { Errors } from '../utils/errors.js';

const router = Router();

const APPOINTMENT_TYPES = ['معاينة', 'استشارة', 'توقيع عقد'];
const APPOINTMENT_STATUSES = ['pending', 'confirmed', 'completed', 'cancelled'];
const OFFER_STATUSES = ['pending', 'accepted', 'rejected', 'cancelled'];

function parseImages(value) {
  if (Array.isArray(value)) return value;
  if (typeof value === 'string' && value.trim()) {
    try {
      const parsed = JSON.parse(value);
      return Array.isArray(parsed) ? parsed : [];
    } catch (_) {
      return [];
    }
  }
  return [];
}

function formatAppointment(row) {
  const { images, ...rest } = row;
  return { ...rest, images: parseImages(images) };
}

function formatOffer(row) {
  const { images, ...rest } = row;
  return { ...rest, images: parseImages(images) };
}

async function loadProperty(propertyId) {
  const [property] = await sql`SELECT id, title, "agentUserId", "agentPhone", "agentName" FROM properties WHERE id = ${propertyId}`;
  return property;
}

router.get('/', protect, async (req, res) => {
  try {
    const [asRequester, asAgent] = await Promise.all([
      sql`SELECT a.*, p.title AS "propertyTitle", p.city, p.district, p.images
          FROM appointments a LEFT JOIN properties p ON p.id = a."propertyId"
          WHERE a."userId" = ${req.user.id} ORDER BY a."createdAt" DESC`,
      sql`SELECT a.*, p.title AS "propertyTitle", p.city, p.district, p.images
          FROM appointments a LEFT JOIN properties p ON p.id = a."propertyId"
          WHERE a."agentUserId" = ${req.user.id} ORDER BY a."createdAt" DESC`,
    ]);
    const seen = new Set();
    const merged = [...asRequester, ...asAgent].filter((a) => {
      if (seen.has(a.id)) return false;
      seen.add(a.id);
      return true;
    });
    res.json({ success: true, appointments: merged.map(formatAppointment) });
  } catch (err) {
    console.error(err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

router.post('/', protect, async (req, res) => {
  try {
    const { propertyId, scheduledAt, type = 'معاينة', note = '' } = req.body;
    if (!propertyId || !scheduledAt) {
      return res.status(400).json({ code: 'VALIDATION_ERROR', message: 'العقار وتاريخ الموعد مطلوبان' });
    }
    if (!APPOINTMENT_TYPES.includes(type)) {
      return res.status(400).json({ code: 'VALIDATION_ERROR', message: 'نوع الموعد غير صالح' });
    }
    const property = await loadProperty(propertyId);
    if (!property) return res.status(404).json(Errors.notFound('العقار').toJSON());
    if (property.agentUserId === req.user.id) {
      return res.status(400).json({ code: 'VALIDATION_ERROR', message: 'لا يمكنك حجز موعد على عقارك الخاص' });
    }
    const [result] = await sql`
      INSERT INTO appointments ("userId", "propertyId", "agentUserId", type, "scheduledAt", note)
      VALUES (${req.user.id}, ${propertyId}, ${property.agentUserId}, ${type}, ${scheduledAt}, ${note})
      RETURNING id
    `;
    res.status(201).json({ success: true, id: result.id, message: 'تم إرسال طلب حجز الموعد، وسيؤكده الوسيط' });
  } catch (err) {
    console.error(err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

router.patch('/:id', protect, async (req, res) => {
  try {
    const { status } = req.body;
    if (!APPOINTMENT_STATUSES.includes(status)) {
      return res.status(400).json({ code: 'VALIDATION_ERROR', message: 'حالة غير صالحة' });
    }
    const [existing] = await sql`SELECT * FROM appointments WHERE id = ${req.params.id}`;
    if (!existing) return res.status(404).json(Errors.notFound('الموعد').toJSON());
    const isRequester = existing.userId === req.user.id;
    const isAgent = existing.agentUserId === req.user.id;
    if (!isRequester && !isAgent && req.user.role !== 'admin') {
      return res.status(403).json(Errors.forbidden('غير مصرح بتعديل هذا الموعد').toJSON());
    }
    if (status === 'cancelled' && isRequester && existing.status !== 'cancelled') {
      await sql`UPDATE appointments SET status = ${status}, "updatedAt" = NOW() WHERE id = ${req.params.id}`;
      return res.json({ success: true, message: 'تم إلغاء الموعد' });
    }
    if ((status === 'confirmed' || status === 'completed' || status === 'cancelled') && isAgent) {
      await sql`UPDATE appointments SET status = ${status}, "updatedAt" = NOW() WHERE id = ${req.params.id}`;
      return res.json({ success: true, message: 'تم تحديث حالة الموعد' });
    }
    return res.status(403).json(Errors.forbidden('لا تملك صلاحية لهذا الإجراء').toJSON());
  } catch (err) {
    console.error(err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

router.get('/offers', protect, async (req, res) => {
  try {
    const [asBuyer, asSeller] = await Promise.all([
      sql`SELECT o.*, p.title AS "propertyTitle", p.city, p.district, p.images, p."agentUserId" AS "propertyAgentUserId", u.name AS "buyerName", u.phone AS "buyerPhone"
          FROM offers o LEFT JOIN properties p ON p.id = o."propertyId"
          LEFT JOIN users u ON u.id = o."userId"
          WHERE o."userId" = ${req.user.id} ORDER BY o."createdAt" DESC`,
      sql`SELECT o.*, p.title AS "propertyTitle", p.city, p.district, p.images, p."agentUserId" AS "propertyAgentUserId", u.name AS "buyerName", u.phone AS "buyerPhone"
          FROM offers o LEFT JOIN properties p ON p.id = o."propertyId"
          LEFT JOIN users u ON u.id = o."userId"
          WHERE p."agentUserId" = ${req.user.id} ORDER BY o."createdAt" DESC`,
    ]);
    const seen = new Set();
    const merged = [...asBuyer, ...asSeller].filter((o) => {
      if (seen.has(o.id)) return false;
      seen.add(o.id);
      return true;
    });
    res.json({ success: true, offers: merged.map(formatOffer) });
  } catch (err) {
    console.error(err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

router.post('/offers', protect, async (req, res) => {
  try {
    const { propertyId, amount, paymentMethod = 'نقدي', note = '' } = req.body;
    if (!propertyId || !amount || Number(amount) <= 0) {
      return res.status(400).json({ code: 'VALIDATION_ERROR', message: 'العقار والمبلغ مطلوبان' });
    }
    const property = await loadProperty(propertyId);
    if (!property) return res.status(404).json(Errors.notFound('العقار').toJSON());
    if (property.agentUserId === req.user.id) {
      return res.status(400).json({ code: 'VALIDATION_ERROR', message: 'لا يمكنك تقديم عرض على عقارك الخاص' });
    }
    const [result] = await sql`
      INSERT INTO offers ("userId", "propertyId", amount, "paymentMethod", note)
      VALUES (${req.user.id}, ${propertyId}, ${Number(amount)}, ${paymentMethod}, ${note})
      RETURNING id
    `;
    res.status(201).json({ success: true, id: result.id, message: 'تم إرسال عرضك، وسيراجعه الوسيط' });
  } catch (err) {
    console.error(err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

router.patch('/offers/:id', protect, async (req, res) => {
  try {
    const { status } = req.body;
    if (!OFFER_STATUSES.includes(status)) {
      return res.status(400).json({ code: 'VALIDATION_ERROR', message: 'حالة غير صالحة' });
    }
    const [existing] = await sql`SELECT * FROM offers WHERE id = ${req.params.id}`;
    if (!existing) return res.status(404).json(Errors.notFound('العرض').toJSON());
    const [property] = await sql`SELECT "agentUserId" FROM properties WHERE id = ${existing.propertyId}`;
    const isBuyer = existing.userId === req.user.id;
    const isSeller = property?.agentUserId === req.user.id;
    if (!isBuyer && !isSeller && req.user.role !== 'admin') {
      return res.status(403).json(Errors.forbidden('غير مصرح بتعديل هذا العرض').toJSON());
    }
    if (status === 'cancelled' && isBuyer && existing.status === 'pending') {
      await sql`UPDATE offers SET status = ${status}, "updatedAt" = NOW() WHERE id = ${req.params.id}`;
      return res.json({ success: true, message: 'تم إلغاء العرض' });
    }
    if ((status === 'accepted' || status === 'rejected') && isSeller && existing.status === 'pending') {
      await sql`UPDATE offers SET status = ${status}, "updatedAt" = NOW() WHERE id = ${req.params.id}`;
      return res.json({ success: true, message: 'تم تحديث حالة العرض' });
    }
    return res.status(403).json(Errors.forbidden('لا تملك صلاحية لهذا الإجراء').toJSON());
  } catch (err) {
    console.error(err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

export default router;
