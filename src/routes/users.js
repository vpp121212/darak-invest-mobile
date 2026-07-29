import { Router } from 'express';
import bcrypt from 'bcryptjs';
import sql from '../config/database.js';
import { protect, authorize } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { profileUpdateSchema } from '../validators/auth.js';

const router = Router();

router.get('/profile', protect, async (req, res) => {
  const [user] = await sql`SELECT id, name, email, phone, role, avatar, favorites, "createdAt" FROM users WHERE id = ${req.user.id}`;
  res.json({ success: true, user: { ...user, favorites: JSON.parse(user.favorites || '[]') } });
});

router.put('/profile', protect, validate.body(profileUpdateSchema), async (req, res) => {
  const { name, phone, avatar } = req.body;
  await sql`
    UPDATE users SET name=COALESCE(${name}, name), phone=COALESCE(${phone}, phone), avatar=COALESCE(${avatar}, avatar), "updatedAt"=NOW() WHERE id=${req.user.id}
  `;
  const [user] = await sql`SELECT id, name, email, phone, role, avatar FROM users WHERE id = ${req.user.id}`;
  res.json({ success: true, user });
});

router.post('/favorites/:propertyId', protect, async (req, res) => {
  const [user] = await sql`SELECT favorites FROM users WHERE id = ${req.user.id}`;
  let favs = JSON.parse(user.favorites || '[]');
  const idx = favs.indexOf(Number(req.params.propertyId));
  if (idx > -1) {
    favs.splice(idx, 1);
    await sql`UPDATE users SET favorites = ${JSON.stringify(favs)} WHERE id = ${req.user.id}`;
    return res.json({ success: true, action: 'removed', favorites: favs });
  }
  favs.push(Number(req.params.propertyId));
  await sql`UPDATE users SET favorites = ${JSON.stringify(favs)} WHERE id = ${req.user.id}`;
  res.json({ success: true, action: 'added', favorites: favs });
});

router.get('/', protect, authorize('admin', 'owner'), async (req, res) => {
  const users = await sql`SELECT id, name, email, phone, role, "createdAt" FROM users ORDER BY "createdAt" DESC`;
  res.json({ success: true, users });
});

router.put('/:id/role', protect, authorize('owner'), async (req, res) => {
  const { role } = req.body;
  if (!['user','agent','admin'].includes(role)) return res.status(400).json({ error: 'صلاحية غير صالحة' });
  await sql`UPDATE users SET role = ${role} WHERE id = ${req.params.id}`;
  res.json({ success: true, message: 'تم تحديث الصلاحية' });
});

router.put('/:id/status', protect, authorize('admin', 'owner'), async (req, res) => {
  const { isActive } = req.body;
  await sql`UPDATE users SET "isActive" = ${isActive ? 1 : 0} WHERE id = ${req.params.id}`;
  res.json({ success: true, message: 'تم تحديث الحالة' });
});

router.delete('/:id', protect, authorize('admin', 'owner'), async (req, res) => {
  await sql`DELETE FROM users WHERE id = ${req.params.id}`;
  res.json({ success: true, message: 'تم حذف المستخدم' });
});

export default router;
