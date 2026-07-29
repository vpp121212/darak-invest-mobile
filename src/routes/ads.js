import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';

const router = Router();

router.post('/add', protect, async (req, res) => {
  try {
    const { title, price, location, description } = req.body;

    const [ad] = await sql`
      INSERT INTO properties (title, type, purpose, price, area, rooms, baths, description, city, status, "agentUserId")
      VALUES (${title}, 'شقة', 'بيع', ${price}, 0, 0, 0, ${description}, ${location}, 'active', ${req.user.id})
      RETURNING id, title, price, city as location, description, "createdAt"
    `;

    res.status(201).json({
      message: 'تم إضافة الإعلان بنجاح',
      ad
    });
  } catch (error) {
    console.error('Add Ad Error:', error);
    res.status(500).json({ message: 'حدث خطأ غير متوقع' });
  }
});

export default router;
