import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { createPropertySchema, updatePropertySchema, propertyQuerySchema } from '../validators/property.js';
import { propertiesBreaker } from '../services/circuitBreaker.js';
import { Errors } from '../utils/errors.js';

const router = Router();

router.get('/', validate.query(propertyQuerySchema), async (req, res) => {
  try {
    const { city, type, purpose, minPrice, maxPrice, minArea, maxArea, rooms, sort, page = 1, limit = 20 } = req.query;
    const properties = await propertiesBreaker.fire({ city, type, purpose, limit, offset: (Number(page) - 1) * Number(limit) });
    let conditions = ['status = $1'];
    let params = ['active'];
    let idx = 2;
    if (city) { conditions.push(`city = $${idx++}`); params.push(city); }
    if (type) { conditions.push(`type = $${idx++}`); params.push(type); }
    if (purpose) { conditions.push(`purpose = $${idx++}`); params.push(purpose); }
    if (rooms) { conditions.push(`rooms >= $${idx++}`); params.push(Number(rooms)); }
    if (minPrice) { conditions.push(`price >= $${idx++}`); params.push(Number(minPrice)); }
    if (maxPrice) { conditions.push(`price <= $${idx++}`); params.push(Number(maxPrice)); }
    if (minArea) { conditions.push(`area >= $${idx++}`); params.push(Number(minArea)); }
    if (maxArea) { conditions.push(`area <= $${idx++}`); params.push(Number(maxArea)); }
    const [{ total }] = await sql.unsafe(`SELECT COUNT(*)::int as total FROM properties WHERE ${conditions.join(' AND ')}`, params);
    res.json({ success: true, properties: properties.map(formatProperty), total, pages: Math.ceil(total / Number(limit)), page: Number(page) });
  } catch (err) { console.error(err); res.status(503).json({ code: 'SERVICE_UNAVAILABLE', message: 'الخدمة غير متاحة مؤقتاً', fallback: true }); }
});

router.get('/all', async (req, res) => {
  try {
    const properties = await sql`SELECT * FROM properties WHERE status = 'active'`;
    const formatted = properties.map(p => ({
      id: p.id,
      title: p.title,
      type: p.type,
      loc: `${p.district}، ${p.city}`,
      district: p.district,
      city: p.city,
      price: p.price,
      rooms: p.rooms,
      baths: p.baths,
      cars: p.cars,
      area: p.area,
      year: p.year,
      age: p.age,
      status: p.isFeatured ? 'حصري' : 'متاح',
      lat: p.lat,
      lng: p.lng,
      street: p.street,
      streetW: p.streetWidth,
      facing: p.facing,
      purpose: p.purpose,
      desc: p.description,
      images: JSON.parse(p.images || '[]').length > 0
        ? JSON.parse(p.images || '[]')
        : [],
      pano: p.panoramicImage || null,
      features: JSON.parse(p.features || '[]'),
      guarantees: [],
      trust: p.trust || 'direct',
      agent: { name: p.agentName || 'مكتب الديار العقارية', role: 'وسيط مرخص', phone: p.agentPhone || '+966501234567' }
    }));
    res.json(formatted);
  } catch (err) { console.error(err); res.status(500).json([]); }
});

router.get('/:id', async (req, res) => {
  try {
    const [property] = await sql`SELECT * FROM properties WHERE id = ${req.params.id}`;
    if (!property) return res.status(404).json(Errors.notFound('العقار').toJSON());
    await sql`UPDATE properties SET views = views + 1 WHERE id = ${req.params.id}`;
    res.json({ success: true, property: formatProperty(property) });
  } catch (err) { res.status(500).json(Errors.internal().toJSON()); }
});

router.post('/', protect, validate.body(createPropertySchema), async (req, res) => {
  try {
    const p = req.body;
    const [result] = await sql.unsafe(`
      INSERT INTO properties (title, type, purpose, price, area, rooms, baths, cars, facing, year, age, description,
        city, district, area_name, street, "streetWidth", lat, lng, features, trust, status, images, "panoramicImage",
        "agentName", "agentPhone", "agentOffice", "agentUserId")
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28)
      RETURNING id
    `, [
      p.title, p.type, p.purpose, p.price, p.area, p.rooms, p.baths, p.cars || 0, p.facing || 'شمالي',
      p.year, p.age || 0, p.description, p.city, p.district, p.area_name, p.street, p.streetWidth,
      p.lat, p.lng, JSON.stringify(p.features || []), p.trust || 'direct', 'active',
      JSON.stringify(p.images || []), p.panoramicImage || null,
      req.user.name, req.user.phone, '', req.user.id
    ]);
    const [property] = await sql`SELECT * FROM properties WHERE id = ${result.id}`;
    res.status(201).json({ success: true, property: formatProperty(property) });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.put('/:id', protect, validate.body(updatePropertySchema), async (req, res) => {
  try {
    const [existing] = await sql`SELECT * FROM properties WHERE id = ${req.params.id}`;
    if (!existing) return res.status(404).json(Errors.notFound('العقار').toJSON());
    if (existing.agentUserId !== req.user.id && req.user.role !== 'admin' && req.user.role !== 'owner') {
      return res.status(403).json(Errors.forbidden('غير مصرح بالتعديل').toJSON());
    }
    const p = req.body;
    await sql.unsafe(`
      UPDATE properties SET title=$1, type=$2, purpose=$3, price=$4, area=$5, rooms=$6, baths=$7, cars=$8, facing=$9, year=$10, age=$11, description=$12,
        city=$13, district=$14, area_name=$15, street=$16, "streetWidth"=$17, lat=$18, lng=$19, features=$20, trust=$21,
        "updatedAt"=NOW()
      WHERE id=$22
    `, [
      p.title || existing.title, p.type || existing.purpose, p.purpose || existing.purpose, p.price || existing.price,
      p.area || existing.area, p.rooms ?? existing.rooms, p.baths ?? existing.baths, p.cars ?? existing.cars,
      p.facing || existing.facing, p.year || existing.year, p.age ?? existing.age, p.description || existing.description,
      p.city || existing.city, p.district || existing.district, p.area_name || existing.area_name,
      p.street || existing.street, p.streetWidth || existing.streetWidth, p.lat || existing.lat, p.lng || existing.lng,
      JSON.stringify(p.features || JSON.parse(existing.features || '[]')), p.trust || existing.trust, req.params.id
    ]);
    const [property] = await sql`SELECT * FROM properties WHERE id = ${req.params.id}`;
    res.json({ success: true, property: formatProperty(property) });
  } catch (err) { console.error(err); res.status(500).json(Errors.internal().toJSON()); }
});

router.delete('/:id', protect, async (req, res) => {
  try {
    const [existing] = await sql`SELECT * FROM properties WHERE id = ${req.params.id}`;
    if (!existing) return res.status(404).json(Errors.notFound('العقار').toJSON());
    if (existing.agentUserId !== req.user.id && req.user.role !== 'admin' && req.user.role !== 'owner') {
      return res.status(403).json(Errors.forbidden('غير مصرح بالحذف').toJSON());
    }
    await sql`DELETE FROM properties WHERE id = ${req.params.id}`;
    res.json({ success: true, message: 'تم حذف العقار' });
  } catch (err) { res.status(500).json(Errors.internal().toJSON()); }
});

router.post('/:id/favorite', protect, async (req, res) => {
  try {
    await sql`UPDATE properties SET favorites = favorites + 1 WHERE id = ${req.params.id}`;
    const [p] = await sql`SELECT favorites FROM properties WHERE id = ${req.params.id}`;
    res.json({ success: true, favorites: p?.favorites || 0 });
  } catch (err) { res.status(500).json(Errors.internal().toJSON()); }
});

function formatProperty(p) {
  return {
    ...p,
    features: JSON.parse(p.features || '[]'),
    images: JSON.parse(p.images || '[]'),
    isFeatured: !!p.isFeatured,
    isActive: !!p.isActive,
    agent: { name: p.agentName, phone: p.agentPhone, office: p.agentOffice }
  };
}

export default router;
