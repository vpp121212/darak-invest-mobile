import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { createAdSchema } from '../validators/ad.js';
import { Errors } from '../utils/errors.js';

const router = Router();

router.post('/add', protect, validate.body(createAdSchema), async (req, res) => {
  try {
    const { title, price, location, description } = req.body;

    const now = new Date().getFullYear();
    const [ad] = await sql`
      INSERT INTO properties (title, type, purpose, price, area, rooms, baths, description, city, district, status, "agentUserId", year, age)
      VALUES (${title}, 'شقة', 'بيع', ${price}, 0, 0, 0, ${description}, ${location}, ${location || 'غير محدد'}, 'active', ${req.user.id}, ${now}, 0)
      RETURNING id, title, price, city as location, description, "createdAt"
    `;

    ad.user = req.user.id;

    res.status(201).json({
      message: 'تم إضافة الإعلان بنجاح',
      ad
    });
  } catch (error) {
    console.error('Add Ad Error:', error);
    res.status(500).json(Errors.internal().toJSON());
  }
});

router.get('/search', async (req, res) => {
  try {
    const { area, type, purpose, price } = req.query;
    let conditions = ["status = 'active'", 'lat IS NOT NULL', 'lng IS NOT NULL'];
    let params = [];
    let idx = 1;

    if (area) {
      conditions.push(`(district ILIKE $${idx} OR city ILIKE $${idx} OR area_name ILIKE $${idx})`);
      params.push(`%${area}%`);
      idx++;
    }
    if (type) {
      conditions.push(`type = $${idx}`);
      params.push(type);
      idx++;
    }
    if (purpose) {
      conditions.push(`purpose = $${idx}`);
      params.push(purpose);
      idx++;
    }
    if (price) {
      const [min, max] = price.split('-').map(Number);
      if (!isNaN(min)) { conditions.push(`price >= $${idx}`); params.push(min); idx++; }
      if (!isNaN(max)) { conditions.push(`price <= $${idx}`); params.push(max); idx++; }
    }

    const ads = await sql.unsafe(
      `SELECT id, title, type, purpose, price, area, rooms, baths, description, city, district, lat, lng, images, features, trust FROM properties WHERE ${conditions.join(' AND ')} ORDER BY "createdAt" DESC LIMIT 100`,
      params
    );
    res.json({ success: true, ads: ads.map(a => ({
      ...a,
      images: JSON.parse(a.images || '[]'),
      features: JSON.parse(a.features || '[]')
    })) });
  } catch (err) {
    console.error('Search ads error:', err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

router.get('/in-bounds', async (req, res) => {
  try {
    const { ne, sw } = req.query;
    if (!ne || !sw) return res.status(400).json({ error: 'يجب تحديد الحدود' });

    const [neLat, neLng] = ne.split(',').map(Number);
    const [swLat, swLng] = sw.split(',').map(Number);

    if (isNaN(neLat) || isNaN(neLng) || isNaN(swLat) || isNaN(swLng)) {
      return res.status(400).json({ error: 'إحداثيات غير صالحة' });
    }

    const ads = await sql`
      SELECT id, title, type, purpose, price, area, rooms, baths, description, city, district, lat, lng, images, features, trust
      FROM properties
      WHERE status = 'active' AND lat IS NOT NULL AND lng IS NOT NULL
        AND lat BETWEEN ${Math.min(swLat, neLat)} AND ${Math.max(swLat, neLat)}
        AND lng BETWEEN ${Math.min(swLng, neLng)} AND ${Math.max(swLng, neLng)}
      ORDER BY "createdAt" DESC LIMIT 200
    `;
    res.json({ success: true, ads: ads.map(a => ({
      ...a,
      images: JSON.parse(a.images || '[]'),
      features: JSON.parse(a.features || '[]')
    })) });
  } catch (err) {
    console.error('Bounds ads error:', err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

export default router;
