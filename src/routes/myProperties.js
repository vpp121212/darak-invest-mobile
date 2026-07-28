import { Router } from 'express';
import db from '../config/database.js';
import { protect } from '../middleware/auth.js';

const router = Router();

router.get('/', protect, (req, res) => {
  try {
    const properties = db.prepare('SELECT * FROM properties WHERE agentUserId = ? ORDER BY createdAt DESC').all(req.user.id);
    res.json({
      success: true,
      properties: properties.map(p => ({
        ...p,
        features: JSON.parse(p.features || '[]'),
        images: JSON.parse(p.images || '[]'),
        isFeatured: !!p.isFeatured
      }))
    });
  } catch (err) { res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.get('/stats', protect, (req, res) => {
  try {
    const total = db.prepare('SELECT COUNT(*) as c FROM properties WHERE agentUserId = ?').get(req.user.id).c;
    const active = db.prepare("SELECT COUNT(*) as c FROM properties WHERE agentUserId = ? AND status = 'active'").get(req.user.id).c;
    const pending = db.prepare("SELECT COUNT(*) as c FROM properties WHERE agentUserId = ? AND status = 'pending'").get(req.user.id).c;
    const totalViews = db.prepare('SELECT COALESCE(SUM(views),0) as v FROM properties WHERE agentUserId = ?').get(req.user.id).v;
    const totalFavs = db.prepare('SELECT COALESCE(SUM(favorites),0) as f FROM properties WHERE agentUserId = ?').get(req.user.id).f;
    res.json({ success: true, stats: { total, active, pending, totalViews, totalFavorites: totalFavs } });
  } catch (err) { res.status(500).json({ error: 'خطأ داخلي' }); }
});

export default router;
