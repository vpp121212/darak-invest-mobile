import { Router } from 'express';
import sql from '../config/database.js';

const router = Router();

router.post('/estimate', async (req, res) => {
  try {
    const { city, district, type, purpose, area, rooms, baths, features = [] } = req.body;
    const similar = await sql`
      SELECT * FROM properties WHERE city=${city} AND type=${type} AND purpose=${purpose} AND status='active'
      AND area BETWEEN ${area * 0.7} AND ${area * 1.3} AND rooms BETWEEN ${Math.max(1, rooms - 1)} AND ${rooms + 1}
    `;

    if (similar.length === 0) {
      return res.json({ success: true, estimation: { expected: null, suitable: null, maximum: null, saleChance: null, message: 'لا توجد بيانات كافية', sampleSize: 0 } });
    }

    const avgPrice = similar.reduce((s, p) => s + p.price, 0) / similar.length;
    const minP = Math.min(...similar.map(p => p.price / p.area)) * area;
    const maxP = Math.max(...similar.map(p => p.price / p.area)) * area;
    const withFeatures = similar.filter(p => {
      const pf = JSON.parse(p.features || '[]');
      return features.some(f => pf.includes(f));
    }).length;
    const boost = withFeatures / similar.length;

    const expected = Math.round(avgPrice * (1 + boost * 0.1));
    const suitable = Math.round((expected + minP) / 2);
    const maximum = Math.round(maxP * 1.1);
    const saleChance = Math.min(95, Math.round(30 + (similar.length * 5) + (boost * 20) + (area > 200 ? 10 : 0)));

    res.json({ success: true, estimation: { expected, suitable, maximum, saleChance, sampleSize: similar.length } });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.post('/match', async (req, res) => {
  try {
    const { budget, area, rooms, type } = req.body;
    let conditions = ["status = 'active'"];
    let params = [];
    let idx = 0;
    if (budget) { conditions.push(`price <= $${++idx}`); params.push(Number(budget) * 1.1); }
    if (area) { conditions.push(`area BETWEEN $${++idx} AND $${++idx}`); params.push(Number(area) * 0.8, Number(area) * 1.2); }
    if (rooms) { conditions.push(`rooms >= $${++idx}`); params.push(Math.max(1, Number(rooms) - 1)); }
    if (type) { conditions.push(`type = $${++idx}`); params.push(type); }

    const matches = (await sql.unsafe(
      `SELECT * FROM properties WHERE ${conditions.join(' AND ')} LIMIT 10`,
      params
    )).map(p => {
      let score = 50;
      if (budget && p.price <= budget) score += 20;
      if (area && Math.abs(p.area - area) < area * 0.1) score += 15;
      if (rooms && p.rooms === Number(rooms)) score += 10;
      if (p.views > 100) score += 5;
      return { ...p, features: JSON.parse(p.features || '[]'), images: JSON.parse(p.images || '[]'), matchScore: Math.min(score, 100) };
    }).sort((a, b) => b.matchScore - a.matchScore);

    res.json({ success: true, matches });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

export default router;
