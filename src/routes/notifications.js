import { Router } from 'express';
import sql from '../config/database.js';
import { protect } from '../middleware/auth.js';

const router = Router();

router.get('/', protect, async (req, res) => {
  try {
    const notifs = await sql`SELECT * FROM notifications WHERE "userId" = ${req.user.id} ORDER BY "createdAt" DESC LIMIT 50`;
    res.json({ success: true, notifications: notifs });
  } catch (err) { res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.put('/:id/read', protect, async (req, res) => {
  try {
    await sql`UPDATE notifications SET "isRead" = 1 WHERE id = ${req.params.id} AND "userId" = ${req.user.id}`;
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.post('/mark-all', protect, async (req, res) => {
  try {
    await sql`UPDATE notifications SET "isRead" = 1 WHERE "userId" = ${req.user.id}`;
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: 'خطأ داخلي' }); }
});

export default router;
