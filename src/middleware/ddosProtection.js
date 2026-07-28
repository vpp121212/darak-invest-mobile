const requests = new Map();

const CLEANUP_INTERVAL = 60000;
setInterval(() => {
  const now = Date.now();
  for (const [ip, data] of requests) {
    data.timestamps = data.timestamps.filter(t => now - t < 60000);
    if (data.timestamps.length === 0) requests.delete(ip);
  }
}, CLEANUP_INTERVAL);

export const ddosProtection = (req, res, next) => {
  const ip = req.headers['cf-connecting-ip'] || req.ip;
  const now = Date.now();

  if (!requests.has(ip)) requests.set(ip, { timestamps: [], blocked: false });
  const data = requests.get(ip);

  if (data.blocked && now - data.blockedAt < 300000) {
    return res.status(429).json({ error: 'نشاط مشبوه - محظور مؤقتاً', retryAfter: 300 });
  }
  data.blocked = false;

  data.timestamps = data.timestamps.filter(t => now - t < 60000);
  data.timestamps.push(now);

  if (data.timestamps.length > 1000) {
    data.blocked = true;
    data.blockedAt = now;
    return res.status(429).json({ error: 'نشاط مشبوه', challenge: true });
  }

  next();
};
