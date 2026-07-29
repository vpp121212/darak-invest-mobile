import { Router } from 'express';
import db from '../config/database.js';

const router = Router();

router.get('/', (req, res) => {
  handleSearch(req, res);
});

function handleSearch(req, res) {
  try {
    console.log('SEARCH HIT:', req.originalUrl, req.path);
    const start = Date.now();
    const { q, city, type, purpose, minPrice, maxPrice, minArea, maxArea,
      rooms, baths, facing, trust, sort, age, minStreetWidth, minCars,
      features, page = 1, limit = 50 } = req.query;

    let where = ['status = ?'];
    let params = ['active'];

    if (city) { where.push('city = ?'); params.push(city); }
    if (type) { where.push('type = ?'); params.push(type); }
    if (purpose) { where.push('purpose = ?'); params.push(purpose); }
    if (facing) { where.push('facing = ?'); params.push(facing); }
    if (trust) { where.push('trust = ?'); params.push(trust); }
    if (rooms) { where.push('rooms >= ?'); params.push(Number(rooms)); }
    if (baths) { where.push('baths >= ?'); params.push(Number(baths)); }
    if (minPrice) { where.push('price >= ?'); params.push(Number(minPrice)); }
    if (maxPrice) { where.push('price <= ?'); params.push(Number(maxPrice)); }
    if (minArea) { where.push('area >= ?'); params.push(Number(minArea)); }
    if (maxArea) { where.push('area <= ?'); params.push(Number(maxArea)); }
    if (minStreetWidth) { where.push('streetWidth >= ?'); params.push(Number(minStreetWidth)); }
    if (minCars) { where.push('cars >= ?'); params.push(Number(minCars)); }

    // Age filter
    if (age) {
      if (age === 'new') { where.push('age <= 1'); }
      else if (age === 'under') { where.push('age = 0'); }
      else if (age === '1') { where.push('age BETWEEN 1 AND 5'); }
      else if (age === '5') { where.push('age BETWEEN 5 AND 10'); }
      else if (age === '10') { where.push('age > 10'); }
    }

    // Text search
    if (q) {
      where.push("(title LIKE ? OR city LIKE ? OR district LIKE ? OR type LIKE ? OR description LIKE ?)");
      const like = `%${q}%`;
      params.push(like, like, like, like, like);
    }

    // Features filter (comma-separated)
    if (features) {
      const featureList = features.split(',');
      featureList.forEach(f => {
        where.push('features LIKE ?');
        params.push(`%${f.trim()}%`);
      });
    }

    let orderBy = 'createdAt DESC';
    if (sort === 'price_asc') orderBy = 'price ASC';
    if (sort === 'price_desc') orderBy = 'price DESC';
    if (sort === 'area_desc') orderBy = 'area DESC';

    const offset = (Number(page) - 1) * Number(limit);
    const sql = `SELECT * FROM properties WHERE ${where.join(' AND ')} ORDER BY ${orderBy} LIMIT ? OFFSET ?`;
    const countSql = `SELECT COUNT(*) as total FROM properties WHERE ${where.join(' AND ')}`;

    const properties = db.prepare(sql).all(...params, Number(limit), offset);
    const { total } = db.prepare(countSql).get(...params);

    const formatted = properties.map(p => ({
      ...p,
      features: JSON.parse(p.features || '[]'),
      images: JSON.parse(p.images || '[]'),
      isFeatured: !!p.isFeatured,
      loc: `${p.district}، ${p.city}`,
    }));

    res.json({ success: true, properties: formatted, total, pages: Math.ceil(total / Number(limit)), page: Number(page), ms: Date.now() - start });
  } catch (err) {
    console.error(err);
    res.status(503).json({ error: 'البحث غير متاح مؤقتاً', fallback: true, message: err.message });
  }
}

router.get('/cities', (req, res) => {
  const cities = db.prepare("SELECT DISTINCT city FROM properties WHERE status = 'active'").all();
  res.json({ success: true, cities: cities.map(c => c.city) });
});

router.get('/districts', (req, res) => {
  const { city } = req.query;
  let sql = "SELECT DISTINCT district FROM properties WHERE status = 'active'";
  const params = [];
  if (city) { sql += ' AND city = ?'; params.push(city); }
  const districts = db.prepare(sql).all(...params);
  res.json({ success: true, districts: districts.map(d => d.district) });
});

router.get('/suggestions', (req, res) => {
  try {
    const { city, type, facing, area } = req.query;
    let where = ['status = ?'];
    let params = ['active'];
    if (city) { where.push('city = ?'); params.push(city); }
    if (type) { where.push('type = ?'); params.push(type); }
    if (facing) { where.push('facing = ?'); params.push(facing); }
    if (area) { where.push('area BETWEEN ? AND ?'); params.push(Number(area) * 0.7, Number(area) * 1.3); }

    const sql = `SELECT AVG(price) as avgPrice, COUNT(*) as count, AVG(area) as avgArea,
      MIN(price) as minPrice, MAX(price) as maxPrice,
      AVG(streetWidth) as avgStreetWidth, AVG(cars) as avgCars
      FROM properties WHERE ${where.join(' AND ')}`;
    const stats = db.prepare(sql).get(...params);

    const byFloor = db.prepare(`SELECT
      CASE WHEN age <= 1 THEN 'جديد' WHEN age <= 5 THEN '1-5 سنوات' WHEN age <= 10 THEN '5-10 سنوات' ELSE '+10 سنوات' END as label,
      COUNT(*) as count, AVG(price) as avgPrice
      FROM properties WHERE ${where.join(' AND ')} GROUP BY label`).all(...params);

    const byFacing = db.prepare(`SELECT facing, COUNT(*) as count, AVG(price) as avgPrice
      FROM properties WHERE ${where.join(' AND ')} AND facing != '' GROUP BY facing`).all(...params);

    res.json({
      success: true,
      suggestions: {
        avgPrice: Math.round(stats.avgPrice || 0),
        count: stats.count || 0,
        avgArea: Math.round(stats.avgArea || 0),
        minPrice: stats.minPrice || 0,
        maxPrice: stats.maxPrice || 0,
        avgStreetWidth: Math.round(stats.avgStreetWidth || 0),
        avgCars: Math.round(stats.avgCars || 0),
        byAge: byFloor,
        byFacing: byFacing
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'خطأ داخلي' });
  }
});

router.get('/stats', (req, res) => {
  try {
    const total = db.prepare("SELECT COUNT(*) as c FROM properties WHERE status='active'").get().c;
    const byCity = db.prepare("SELECT city as _id, COUNT(*) as count, AVG(price) as avgPrice FROM properties WHERE status='active' GROUP BY city ORDER BY count DESC").all();
    const byType = db.prepare("SELECT type as _id, COUNT(*) as count FROM properties WHERE status='active' GROUP BY type ORDER BY count DESC").all();
    res.json({ success: true, stats: { total, byCity, byType } });
  } catch (err) { res.status(503).json({ error: 'الإحصائيات غير متاحة' }); }
});

export default router;
