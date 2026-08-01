import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { createInvoiceSchema, updateInvoiceSchema, createVendorSchema } from '../validators/business.js';
import { Errors } from '../utils/errors.js';

const router = Router();

router.get('/invoices', protect, async (req, res) => {
  try {
    const { status, type, page = 1, limit = 20 } = req.query;
    let conditions = ['"userId" = $1'];
    let params = [req.userId];
    let idx = 2;
    if (status) { conditions.push(`status = $${idx++}`); params.push(status); }
    if (type) { conditions.push(`type = $${idx++}`); params.push(type); }

    const offset = (Number(page) - 1) * Number(limit);
    const invoices = await sql.unsafe(
      `SELECT * FROM invoices WHERE ${conditions.join(' AND ')} ORDER BY "createdAt" DESC LIMIT $${idx++} OFFSET $${idx++}`,
      [...params, Number(limit), offset]
    );

    const [{ total }] = await sql.unsafe(
      `SELECT COUNT(*)::int as total FROM invoices WHERE ${conditions.join(' AND ')}`,
      params
    );

    const [stats] = await sql.unsafe(`
      SELECT
        COALESCE(SUM(CASE WHEN status = 'مدفوعة' THEN amount ELSE 0 END), 0) as paid,
        COALESCE(SUM(CASE WHEN status = 'معلقة' THEN amount ELSE 0 END), 0) as pending,
        COALESCE(SUM(CASE WHEN status = 'متأخرة' THEN amount ELSE 0 END), 0) as overdue,
        COUNT(*)::int as count
      FROM invoices WHERE "userId" = $1
    `, [req.userId]);

    res.json({ success: true, invoices, total, stats });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.post('/invoices', protect, validate.body(createInvoiceSchema), async (req, res) => {
  try {
    const { type, amount, description, clientName, clientPhone, propertyId, dueDate } = req.body;
    const [{ id }] = await sql`
      INSERT INTO invoices ("userId", "propertyId", type, amount, description, "clientName", "clientPhone", "dueDate")
      VALUES (${req.userId}, ${propertyId || null}, ${type}, ${amount}, ${description || ''}, ${clientName || ''}, ${clientPhone || ''}, ${dueDate || null})
      RETURNING id
    `;
    res.json({ success: true, id, message: 'تم إضافة الفاتورة' });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.put('/invoices/:id', protect, validate.body(updateInvoiceSchema), async (req, res) => {
  try {
    const { status, paidAt } = req.body;
    const updates = [];
    let params = [];
    let idx = 0;
    if (status) { updates.push(`status = $${++idx}`); params.push(status); }
    if (paidAt) { updates.push(`"paidAt" = $${++idx}`); params.push(paidAt); }
    if (status === 'مدفوعة' && !paidAt) { updates.push(`"paidAt" = NOW()`); }
    if (updates.length === 0) return res.status(400).json(Errors.custom('NO_UPDATES', 'لا توجد تحديثات').toJSON());

    params.push(req.params.id, req.userId);
    await sql.unsafe(
      `UPDATE invoices SET ${updates.join(', ')} WHERE id = $${++idx} AND "userId" = $${++idx}`,
      params
    );
    res.json({ success: true, message: 'تم تحديث الفاتورة' });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.delete('/invoices/:id', protect, async (req, res) => {
  try {
    await sql`DELETE FROM invoices WHERE id = ${req.params.id} AND "userId" = ${req.userId}`;
    res.json({ success: true, message: 'تم حذف الفاتورة' });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.get('/vendors', protect, async (req, res) => {
  try {
    const { category, search } = req.query;
    let conditions = ['"userId" = $1'];
    let params = [req.userId];
    let idx = 2;
    if (category) { conditions.push(`category = $${idx++}`); params.push(category); }
    if (search) { conditions.push(`(name ILIKE $${idx++} OR phone ILIKE $${idx++})`); params.push(`%${search}%`, `%${search}%`); }

    const vendors = await sql.unsafe(
      `SELECT * FROM vendors WHERE ${conditions.join(' AND ')} ORDER BY "totalDeals" DESC, rating DESC`,
      params
    );
    res.json({ success: true, vendors });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.post('/vendors', protect, validate.body(createVendorSchema), async (req, res) => {
  try {
    const { name, category, phone, email, city, notes } = req.body;

    const [{ id }] = await sql`
      INSERT INTO vendors ("userId", name, category, phone, email, city, notes)
      VALUES (${req.userId}, ${name}, ${category}, ${phone || ''}, ${email || ''}, ${city || ''}, ${notes || ''})
      RETURNING id
    `;
    res.json({ success: true, id, message: 'تم إضافة المورد' });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.put('/vendors/:id', protect, async (req, res) => {
  try {
    const { name, category, phone, email, city, rating, notes } = req.body;
    const updates = [];
    let params = [];
    let idx = 0;
    if (name) { updates.push(`name = $${++idx}`); params.push(name); }
    if (category) { updates.push(`category = $${++idx}`); params.push(category); }
    if (phone) { updates.push(`phone = $${++idx}`); params.push(phone); }
    if (email) { updates.push(`email = $${++idx}`); params.push(email); }
    if (city) { updates.push(`city = $${++idx}`); params.push(city); }
    if (rating !== undefined) { updates.push(`rating = $${++idx}`); params.push(rating); }
    if (notes) { updates.push(`notes = $${++idx}`); params.push(notes); }
    if (updates.length === 0) return res.status(400).json(Errors.custom('NO_UPDATES', 'لا توجد تحديثات').toJSON());

    params.push(req.params.id, req.userId);
    await sql.unsafe(
      `UPDATE vendors SET ${updates.join(', ')} WHERE id = $${++idx} AND "userId" = $${++idx}`,
      params
    );
    res.json({ success: true, message: 'تم تحديث المورد' });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.delete('/vendors/:id', protect, async (req, res) => {
  try {
    await sql`DELETE FROM vendors WHERE id = ${req.params.id} AND "userId" = ${req.userId}`;
    res.json({ success: true, message: 'تم حذف المورد' });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

export default router;
