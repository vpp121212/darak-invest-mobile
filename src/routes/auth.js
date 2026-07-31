import { Router } from 'express';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import rateLimit from 'express-rate-limit';
import sql from '../config/database.js';
import { generateTokens } from '../middleware/auth.js';
import { createRateLimiter } from '../middleware/security.js';
import { validate } from '../middleware/validate.js';
import { loginSchema, refreshSchema } from '../validators/auth.js';
import { Errors } from '../utils/errors.js';

const router = Router();
const authLimiter = createRateLimiter('basic');
const verifyOtpLimiter = rateLimit({ windowMs: 15 * 60 * 1000, limit: 15, standardHeaders: true, legacyHeaders: false });

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

function sendSMS(phone, message) {
  const appSid = process.env.UNIFONIC_APP_SID;
  if (!appSid) { console.log(`[SMS Mock] To ${phone}: ${message}`); return }
  const recipient = phone.startsWith('0') ? '966' + phone.slice(1) : phone;
  fetch('https://api.unifonic.com/rest/Messages/Send', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ AppSid: appSid, Recipient: recipient, Body: message })
  }).catch(err => console.error('SMS Error:', err));
}

router.post('/send-otp', authLimiter, async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) return res.status(400).json({ code: 'MISSING_PHONE', message: 'رقم الجوال مطلوب' });

    const otp = Math.floor(100000 + Math.random() * 900000);

    let [user] = await sql`SELECT id FROM users WHERE phone = ${phone}`;
    if (!user) {
      [user] = await sql`
        INSERT INTO users (name, email, phone, password)
        VALUES (${'مستخدم ' + phone.slice(-4)}, ${phone + '@phone.darak'}, ${phone}, ${'$2a$12$' + Math.random().toString(36).slice(2, 30)})
        RETURNING id
      `;
    }

    await sql`
      UPDATE users SET "otpCode" = ${otp.toString()}, "otpExpires" = ${(Date.now() + 5 * 60 * 1000).toString()}
      WHERE id = ${user.id}
    `;

    sendSMS(phone, `كود التحقق الخاص بك في دارك وحيك: ${otp}`);

    const smsConfigured = !!process.env.UNIFONIC_APP_SID;
    const payload = { message: 'تم إرسال كود التحقق إلى رقم الجوال' };
    if (!smsConfigured) payload.otp = otp.toString();

    res.json(payload);
  } catch (err) {
    console.error(err);
    res.status(500).json(Errors.internal().toJSON());
  }
});

router.post('/verify-otp', verifyOtpLimiter, async (req, res) => {
  try {
    const { phone, otp } = req.body;
    if (!phone || !otp) {
      return res.status(400).json({ code: 'MISSING_FIELDS', message: 'رقم الجوال والكود مطلوبان' });
    }

    const [user] = await sql`SELECT * FROM users WHERE phone = ${phone}`;
    if (!user) {
      return res.status(404).json({ code: 'NOT_FOUND', message: 'المستخدم غير موجود' });
    }

    if (!user.otpCode || user.otpCode !== otp.toString()) {
      return res.status(400).json({ code: 'INVALID_OTP', message: 'كود غير صحيح' });
    }

    if (parseInt(user.otpExpires) < Date.now()) {
      return res.status(400).json({ code: 'EXPIRED_OTP', message: 'انتهت صلاحية الكود، اطلب كود جديد' });
    }

    await sql`
      UPDATE users SET "phoneVerified" = 1, "otpCode" = NULL, "otpExpires" = NULL
      WHERE id = ${user.id}
    `;

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

export default router;
