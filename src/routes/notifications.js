import { Router } from 'express';
import db from '../config/database.js';
import { protect } from '../middleware/auth.js';

const router = Router();

router.get('/', protect, (req, res) => {
  try {
    const notifs = db.prepare('SELECT * FROM notifications WHERE userId = ? ORDER BY createdAt DESC LIMIT 50').all(req.user.id);
    res.json({ success: true, notifications: notifs });
  } catch (err) { res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.put('/:id/read', protect, (req, res) => {
  try {
    db.prepare('UPDATE notifications SET isRead = 1 WHERE id = ? AND userId = ?').run(req.params.id, req.user.id);
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: 'خطأ داخلي' }); }
});

router.post('/mark-all', protect, (req, res) => {
  try {
    db.prepare('UPDATE notifications SET isRead = 1 WHERE userId = ?').run(req.user.id);
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: 'خطأ داخلي' }); }
});

export default router;
