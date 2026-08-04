import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';

export const createRateLimiter = (type = 'basic') => {
  const configs = {
    basic: { windowMs: 15 * 60 * 1000, limit: 100 },
    strict: { windowMs: 15 * 60 * 1000, limit: 20 },
    auth: { windowMs: 15 * 60 * 1000, limit: 10 }
  };
  const cfg = configs[type] || configs.basic;
  return rateLimit({ windowMs: cfg.windowMs, limit: cfg.limit, standardHeaders: true, legacyHeaders: false });
};

const escapeString = (v) => v.trim().replace(/</g, '&lt;').replace(/>/g, '&gt;');

const sanitizeValue = (v) => {
  if (typeof v === 'string') return escapeString(v);
  if (Array.isArray(v)) return v.map(sanitizeValue);
  if (v && typeof v === 'object') {
    const out = {};
    for (const key in v) out[key] = sanitizeValue(v[key]);
    return out;
  }
  return v;
};

export const securityMiddleware = (app) => {
  app.use(helmet({ contentSecurityPolicy: false, crossOriginResourcePolicy: { policy: 'cross-origin' } }));

  app.use((req, res, next) => {
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-XSS-Protection', '1; mode=block');
    res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
    res.setHeader('X-Server', 'Darak-Wehayk');
    next();
  });

  app.use((req, res, next) => {
    if (req.body) {
      for (const key in req.body) req.body[key] = sanitizeValue(req.body[key]);
    }
    next();
  });
};

export const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Token unavailable' });
  try {
    const secret = process.env.JWT_SECRET || 'default-secret';
    req.user = jwt.verify(token, secret);
    next();
  } catch (err) {
    return res.status(403).json({ error: 'Token invalid' });
  }
};

export const validateRequest = (req, res, next) => {
  const suspiciousPatterns = /<script|javascript:|onload=|onerror=|alert\(/i;
  const bodyStr = JSON.stringify(req.body || {});
  const queryStr = JSON.stringify(req.query || {});
  if (suspiciousPatterns.test(bodyStr) || suspiciousPatterns.test(queryStr)) {
    return res.status(400).json({ error: 'Invalid request', code: 'THREAT_DETECTED' });
  }
  next();
};
