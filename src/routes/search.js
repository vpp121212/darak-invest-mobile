import { Router } from 'express';
import sql from '../config/database.js';

const router = Router();

router.get('/', async (req, res) => {
  await handleSearch(req, res);
});

async function handleSearch(req, res) {
  try {
    console.log('SEARCH HIT:', req.originalUrl, req.path);
    const start = Date.now();
    const { q, city, type, purpose, minPrice, maxPrice, minArea, maxArea,
      rooms, baths, apartments, facing, trust, sort, age, minStreetWidth, minCars,
      features, page = 1, limit = 50 } = req.query;

    let conditions = [];
    let params = [];
    let idx = 0;

    const add = (sql, val) => {
      if (val !== undefined && val !== null && val !== '') {
        conditions.push(sql.replace('?', `$${++idx}`));
        params.push(val);
      }
    };

    conditions.push(`status = $${++idx}`);
    params.push('active');

    add('city = ?', city);
    add('type = ?', type);
    add('purpose = ?', purpose);
    add('facing = ?', facing);
    add('trust = ?', trust);
    add('rooms >= ?', rooms && Number(rooms));
    add('baths >= ?', baths && Number(baths));
    add('apartments = ?', apartments && Number(apartments));
    add('price >= ?', minPrice && Number(minPrice));
    add('price <= ?', maxPrice && Number(maxPrice));
    add('area >= ?', minArea && Number(minArea));
    add('area <= ?', maxArea && Number(maxArea));
    add('"streetWidth" >= ?', minStreetWidth && Number(minStreetWidth));
    add('cars >= ?', minCars && Number(minCars));

    if (age) {
      if (age === 'new') conditions.push('age <= 1');
      else if (age === 'under') conditions.push('age = 0');
      else if (age === '1') conditions.push('age BETWEEN 1 AND 5');
      else if (age === '5') conditions.push('age BETWEEN 5 AND 10');
      else if (age === '10') conditions.push('age > 10');
    }

    if (q) {
      conditions.push(`(title ILIKE $${++idx} OR city ILIKE $${++idx} OR district ILIKE $${++idx} OR type ILIKE $${++idx} OR description ILIKE $${++idx})`);
      const like = `%${q}%`;
      params.push(like, like, like, like, like);
    }

    if (features) {
      const featureList = features.split(',');
      featureList.forEach(f => {
        conditions.push(`features ILIKE $${++idx}`);
        params.push(`%${f.trim()}%`);
      });
    }

    let orderBy = '"createdAt" DESC';
    if (sort === 'price_asc') orderBy = 'price ASC';
    if (sort === 'price_desc') orderBy = 'price DESC';
    if (sort === 'area_desc') orderBy = 'area DESC';

    const offset = (Number(page) - 1) * Number(limit);
    const where = conditions.join(' AND ');

    const properties = await sql.unsafe(
      `SELECT * FROM properties WHERE ${where} ORDER BY ${orderBy} LIMIT $${++idx} OFFSET $${++idx}`,
      [...params, Number(limit), offset]
    );

    // remove limit/offset params for count query
    const countParams = params.slice();
    const [{ total }] = await sql.unsafe(`SELECT COUNT(*)::int as total FROM properties WHERE ${where}`, countParams);

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

router.get('/cities', async (req, res) => {
  const cities = await sql`SELECT DISTINCT city FROM properties WHERE status = 'active'`;
  res.json({ success: true, cities: cities.map(c => c.city) });
});

router.get('/districts', async (req, res) => {
  const { city } = req.query;
  let query = "SELECT DISTINCT district FROM properties WHERE status = 'active'";
  let params = [];
  if (city) { query += ' AND city = $1'; params.push(city); }
  const districts = await sql.unsafe(query, params);
  res.json({ success: true, districts: districts.map(d => d.district) });
});

router.get('/suggestions', async (req, res) => {
  try {
    const { city, type, facing, area } = req.query;
    let conditions = [`status = 'active'`];
    let params = [];
    let idx = 0;
    const add = (sql, val) => {
      if (val) { conditions.push(sql.replace('?', `$${++idx}`)); params.push(val); }
    };
    add('city = ?', city);
    add('type = ?', type);
    add('facing = ?', facing);
    if (area) { conditions.push(`area BETWEEN $${++idx} AND $${++idx}`); params.push(Number(area) * 0.7, Number(area) * 1.3); }

    const where = conditions.join(' AND ');
    const [stats] = await sql.unsafe(
      `SELECT AVG(price) as "avgPrice", COUNT(*)::int as count, AVG(area) as "avgArea",
      MIN(price) as "minPrice", MAX(price) as "maxPrice",
      AVG("streetWidth") as "avgStreetWidth", AVG(cars) as "avgCars"
      FROM properties WHERE ${where}`, params
    );

    const byFloor = await sql.unsafe(
      `SELECT
      CASE WHEN age <= 1 THEN 'جديد' WHEN age <= 5 THEN '1-5 سنوات' WHEN age <= 10 THEN '5-10 سنوات' ELSE '+10 سنوات' END as label,
      COUNT(*)::int as count, AVG(price) as "avgPrice"
      FROM properties WHERE ${where} GROUP BY label`, params
    );

    const byFacing = await sql.unsafe(
      `SELECT facing, COUNT(*)::int as count, AVG(price) as "avgPrice"
      FROM properties WHERE ${where} AND facing != '' GROUP BY facing`, params
    );

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

router.get('/stats', async (req, res) => {
  try {
    const [{ c: total }] = await sql`SELECT COUNT(*)::int as c FROM properties WHERE status='active'`;
    const byCity = await sql`SELECT city as _id, COUNT(*)::int as count, AVG(price) as "avgPrice" FROM properties WHERE status='active' GROUP BY city ORDER BY count DESC`;
    const byType = await sql`SELECT type as _id, COUNT(*)::int as count FROM properties WHERE status='active' GROUP BY type ORDER BY count DESC`;
    res.json({ success: true, stats: { total, byCity, byType } });
  } catch (err) { res.status(503).json({ error: 'الإحصائيات غير متاحة' }); }
});

export default router;
