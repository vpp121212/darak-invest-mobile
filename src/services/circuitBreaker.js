import CircuitBreaker from 'opossum';
import sql from '../config/database.js';

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

async function fetchProperties(filters) {
  const cacheKey = `props:${JSON.stringify(filters)}`;
  const cached = getCached(cacheKey);
  if (cached) return cached;

  let conditions = ['status = $1'];
  let params = ['active'];
  let idx = 2;
  if (filters.city) { conditions.push(`city = $${idx++}`); params.push(filters.city); }
  if (filters.type) { conditions.push(`type = $${idx++}`); params.push(filters.type); }
  if (filters.purpose) { conditions.push(`purpose = $${idx++}`); params.push(filters.purpose); }

  const sql_query = `SELECT * FROM properties WHERE ${conditions.join(' AND ')} ORDER BY "createdAt" DESC LIMIT $${idx++} OFFSET $${idx++}`;
  params.push(Number(filters.limit || 20), Number(filters.offset || 0));
  const result = await sql.unsafe(sql_query, params);
  setCache(cacheKey, result);
  return result;
}

async function fetchSearch(query) {
  const cacheKey = `search:${query}`;
  const cached = getCached(cacheKey);
  if (cached) return cached;

  const result = await sql`SELECT * FROM properties WHERE status='active' AND (title ILIKE ${'%' + query + '%'} OR district ILIKE ${'%' + query + '%'} OR city ILIKE ${'%' + query + '%'}) LIMIT 20`;
  setCache(cacheKey, result);
  return result;
}

async function fetchStats() {
  const cached = getCached('stats');
  if (cached) return cached;

  const [{ c: total }] = await sql`SELECT COUNT(*)::int as c FROM properties`;
  const [{ c: active }] = await sql`SELECT COUNT(*)::int as c FROM properties WHERE status='active'`;
  const result = { total, active };
  setCache('stats', result);
  return result;
}

const propertiesBreaker = new CircuitBreaker(fetchProperties, breakerOptions);
const searchBreaker = new CircuitBreaker(fetchSearch, breakerOptions);
const statsBreaker = new CircuitBreaker(fetchStats, breakerOptions);

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

propertiesBreaker.on('open', () => console.log('🔴 Properties circuit OPEN'));
propertiesBreaker.on('halfOpen', () => console.log('🟡 Properties circuit HALF-OPEN'));
propertiesBreaker.on('close', () => console.log('🟢 Properties circuit CLOSED'));

searchBreaker.on('open', () => console.log('🔴 Search circuit OPEN'));
searchBreaker.on('close', () => console.log('🟢 Search circuit CLOSED'));

statsBreaker.on('open', () => console.log('🔴 Stats circuit OPEN'));
statsBreaker.on('close', () => console.log('🟢 Stats circuit CLOSED'));

export { propertiesBreaker, searchBreaker, statsBreaker, cache };
