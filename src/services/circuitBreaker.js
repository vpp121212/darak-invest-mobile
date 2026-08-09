import CircuitBreaker from 'opossum';
import sql from '../config/database.js';
import { cacheGet, cacheSet } from './cache.js';

const CACHE_TTL = 60000;

const breakerOptions = {
  timeout: 3000,
  errorThresholdPercentage: 50,
  resetTimeout: 30000,
  volumeThreshold: 5
};

async function fetchProperties(filters) {
  const cacheKey = `props:${JSON.stringify(filters)}`;
  const cached = await cacheGet(cacheKey);
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
  await cacheSet(cacheKey, result, CACHE_TTL);
  return result;
}

async function fetchSearch(query) {
  const cacheKey = `search:${query}`;
  const cached = await cacheGet(cacheKey);
  if (cached) return cached;

  const result = await sql`SELECT * FROM properties WHERE status='active' AND (title ILIKE ${'%' + query + '%'} OR district ILIKE ${'%' + query + '%'} OR city ILIKE ${'%' + query + '%'}) LIMIT 20`;
  await cacheSet(cacheKey, result, CACHE_TTL);
  return result;
}

async function fetchStats() {
  const cached = await cacheGet('stats');
  if (cached) return cached;

  const [{ c: total }] = await sql`SELECT COUNT(*)::int as c FROM properties`;
  const [{ c: active }] = await sql`SELECT COUNT(*)::int as c FROM properties WHERE status='active'`;
  const result = { total, active };
  await cacheSet('stats', result, CACHE_TTL);
  return result;
}

const propertiesBreaker = new CircuitBreaker(fetchProperties, breakerOptions);
const searchBreaker = new CircuitBreaker(fetchSearch, breakerOptions);
const statsBreaker = new CircuitBreaker(fetchStats, breakerOptions);

propertiesBreaker.fallback(async (filters) => {
  const cacheKey = `props:${JSON.stringify(filters)}`;
  return (await cacheGet(cacheKey)) || [];
});

searchBreaker.fallback(async (query) => {
  return (await cacheGet(`search:${query}`)) || [];
});

statsBreaker.fallback(async () => {
  return (await cacheGet('stats')) || { total: 0, active: 0 };
});

propertiesBreaker.on('open', () => console.log('🔴 Properties circuit OPEN'));
propertiesBreaker.on('halfOpen', () => console.log('🟡 Properties circuit HALF-OPEN'));
propertiesBreaker.on('close', () => console.log('🟢 Properties circuit CLOSED'));

searchBreaker.on('open', () => console.log('🔴 Search circuit OPEN'));
searchBreaker.on('close', () => console.log('🟢 Search circuit CLOSED'));

statsBreaker.on('open', () => console.log('🔴 Stats circuit OPEN'));
statsBreaker.on('close', () => console.log('🟢 Stats circuit CLOSED'));

export { propertiesBreaker, searchBreaker, statsBreaker };
