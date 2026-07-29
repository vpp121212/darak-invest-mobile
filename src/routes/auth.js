import { Router } from 'express';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import sql from '../config/database.js';
import { generateTokens } from '../middleware/auth.js';
import { createRateLimiter } from '../middleware/security.js';

const router = Router();
const authLimiter = createRateLimiter('basic');

router.post('/login', authLimiter, async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'أدخل البريد وكلمة المرور' });

    const [user] = await sql`SELECT * FROM users WHERE email = ${email}`;
    if (!user) return res.status(401).json({ error: 'بيانات الدخول غير صحيحة' });

    const valid = await bcrypt.compare(password, user.password);
    if (!valid) return res.status(401).json({ error: 'بيانات الدخول غير صحيحة' });

    const tokens = generateTokens(user.id);
    await sql`UPDATE users SET "refreshToken" = ${tokens.refreshToken}, "lastLogin" = NOW() WHERE id = ${user.id}`;

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

router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) return res.status(400).json({ error: 'Refresh token مطلوب' });

    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    const [user] = await sql`SELECT * FROM users WHERE id = ${decoded.id}`;
    if (!user || user.refreshToken !== refreshToken) {
      return res.status(401).json({ error: 'Token غير صالح' });
    }

    const tokens = generateTokens(user.id);
    await sql`UPDATE users SET "refreshToken" = ${tokens.refreshToken} WHERE id = ${user.id}`;

    res.json({ success: true, ...tokens });
  } catch (err) {
    res.status(401).json({ error: 'Token غير صالح' });
  }
});

router.post('/logout', async (req, res) => {
  const { userId } = req.body;
  if (userId) await sql`UPDATE users SET "refreshToken" = NULL WHERE id = ${userId}`;
  res.json({ success: true });
});

router.get('/me', async (req, res) => {
  let token;
  if (req.headers.authorization?.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }
  if (!token) return res.status(401).json({ error: 'غير مصرح' });
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const [user] = await sql`SELECT id, name, email, phone, role FROM users WHERE id = ${decoded.id}`;
    if (!user) return res.status(401).json({ error: 'المستخدم غير موجود' });
    res.json({ success: true, user });
  } catch (err) {
    return res.status(401).json({ error: 'رمز غير صالح' });
  }
});

export default router;
