import { Router } from 'express';
import db from '../config/database.js';
import { protect } from '../middleware/auth.js';
import { propertiesBreaker } from '../services/circuitBreaker.js';

const router = Router();

router.get('/', async (req, res) => {
  try {
    const { city, type, purpose, minPrice, maxPrice, minArea, maxArea, rooms, sort, page = 1, limit = 20 } = req.query;
    const properties = await propertiesBreaker.fire({ city, type, purpose, limit, offset: (Number(page) - 1) * Number(limit) });
    let where = ['status = ?'];
    let params = ['active'];
    if (city) { where.push('city = ?'); params.push(city); }
    if (type) { where.push('type = ?'); params.push(type); }
    if (purpose) { where.push('purpose = ?'); params.push(purpose); }
    if (rooms) { where.push('rooms >= ?'); params.push(Number(rooms)); }
    if (minPrice) { where.push('price >= ?'); params.push(Number(minPrice)); }
    if (maxPrice) { where.push('price <= ?'); params.push(Number(maxPrice)); }
    if (minArea) { where.push('area >= ?'); params.push(Number(minArea)); }
    if (maxArea) { where.push('area <= ?'); params.push(Number(maxArea)); }
    const countSql = `SELECT COUNT(*) as total FROM properties WHERE ${where.join(' AND ')}`;
    const { total } = db.prepare(countSql).get(...params);
    res.json({ success: true, properties: properties.map(formatProperty), total, pages: Math.ceil(total / Number(limit)), page: Number(page) });
  } catch (err) { console.error(err); res.status(503).json({ error: 'الخدمة غير متاحة مؤقتاً', fallback: true }); }
});

// All properties for frontend (no pagination, all active)
router.get('/all', (req, res) => {
  try {
    const properties = db.prepare("SELECT * FROM properties WHERE status = 'active'").all();
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

router.get('/:id', (req, res) => {
  try {
    const property = db.prepare('SELECT * FROM properties WHERE id = ?').get(req.params.id);
    if (!property) return res.status(404).json({ error: 'العقار غير موجود' });
    db.prepare('UPDATE properties SET views = views + 1 WHERE id = ?').run(req.params.id);
    res.json({ success: true, property: formatProperty(property) });
  } catch (err) { res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.post('/', protect, (req, res) => {
  try {
    const p = req.body;
    const result = db.prepare(`
      INSERT INTO properties (title, type, purpose, price, area, rooms, baths, cars, facing, year, age, description,
        city, district, area_name, street, streetWidth, lat, lng, features, trust, status, images, panoramicImage,
        agentName, agentPhone, agentOffice, agentUserId)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      p.title, p.type, p.purpose, p.price, p.area, p.rooms, p.baths, p.cars || 0, p.facing || 'شمالي',
      p.year, p.age || 0, p.description, p.city, p.district, p.area_name, p.street, p.streetWidth,
      p.lat, p.lng, JSON.stringify(p.features || []), p.trust || 'direct', 'active',
      JSON.stringify(p.images || []), p.panoramicImage || null,
      req.user.name, req.user.phone, '', req.user.id
    );
    const property = db.prepare('SELECT * FROM properties WHERE id = ?').get(result.lastInsertRowid);
    res.status(201).json({ success: true, property: formatProperty(property) });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.put('/:id', protect, (req, res) => {
  try {
    const existing = db.prepare('SELECT * FROM properties WHERE id = ?').get(req.params.id);
    if (!existing) return res.status(404).json({ error: 'العقار غير موجود' });
    if (existing.agentUserId !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'غير مصرح بالتعديل' });
    }
    const p = req.body;
    db.prepare(`
      UPDATE properties SET title=?, type=?, purpose=?, price=?, area=?, rooms=?, baths=?, cars=?, facing=?, year=?, age=?, description=?,
        city=?, district=?, area_name=?, street=?, streetWidth=?, lat=?, lng=?, features=?, trust=?,
        updatedAt=datetime('now')
      WHERE id=?
    `).run(
      p.title || existing.title, p.type || existing.type, p.purpose || existing.purpose, p.price || existing.price,
      p.area || existing.area, p.rooms ?? existing.rooms, p.baths ?? existing.baths, p.cars ?? existing.cars,
      p.facing || existing.facing, p.year || existing.year, p.age ?? existing.age, p.description || existing.description,
      p.city || existing.city, p.district || existing.district, p.area_name || existing.area_name,
      p.street || existing.street, p.streetWidth || existing.streetWidth, p.lat || existing.lat, p.lng || existing.lng,
      JSON.stringify(p.features || JSON.parse(existing.features || '[]')), p.trust || existing.trust, req.params.id
    );
    const property = db.prepare('SELECT * FROM properties WHERE id = ?').get(req.params.id);
    res.json({ success: true, property: formatProperty(property) });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.delete('/:id', protect, (req, res) => {
  try {
    const existing = db.prepare('SELECT * FROM properties WHERE id = ?').get(req.params.id);
    if (!existing) return res.status(404).json({ error: 'العقار غير موجود' });
    if (existing.agentUserId !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'غير مصرح بالحذف' });
    }
    db.prepare('DELETE FROM properties WHERE id = ?').run(req.params.id);
    res.json({ success: true, message: 'تم حذف العقار' });
  } catch (err) { res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.post('/:id/favorite', protect, (req, res) => {
  try {
    db.prepare('UPDATE properties SET favorites = favorites + 1 WHERE id = ?').run(req.params.id);
    const p = db.prepare('SELECT favorites FROM properties WHERE id = ?').get(req.params.id);
    res.json({ success: true, favorites: p?.favorites || 0 });
  } catch (err) { res.status(500).json({ error: 'خطأ داخلي' }); }
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
