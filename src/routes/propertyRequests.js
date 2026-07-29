import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';

const router = Router();

router.get('/', protect, async (req, res) => {
  try {
    const requests = await sql`SELECT * FROM "propertyRequests" WHERE "userId" = ${req.user.id} ORDER BY "createdAt" DESC`;
    res.json({ success: true, requests });
  } catch (err) { res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.post('/', protect, async (req, res) => {
  try {
    const { city, district, type, purpose, minPrice, maxPrice, minArea, maxArea, rooms, notes } = req.body;
    const [result] = await sql`
      INSERT INTO "propertyRequests" ("userId", city, district, type, purpose, "minPrice", "maxPrice", "minArea", "maxArea", rooms, notes)
      VALUES (${req.user.id}, ${city}, ${district}, ${type}, ${purpose}, ${minPrice}, ${maxPrice}, ${minArea}, ${maxArea}, ${rooms}, ${notes})
      RETURNING id
    `;
    res.status(201).json({ success: true, id: result.id, message: 'تم إرسال طلبك بنجاح' });
  } catch (err) { res.status(500).json({ error: 'خطأ داخلي' }); }
});

export default router;
