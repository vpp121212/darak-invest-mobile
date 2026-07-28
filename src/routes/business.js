import { Router } from 'express';
import db from '../config/database.js';
import { protect } from '../middleware/auth.js';

const router = Router();

router.get('/invoices', protect, (req, res) => {
  try {
    const { status, type, page = 1, limit = 20 } = req.query;
    let where = ['userId = ?'];
    const params = [req.userId];
    if (status) { where.push('status = ?'); params.push(status); }
    if (type) { where.push('type = ?'); params.push(type); }

    const sql = `SELECT * FROM invoices WHERE ${where.join(' AND ')} ORDER BY createdAt DESC LIMIT ? OFFSET ?`;
    const offset = (Number(page) - 1) * Number(limit);
    const invoices = db.prepare(sql).all(...params, Number(limit), offset);
    const { total } = db.prepare(`SELECT COUNT(*) as total FROM invoices WHERE ${where.join(' AND ')}`).get(...params);

    const stats = db.prepare(`
      SELECT
        SUM(CASE WHEN status = 'مدفوعة' THEN amount ELSE 0 END) as paid,
        SUM(CASE WHEN status = 'معلقة' THEN amount ELSE 0 END) as pending,
        SUM(CASE WHEN status = 'متأخرة' THEN amount ELSE 0 END) as overdue,
        COUNT(*) as count
      FROM invoices WHERE userId = ?
    `).get(req.userId);

    res.json({ success: true, invoices, total, stats });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.post('/invoices', protect, (req, res) => {
  try {
    const { type, amount, description, clientName, clientPhone, propertyId, dueDate } = req.body;
    const result = db.prepare(`
      INSERT INTO invoices (userId, propertyId, type, amount, description, clientName, clientPhone, dueDate)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).run(req.userId, propertyId || null, type, amount, description || '', clientName || '', clientPhone || '', dueDate || null);

    res.json({ success: true, id: result.lastInsertRowid, message: 'تم إضافة الفاتورة' });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.put('/invoices/:id', protect, (req, res) => {
  try {
    const { status, paidAt } = req.body;
    const updates = [];
    const params = [];
    if (status) { updates.push('status = ?'); params.push(status); }
    if (paidAt) { updates.push('paidAt = ?'); params.push(paidAt); }
    if (status === 'مدفوعة' && !paidAt) { updates.push("paidAt = datetime('now')"); }
    if (updates.length === 0) return res.status(400).json({ error: 'لا توجد تحديثات' });

    params.push(req.params.id, req.userId);
    db.prepare(`UPDATE invoices SET ${updates.join(', ')} WHERE id = ? AND userId = ?`).run(...params);
    res.json({ success: true, message: 'تم تحديث الفاتورة' });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.delete('/invoices/:id', protect, (req, res) => {
  try {
    db.prepare('DELETE FROM invoices WHERE id = ? AND userId = ?').run(req.params.id, req.userId);
    res.json({ success: true, message: 'تم حذف الفاتورة' });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.get('/vendors', protect, (req, res) => {
  try {
    const { category, search } = req.query;
    let where = ['userId = ?'];
    const params = [req.userId];
    if (category) { where.push('category = ?'); params.push(category); }
    if (search) { where.push('(name LIKE ? OR phone LIKE ?)'); params.push(`%${search}%`, `%${search}%`); }

    const vendors = db.prepare(`SELECT * FROM vendors WHERE ${where.join(' AND ')} ORDER BY totalDeals DESC, rating DESC`).all(...params);
    res.json({ success: true, vendors });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.post('/vendors', protect, (req, res) => {
  try {
    const { name, category, phone, email, city, notes } = req.body;
    if (!name || !category) return res.status(400).json({ error: 'اسم المورد والفئة مطلوبين' });

    const result = db.prepare(`
      INSERT INTO vendors (userId, name, category, phone, email, city, notes)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(req.userId, name, category, phone || '', email || '', city || '', notes || '');

    res.json({ success: true, id: result.lastInsertRowid, message: 'تم إضافة المورد' });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.put('/vendors/:id', protect, (req, res) => {
  try {
    const { name, category, phone, email, city, rating, notes } = req.body;
    const updates = [];
    const params = [];
    if (name) { updates.push('name = ?'); params.push(name); }
    if (category) { updates.push('category = ?'); params.push(category); }
    if (phone) { updates.push('phone = ?'); params.push(phone); }
    if (email) { updates.push('email = ?'); params.push(email); }
    if (city) { updates.push('city = ?'); params.push(city); }
    if (rating !== undefined) { updates.push('rating = ?'); params.push(rating); }
    if (notes) { updates.push('notes = ?'); params.push(notes); }
    if (updates.length === 0) return res.status(400).json({ error: 'لا توجد تحديثات' });

    params.push(req.params.id, req.userId);
    db.prepare(`UPDATE vendors SET ${updates.join(', ')} WHERE id = ? AND userId = ?`).run(...params);
    res.json({ success: true, message: 'تم تحديث المورد' });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.delete('/vendors/:id', protect, (req, res) => {
  try {
    db.prepare('DELETE FROM vendors WHERE id = ? AND userId = ?').run(req.params.id, req.userId);
    res.json({ success: true, message: 'تم حذف المورد' });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

export default router;
