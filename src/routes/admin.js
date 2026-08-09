import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';
import { authorize } from '../middleware/auth.js';
import { Errors } from '../utils/errors.js';

const router = Router();

router.use(protect, authorize('admin', 'owner'));

// إحصائيات عامة للوحة الإدارة.
router.get('/stats', async (req, res) => {
  try {
    const [stats] = await sql`
      SELECT
        (SELECT COUNT(*)::int FROM users) AS users,
        (SELECT COUNT(*)::int FROM properties) AS properties,
        (SELECT COUNT(*)::int FROM properties WHERE status = 'active') AS active_listings,
        (SELECT COUNT(*)::int FROM agents) AS brokers,
        (SELECT COUNT(*)::int FROM realestate_contracts) AS contracts,
        (SELECT COUNT(*)::int FROM maintenance_requests) AS maintenance,
        (SELECT COUNT(*)::int FROM payments WHERE status = 'paid') AS paid_payments,
        (SELECT COALESCE(SUM(amount), 0)::real FROM payments WHERE status = 'paid') AS revenue
    `;
    res.json({ success: true, stats });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

// قائمة المستخدمين مع الأدوار والباقات.
router.get('/users', async (req, res) => {
  try {
    const rows = await sql`
      SELECT id, name, phone, email, city, role, package, "createdAt"
      FROM users ORDER BY id DESC LIMIT 100
    `;
    res.json({ success: true, users: rows });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

// تغيير دور مستخدم.
router.put('/users/:id/role', async (req, res) => {
  try {
    const { role } = req.body;
    if (!['user', 'agent', 'owner', 'admin'].includes(role)) {
      return res.status(400).json({ code: 'VALIDATION_ERROR', message: 'دور غير صالح' });
    }
    const [user] = await sql`
      UPDATE users SET role = ${role} WHERE id = ${Number(req.params.id)} RETURNING id, name, role
    `;
    if (!user) return res.status(404).json(Errors.notFound('المستخدم').toJSON());
    res.json({ success: true, user });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

// قائمة الأدوار المرجعية.
router.get('/roles', async (req, res) => {
  try {
    const roles = await sql`SELECT id, name, label, permissions FROM roles ORDER BY id`;
    res.json({ success: true, roles });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

// طلبات الصيانة (كل المستخدمين).
router.get('/maintenance', async (req, res) => {
  try {
    const rows = await sql`
      SELECT m.*, u.name AS "userName", p.title AS "propertyTitle"
      FROM maintenance_requests m
      LEFT JOIN users u ON u.id = m."userId"
      LEFT JOIN properties p ON p.id = m."propertyId"
      ORDER BY m.id DESC LIMIT 100
    `;
    res.json({ success: true, requests: rows });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

export default router;
