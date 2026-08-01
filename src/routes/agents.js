import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';

const router = Router();

router.get('/', async (req, res) => {
  const { city, verified } = req.query;
  let conditions = ['1=1'];
  let params = [];
  let idx = 0;
  if (city) { conditions.push(`city = $${++idx}`); params.push(city); }
  if (verified) { conditions.push(`"isVerified" = $${++idx}`); params.push(verified === 'true' ? 1 : 0); }
  const agents = await sql.unsafe(`SELECT * FROM agents WHERE ${conditions.join(' AND ')} ORDER BY rating DESC`, params);
  res.json({ success: true, agents });
});

router.get('/:id', async (req, res) => {
  const [agent] = await sql`SELECT * FROM agents WHERE id = ${req.params.id}`;
  if (!agent) return res.status(404).json({ error: 'المكتب غير موجود' });
  const [{ c: count }] = await sql`SELECT COUNT(*)::int as c FROM properties WHERE "agentOfficeId" = ${agent.id}`;
  res.json({ success: true, agent: { ...agent, totalListings: count } });
});

router.post('/', protect, async (req, res) => {
  try {
    const { officeName, commercialReg, city, district, description, phone, email } = req.body;
    if (!officeName || !city) return res.status(400).json({ error: 'أكمل الحقول المطلوبة' });
    const [exists] = await sql`SELECT id FROM agents WHERE "userId" = ${req.user.id}`;
    if (exists) return res.status(400).json({ error: 'المكتب مسجل مسبقاً' });
    const [result] = await sql`
      INSERT INTO agents ("userId", "officeName", "commercialReg", city, district, description, phone, email)
      VALUES (${req.user.id}, ${officeName}, ${commercialReg || '000000'}, ${city}, ${district || ''}, ${description || ''}, ${phone || req.user.phone}, ${email || req.user.email})
      RETURNING id
    `;
    await sql`UPDATE users SET role = 'agent' WHERE id = ${req.user.id}`;
    const [agent] = await sql`SELECT * FROM agents WHERE id = ${result.id}`;
    res.status(201).json({ success: true, agent });
  } catch (err) { console.error(err); res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.post('/register', protect, async (req, res) => {
  const { officeName, commercialReg, city, district, description } = req.body;
  const [result] = await sql`
    INSERT INTO agents ("userId", "officeName", "commercialReg", city, district, description, phone, email)
    VALUES (${req.user.id}, ${officeName}, ${commercialReg}, ${city}, ${district}, ${description}, ${req.user.phone}, ${req.user.email})
    RETURNING id
  `;
  const [agent] = await sql`SELECT * FROM agents WHERE id = ${result.id}`;
  res.status(201).json({ success: true, agent });
});

router.get('/:id/listings', async (req, res) => {
  const listings = await sql`SELECT * FROM properties WHERE "agentOfficeId" = ${req.params.id} AND status = 'active'`;
  res.json({ success: true, listings });
});

export default router;
