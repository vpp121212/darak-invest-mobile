import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';

const router = Router();

router.get('/', protect, async (req, res) => {
  try {
    const properties = await sql`SELECT * FROM properties WHERE "agentUserId" = ${req.user.id} ORDER BY "createdAt" DESC`;
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

router.get('/stats', protect, async (req, res) => {
  try {
    const [{ c: total }] = await sql`SELECT COUNT(*)::int as c FROM properties WHERE "agentUserId" = ${req.user.id}`;
    const [{ c: active }] = await sql`SELECT COUNT(*)::int as c FROM properties WHERE "agentUserId" = ${req.user.id} AND status = 'active'`;
    const [{ c: pending }] = await sql`SELECT COUNT(*)::int as c FROM properties WHERE "agentUserId" = ${req.user.id} AND status = 'pending'`;
    const [{ v: totalViews }] = await sql`SELECT COALESCE(SUM(views),0)::int as v FROM properties WHERE "agentUserId" = ${req.user.id}`;
    const [{ f: totalFavs }] = await sql`SELECT COALESCE(SUM(favorites),0)::int as f FROM properties WHERE "agentUserId" = ${req.user.id}`;
    res.json({ success: true, stats: { total, active, pending, totalViews, totalFavorites: totalFavs } });
  } catch (err) { res.status(500).json({ error: 'خطأ داخلي' }); }
});

export default router;
