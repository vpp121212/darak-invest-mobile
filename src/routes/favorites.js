import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';
import { Errors } from '../utils/errors.js';

const router = Router();

async function loadFavorites(userId) {
  const [user] = await sql`SELECT favorites FROM users WHERE id = ${userId}`;
  return JSON.parse(user?.favorites || '[]');
}

// قائمة المفضلة مع بيانات العقارات.
router.get('/', protect, async (req, res) => {
  try {
    const favs = await loadFavorites(req.user.id);
    if (favs.length === 0) return res.json({ success: true, favorites: [] });
    const rows = await sql`
      SELECT * FROM properties WHERE id = ANY(${favs}::int[]) AND status = 'active'
    `;
    res.json({ success: true, favorites: rows });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

// إضافة أو إزالة عقار من المفضلة.
router.post('/:propertyId', protect, async (req, res) => {
  try {
    const propertyId = Number(req.params.propertyId);
    const [property] = await sql`SELECT id FROM properties WHERE id = ${propertyId}`;
    if (!property) return res.status(404).json(Errors.notFound('العقار').toJSON());
    const favs = await loadFavorites(req.user.id);
    const idx = favs.indexOf(propertyId);
    if (idx > -1) {
      favs.splice(idx, 1);
      await sql`UPDATE users SET favorites = ${JSON.stringify(favs)} WHERE id = ${req.user.id}`;
      return res.json({ success: true, action: 'removed', favorites: favs });
    }
    favs.push(propertyId);
    await sql`UPDATE users SET favorites = ${JSON.stringify(favs)} WHERE id = ${req.user.id}`;
    res.json({ success: true, action: 'added', favorites: favs });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

// إزالة من المفضلة.
router.delete('/:propertyId', protect, async (req, res) => {
  try {
    const favs = await loadFavorites(req.user.id);
    const updated = favs.filter((id) => id !== Number(req.params.propertyId));
    await sql`UPDATE users SET favorites = ${JSON.stringify(updated)} WHERE id = ${req.user.id}`;
    res.json({ success: true, favorites: updated });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

export default router;
