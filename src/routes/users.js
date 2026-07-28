import { Router } from 'express';
import bcrypt from 'bcryptjs';
import db from '../config/database.js';
import { protect, authorize } from '../middleware/auth.js';

const router = Router();

router.get('/profile', protect, (req, res) => {
  const user = db.prepare('SELECT id, name, email, phone, role, avatar, favorites, createdAt FROM users WHERE id = ?').get(req.user.id);
  res.json({ success: true, user: { ...user, favorites: JSON.parse(user.favorites || '[]') } });
});

router.put('/profile', protect, (req, res) => {
  const { name, phone, avatar } = req.body;
  db.prepare("UPDATE users SET name=COALESCE(?,name), phone=COALESCE(?,phone), avatar=COALESCE(?,avatar), updatedAt=datetime('now') WHERE id=?")
    .run(name, phone, avatar, req.user.id);
  const user = db.prepare('SELECT id, name, email, phone, role, avatar FROM users WHERE id = ?').get(req.user.id);
  res.json({ success: true, user });
});

router.post('/favorites/:propertyId', protect, (req, res) => {
  const user = db.prepare('SELECT favorites FROM users WHERE id = ?').get(req.user.id);
  let favs = JSON.parse(user.favorites || '[]');
  const idx = favs.indexOf(Number(req.params.propertyId));
  if (idx > -1) {
    favs.splice(idx, 1);
    db.prepare('UPDATE users SET favorites = ? WHERE id = ?').run(JSON.stringify(favs), req.user.id);
    return res.json({ success: true, action: 'removed', favorites: favs });
  }
  favs.push(Number(req.params.propertyId));
  db.prepare('UPDATE users SET favorites = ? WHERE id = ?').run(JSON.stringify(favs), req.user.id);
  res.json({ success: true, action: 'added', favorites: favs });
});

router.get('/', protect, authorize('admin'), (req, res) => {
  const users = db.prepare('SELECT id, name, email, phone, role, createdAt FROM users ORDER BY createdAt DESC').all();
  res.json({ success: true, users });
});

router.delete('/:id', protect, authorize('admin'), (req, res) => {
  db.prepare('DELETE FROM users WHERE id = ?').run(req.params.id);
  res.json({ success: true });
});

export default router;
