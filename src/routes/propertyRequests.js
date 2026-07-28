import { Router } from 'express';
import db from '../config/database.js';
import { protect } from '../middleware/auth.js';

const router = Router();

router.get('/', protect, (req, res) => {
  try {
    const requests = db.prepare('SELECT * FROM propertyRequests WHERE userId = ? ORDER BY createdAt DESC').all(req.user.id);
    res.json({ success: true, requests });
  } catch (err) { res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.post('/', protect, (req, res) => {
  try {
    const { city, district, type, purpose, minPrice, maxPrice, minArea, maxArea, rooms, notes } = req.body;
    const result = db.prepare(
      'INSERT INTO propertyRequests (userId, city, district, type, purpose, minPrice, maxPrice, minArea, maxArea, rooms, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
    ).run(req.user.id, city, district, type, purpose, minPrice, maxPrice, minArea, maxArea, rooms, notes);
    res.status(201).json({ success: true, id: result.lastInsertRowid, message: 'تم إرسال طلبك بنجاح' });
  } catch (err) { res.status(500).json({ error: 'خطأ داخلي' }); }
});

export default router;
