import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';
import { Errors } from '../utils/errors.js';

const router = Router();

function formatListing(p) {
  let features = [];
  let images = [];
  try { features = JSON.parse(p.features || '[]'); } catch (_) {}
  try { images = JSON.parse(p.images || '[]'); } catch (_) {}
  return { ...p, features, images };
}

// قائمة الإعلانات النشطة مع فلترة اختيارية.
router.get('/', async (req, res) => {
  try {
    const { city, district, type, purpose, minPrice, maxPrice, rooms, page = 1, limit = 20 } = req.query;
    const conditions = ['status = $1'];
    const params = ['active'];
    let idx = 2;
    if (city) { conditions.push(`city = $${idx++}`); params.push(city); }
    if (district) { conditions.push(`district ILIKE $${idx++}`); params.push(`%${district}%`); }
    if (type) { conditions.push(`type = $${idx++}`); params.push(type); }
    if (purpose) { conditions.push(`purpose = $${idx++}`); params.push(purpose); }
    if (rooms) { conditions.push(`rooms >= $${idx++}`); params.push(Number(rooms)); }
    if (minPrice) { conditions.push(`price >= $${idx++}`); params.push(Number(minPrice)); }
    if (maxPrice) { conditions.push(`price <= $${idx++}`); params.push(Number(maxPrice)); }

    const [{ total }] = await sql.unsafe(`SELECT COUNT(*)::int as total FROM properties WHERE ${conditions.join(' AND ')}`, params);
    params.push(Number(limit), (Number(page) - 1) * Number(limit));
    const rows = await sql.unsafe(
      `SELECT * FROM properties WHERE ${conditions.join(' AND ')} ORDER BY "createdAt" DESC LIMIT $${idx++} OFFSET $${idx++}`,
      params
    );
    res.json({ success: true, listings: rows.map(formatListing), total, pages: Math.ceil(total / Number(limit)), page: Number(page) });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

// تفاصيل إعلان.
router.get('/:id', async (req, res) => {
  try {
    const [row] = await sql`SELECT * FROM properties WHERE id = ${Number(req.params.id)} AND status = 'active'`;
    if (!row) return res.status(404).json(Errors.notFound('الإعلان').toJSON());
    res.json({ success: true, listing: formatListing(row) });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

// نشر إعلان جديد (يطابق /api/properties).
router.post('/', protect, async (req, res) => {
  try {
    const p = req.body;
    if (!p.title || !p.type || !p.purpose || !p.city || !p.district || !p.price || !p.area) {
      return res.status(400).json({ code: 'VALIDATION_ERROR', message: 'العنوان والنوع والغرض والمدينة والحي والسعر والمساحة مطلوبة' });
    }
    const [result] = await sql.unsafe(`
      INSERT INTO properties (title, type, purpose, price, area, rooms, baths, cars, apartments, facing, year, age, description,
        city, district, area_name, street, "streetWidth", lat, lng, features, trust, status, images, "panoramicImage",
        "agentName", "agentPhone", "agentOffice", "agentUserId")
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29)
      RETURNING id
    `, [
      p.title, p.type, p.purpose, p.price, p.area, p.rooms || 0, p.baths || 0, p.cars || 0, p.apartments || 0, p.facing || 'شمالي',
      p.year ?? null, p.age || 0, p.description || '', p.city, p.district, p.area_name ?? null, p.street ?? null,
      p.streetWidth ?? null, p.lat ?? null, p.lng ?? null, JSON.stringify(p.features || []), p.trust || 'direct', 'active',
      JSON.stringify(p.images || []), p.panoramicImage || null,
      req.user.name, req.user.phone, '', req.user.id
    ]);
    const [listing] = await sql`SELECT * FROM properties WHERE id = ${result.id}`;
    res.status(201).json({ success: true, listing: formatListing(listing) });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

export default router;
