import { Router } from 'express';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import db from '../config/database.js';
import { generateTokens } from '../middleware/auth.js';
import { createRateLimiter } from '../middleware/security.js';

const router = Router();
const authLimiter = createRateLimiter('basic');

// Register
router.post('/register', authLimiter, async (req, res) => {
  try {
    const { name, email, phone, password } = req.body;
    if (!name || !email || !phone || !password) {
      return res.status(400).json({ error: 'أكمل جميع الحقول' });
    }

    const exists = db.prepare('SELECT id FROM users WHERE email = ?').get(email);
    if (exists) return res.status(400).json({ error: 'البريد مسجل مسبقاً' });

    const hashedPassword = await bcrypt.hash(password, 12);
    const result = db.prepare(
      'INSERT INTO users (name, email, phone, password) VALUES (?, ?, ?, ?)'
    ).run(name, email, phone, hashedPassword);

    const tokens = generateTokens(result.lastInsertRowid);
    db.prepare("UPDATE users SET refreshToken = ?, lastLogin = datetime('now') WHERE id = ?")
      .run(tokens.refreshToken, result.lastInsertRowid);

    res.status(201).json({
      success: true,
      user: { id: result.lastInsertRowid, name, email, role: 'user' },
      ...tokens
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'خطأ داخلي' });
  }
});

// Login
router.post('/login', authLimiter, async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'أدخل البريد وكلمة المرور' });

    const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email);
    if (!user) return res.status(401).json({ error: 'بيانات الدخول غير صحيحة' });

    const valid = await bcrypt.compare(password, user.password);
    if (!valid) return res.status(401).json({ error: 'بيانات الدخول غير صحيحة' });

    const tokens = generateTokens(user.id);
    db.prepare("UPDATE users SET refreshToken = ?, lastLogin = datetime('now') WHERE id = ?")
      .run(tokens.refreshToken, user.id);

    res.json({
      success: true,
      user: { id: user.id, name: user.name, email: user.email, role: user.role },
      ...tokens
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'خطأ داخلي' });
  }
});

// Refresh Token
router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) return res.status(400).json({ error: 'Refresh token مطلوب' });

    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(decoded.id);
    if (!user || user.refreshToken !== refreshToken) {
      return res.status(401).json({ error: 'Token غير صالح' });
    }

    const tokens = generateTokens(user.id);
    db.prepare('UPDATE users SET refreshToken = ? WHERE id = ?').run(tokens.refreshToken, user.id);

    res.json({ success: true, ...tokens });
  } catch (err) {
    res.status(401).json({ error: 'Token غير صالح' });
  }
});

// Logout
router.post('/logout', (req, res) => {
  const { userId } = req.body;
  if (userId) db.prepare('UPDATE users SET refreshToken = NULL WHERE id = ?').run(userId);
  res.json({ success: true });
});

// Get current user
router.get('/me', (req, res) => {
  let token;
  if (req.headers.authorization?.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }
  if (!token) return res.status(401).json({ error: 'غير مصرح' });
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = db.prepare('SELECT id, name, email, phone, role FROM users WHERE id = ?').get(decoded.id);
    if (!user) return res.status(401).json({ error: 'المستخدم غير موجود' });
    res.json({ success: true, user });
  } catch (err) {
    return res.status(401).json({ error: 'رمز غير صالح' });
  }
});

export default router;
