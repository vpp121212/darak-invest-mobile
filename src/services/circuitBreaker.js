import CircuitBreaker from 'opossum';
import db from '../config/database.js';

const cache = new Map();
const CACHE_TTL = 60000;

function getCached(key) {
  const item = cache.get(key);
  if (item && Date.now() - item.ts < CACHE_TTL) return item.data;
  return null;
}

function setCache(key, data) {
  cache.set(key, { data, ts: Date.now() });
}

const breakerOptions = {
  timeout: 3000,
  errorThresholdPercentage: 50,
  resetTimeout: 30000,
  volumeThreshold: 5
};

// Properties fetcher with circuit breaker
async function fetchProperties(filters) {
  const cacheKey = `props:${JSON.stringify(filters)}`;
  const cached = getCached(cacheKey);
  if (cached) return cached;

  let where = ['status = ?'];
  let params = ['active'];
  if (filters.city) { where.push('city = ?'); params.push(filters.city); }
  if (filters.type) { where.push('type = ?'); params.push(filters.type); }
  if (filters.purpose) { where.push('purpose = ?'); params.push(filters.purpose); }

  const sql = `SELECT * FROM properties WHERE ${where.join(' AND ')} ORDER BY createdAt DESC LIMIT ? OFFSET ?`;
  const result = db.prepare(sql).all(...params, Number(filters.limit || 20), Number(filters.offset || 0));
  setCache(cacheKey, result);
  return result;
}

// Search fetcher
async function fetchSearch(query) {
  const cacheKey = `search:${query}`;
  const cached = getCached(cacheKey);
  if (cached) return cached;

  const sql = `SELECT * FROM properties WHERE status='active' AND (title LIKE ? OR district LIKE ? OR city LIKE ?) LIMIT 20`;
  const s = `%${query}%`;
  const result = db.prepare(sql).all(s, s, s);
  setCache(cacheKey, result);
  return result;
}

// Stats fetcher
async function fetchStats() {
  const cached = getCached('stats');
  if (cached) return cached;

  const total = db.prepare('SELECT COUNT(*) as c FROM properties').get().c;
  const active = db.prepare("SELECT COUNT(*) as c FROM properties WHERE status='active'").get().c;
  const result = { total, active };
  setCache('stats', result);
  return result;
}

// Create breakers
const propertiesBreaker = new CircuitBreaker(fetchProperties, breakerOptions);
const searchBreaker = new CircuitBreaker(fetchSearch, breakerOptions);
const statsBreaker = new CircuitBreaker(fetchStats, breakerOptions);

// Fallbacks
propertiesBreaker.fallback((filters) => {
  const cacheKey = `props:${JSON.stringify(filters)}`;
  return getCached(cacheKey) || [];
});

searchBreaker.fallback((query) => {
  return getCached(`search:${query}`) || [];
});

statsBreaker.fallback(() => {
  return getCached('stats') || { total: 0, active: 0 };
});

// Events
propertiesBreaker.on('open', () => console.log('🔴 Properties circuit OPEN'));
propertiesBreaker.on('halfOpen', () => console.log('🟡 Properties circuit HALF-OPEN'));
propertiesBreaker.on('close', () => console.log('🟢 Properties circuit CLOSED'));

searchBreaker.on('open', () => console.log('🔴 Search circuit OPEN'));
searchBreaker.on('close', () => console.log('🟢 Search circuit CLOSED'));

statsBreaker.on('open', () => console.log('🔴 Stats circuit OPEN'));
statsBreaker.on('close', () => console.log('🟢 Stats circuit CLOSED'));

export { propertiesBreaker, searchBreaker, statsBreaker, cache };
