import { Router } from 'express';
import db from '../config/database.js';
import { protect } from '../middleware/auth.js';

const router = Router();

router.get('/', (req, res) => {
  const { city, verified } = req.query;
  let sql = 'SELECT * FROM agents WHERE 1=1';
  const params = [];
  if (city) { sql += ' AND city = ?'; params.push(city); }
  if (verified) { sql += ' AND isVerified = ?'; params.push(verified === 'true' ? 1 : 0); }
  sql += ' ORDER BY rating DESC';
  const agents = db.prepare(sql).all(...params);
  res.json({ success: true, agents });
});

router.get('/:id', (req, res) => {
  const agent = db.prepare('SELECT * FROM agents WHERE id = ?').get(req.params.id);
  if (!agent) return res.status(404).json({ error: 'المكتب غير موجود' });
  const count = db.prepare('SELECT COUNT(*) as c FROM properties WHERE agentOfficeId = ?').get(agent.id);
  res.json({ success: true, agent: { ...agent, totalListings: count.c } });
});

router.post('/', protect, (req, res) => {
  try {
    const { officeName, commercialReg, city, district, description, phone, email } = req.body;
    if (!officeName || !city) return res.status(400).json({ error: 'أكمل الحقول المطلوبة' });
    const exists = db.prepare('SELECT id FROM agents WHERE userId = ?').get(req.user.id);
    if (exists) return res.status(400).json({ error: 'المكتب مسجل مسبقاً' });
    const result = db.prepare(
      'INSERT INTO agents (userId, officeName, commercialReg, city, district, description, phone, email) VALUES (?,?,?,?,?,?,?,?)'
    ).run(req.user.id, officeName, commercialReg || '000000', city, district || '', description || '', phone || req.user.phone, email || req.user.email);
    db.prepare("UPDATE users SET role = 'agent' WHERE id = ?").run(req.user.id);
    const agent = db.prepare('SELECT * FROM agents WHERE id = ?').get(result.lastInsertRowid);
    res.status(201).json({ success: true, agent });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.post('/register', protect, (req, res) => {
  const { officeName, commercialReg, city, district, description } = req.body;
  const result = db.prepare(
    'INSERT INTO agents (userId, officeName, commercialReg, city, district, description, phone, email) VALUES (?,?,?,?,?,?,?,?)'
  ).run(req.user.id, officeName, commercialReg, city, district, description, req.user.phone, req.user.email);
  const agent = db.prepare('SELECT * FROM agents WHERE id = ?').get(result.lastInsertRowid);
  res.status(201).json({ success: true, agent });
});

router.get('/:id/listings', (req, res) => {
  const listings = db.prepare("SELECT * FROM properties WHERE agentOfficeId = ? AND status = 'active'").all(req.params.id);
  res.json({ success: true, listings });
});

export default router;
