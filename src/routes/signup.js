import { Router } from 'express';
import bcrypt from 'bcryptjs';
import sql from '../config/database.js';
import { generateTokens } from '../middleware/auth.js';
import { createRateLimiter } from '../middleware/security.js';

const router = Router();
const authLimiter = createRateLimiter('basic');

router.post('/register', authLimiter, async (req, res) => {
  try {
    const { name, email, phone, password } = req.body;
    if (!name || !email || !phone || !password) {
      return res.status(400).json({ error: 'أكمل جميع الحقول' });
    }

    const [exists] = await sql`SELECT id FROM users WHERE email = ${email}`;
    if (exists) return res.status(400).json({ error: 'البريد مسجل مسبقاً' });

    const hashedPassword = await bcrypt.hash(password, 12);
    const [result] = await sql`
      INSERT INTO users (name, email, phone, password) VALUES (${name}, ${email}, ${phone}, ${hashedPassword})
      RETURNING id
    `;

    const tokens = generateTokens(result.id);
    await sql`UPDATE users SET "refreshToken" = ${tokens.refreshToken}, "lastLogin" = NOW() WHERE id = ${result.id}`;

    res.status(201).json({
      success: true,
      user: { id: result.id, name, email, role: 'user' },
      ...tokens
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'خطأ داخلي' });
  }
});

export default router;
