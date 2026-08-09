import { Router } from 'express';
import sql from '../config/database.js';
import { analyzeListing, duplicateCheck, recommend, buyerAssistant, sellerAssistant, valuationSummary } from '../services/ai.js';

const router = Router();

const num = (v) => (v !== undefined && v !== null && v !== '' ? Number(v) : undefined);

// AI Listing Analyzer — evaluates listing completeness, marketing quality and pricing.
router.post('/listing/analyze', async (req, res) => {
  try {
    const analysis = await analyzeListing(req.body);
    res.json({ success: true, analysis });
  } catch (err) {
    if (err.status === 404) return res.status(404).json({ error: err.message });
    console.error(err);
    res.status(500).json({ error: 'خطأ داخلي' });
  }
});

// AI Duplicate Detection — finds near-duplicate listings.
router.post('/listing/duplicate-check', async (req, res) => {
  try {
    const result = await duplicateCheck(req.body);
    res.json(result);
  } catch (err) {
    if (err.status === 404) return res.status(404).json({ error: err.message });
    console.error(err);
    res.status(500).json({ error: 'خطأ داخلي' });
  }
});

// AI Valuation Engine — estimate + natural-language summary.
router.post('/valuation/estimate', async (req, res) => {
  try {
    const result = await valuationSummary(req.body);
    res.json(result);
  } catch (err) {
    if (err.status === 400) return res.status(400).json({ error: err.message });
    if (err.status === 404) return res.status(404).json({ error: err.message });
    console.error(err);
    res.status(500).json({ error: 'خطأ داخلي' });
  }
});

// AI Recommendation Engine — personalized ranked matches.
router.post('/recommendations', async (req, res) => {
  try {
    const { budget, area, rooms, baths, type, purpose, city, districts, features, limit } = req.body;
    const result = await recommend({
      budget: num(budget), area: num(area), rooms: num(rooms), baths: num(baths),
      type, purpose, city, districts, features, limit: num(limit)
    });
    res.json(result);
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

// AI Buyer Assistant — query in natural language + structured filters.
router.post('/assistant/buyer', async (req, res) => {
  try {
    const result = await buyerAssistant({
      query: req.body.query || '',
      budget: num(req.body.budget), area: num(req.body.area), rooms: num(req.body.rooms),
      type: req.body.type, city: req.body.city, purpose: req.body.purpose,
      districts: req.body.districts, features: req.body.features
    });
    res.json(result);
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

// AI Seller Assistant — pricing guidance + listing improvements.
router.post('/assistant/seller', async (req, res) => {
  try {
    const result = await sellerAssistant(req.body);
    res.json({ success: true, ...result });
  } catch (err) {
    if (err.status === 404) return res.status(404).json({ error: err.message });
    console.error(err);
    res.status(500).json({ error: 'خطأ داخلي' });
  }
});

// Backward-compatible legacy estimate (heuristic fallback, no comparables engine).
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

// Backward-compatible legacy match.
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
