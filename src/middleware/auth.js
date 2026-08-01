import jwt from 'jsonwebtoken';
import sql from '../config/database.js';

export const protect = async (req, res, next) => {
  let token;
  if (req.headers.authorization?.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }
  if (!token) return res.status(401).json({ error: 'غير مصرح' });

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback-jwt-secret-darak-2026');
    const [user] = await sql`SELECT id, name, email, phone, role FROM users WHERE id = ${decoded.id}`;
    if (!user) return res.status(401).json({ error: 'المستخدم غير موجود' });
    req.user = user;
    req.userId = user.id;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'رمز غير صالح' });
  }
};

export const authorize = (...roles) => (req, res, next) => {
  if (!roles.includes(req.user.role)) return res.status(403).json({ error: 'غير مصرح' });
  next();
};

export const generateTokens = (userId) => {
  const secret = process.env.JWT_SECRET || 'fallback-jwt-secret-darak-2026';
  const refreshSecret = process.env.JWT_REFRESH_SECRET || 'fallback-refresh-secret-darak-2026';
  const accessToken = jwt.sign({ id: userId }, secret, { expiresIn: '15m' });
  const refreshToken = jwt.sign({ id: userId }, refreshSecret, { expiresIn: '7d' });
  return { accessToken, refreshToken };
};
