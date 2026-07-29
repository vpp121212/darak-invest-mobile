import { Router } from 'express';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import sql from '../config/database.js';
import { generateTokens } from '../middleware/auth.js';
import { createRateLimiter } from '../middleware/security.js';
import { validate } from '../middleware/validate.js';
import { loginSchema, refreshSchema } from '../validators/auth.js';
import { Errors } from '../utils/errors.js';

const router = Router();
const authLimiter = createRateLimiter('basic');

router.post('/login', authLimiter, validate.body(loginSchema), async (req, res) => {
  try {
    const { email, password } = req.body;

    const [user] = await sql`SELECT * FROM users WHERE email = ${email}`;
    if (!user) return res.status(401).json(Errors.unauthorized('بيانات الدخول غير صحيحة').toJSON());

    const valid = await bcrypt.compare(password, user.password);
    if (!valid) return res.status(401).json(Errors.unauthorized('بيانات الدخول غير صحيحة').toJSON());

    const tokens = generateTokens(user.id);
    await sql`UPDATE users SET "refreshToken" = ${tokens.refreshToken}, "lastLogin" = NOW() WHERE id = ${user.id}`;

    res.json({
      success: true,
      user: { id: user.id, name: user.name, email: user.email, role: user.role },
      ...tokens
    });
  } catch (err) {
    console.error(err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

router.post('/refresh', validate.body(refreshSchema), async (req, res) => {
  try {
    const { refreshToken } = req.body;

    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    const [user] = await sql`SELECT * FROM users WHERE id = ${decoded.id}`;
    if (!user || user.refreshToken !== refreshToken) {
      return res.status(401).json(Errors.invalidToken('Token غير صالح').toJSON());
    }

    const tokens = generateTokens(user.id);
    await sql`UPDATE users SET "refreshToken" = ${tokens.refreshToken} WHERE id = ${user.id}`;

    res.json({ success: true, ...tokens });
  } catch (err) {
    res.status(401).json(Errors.invalidToken().toJSON());
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
  if (!token) return res.status(401).json(Errors.unauthorized().toJSON());
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const [user] = await sql`SELECT id, name, email, phone, role FROM users WHERE id = ${decoded.id}`;
    if (!user) return res.status(401).json(Errors.unauthorized('المستخدم غير موجود').toJSON());
    res.json({ success: true, user });
  } catch (err) {
    return res.status(401).json(Errors.invalidToken().toJSON());
  }
});

export default router;
