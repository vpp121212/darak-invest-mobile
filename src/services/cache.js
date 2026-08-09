// Unified cache layer: Redis (ioredis) when REDIS_URL is configured, otherwise
// an in-memory store. Every operation degrades gracefully — a Redis outage or
// an unset REDIS_URL never fails a request, it just falls back to the local
// map so the app stays fully functional on a single instance.
const memory = new Map();
const DEFAULT_TTL = 60000;

let redis = null;
let redisReady = false;
let redisFailed = false;

function disableRedis(err) {
  redisReady = false;
  redis = null;
  redisFailed = true;
  console.log('🟡 Redis cache disabled:', err?.message || err);
}

/// Connects to Redis if REDIS_URL is set and ioredis is installed.
/// Safe to call more than once; returns whether Redis is active.
export async function initCache() {
  if (redisFailed) return false;
  if (!process.env.REDIS_URL) return false;
  try {
    const { default: Redis } = await import('ioredis');
    redis = new Redis(process.env.REDIS_URL, {
      lazyConnect: true,
      connectTimeout: 2000,
      maxRetriesPerRequest: 1,
      retryStrategy: () => null,
    });
    redis.on('error', disableRedis);
    await redis.connect();
    redisReady = true;
    console.log('🟢 Redis cache connected');
  } catch (err) {
    disableRedis(err);
  }
  return redisReady;
}

export async function cacheGet(key) {
  if (redisReady && redis) {
    try {
      const raw = await redis.get(key);
      if (raw) return JSON.parse(raw);
    } catch (err) {
      disableRedis(err);
    }
  }
  const item = memory.get(key);
  if (item && Date.now() - item.ts < item.ttl) return item.data;
  if (item) memory.delete(key);
  return null;
}

export async function cacheSet(key, data, ttlMs = DEFAULT_TTL) {
  memory.set(key, { data, ts: Date.now(), ttl: ttlMs });
  if (redisReady && redis) {
    try {
      await redis.set(key, JSON.stringify(data), 'PX', ttlMs);
    } catch (err) {
      disableRedis(err);
    }
  }
}

export async function cacheDel(key) {
  memory.delete(key);
  if (redisReady && redis) {
    try {
      await redis.del(key);
    } catch (err) {
      disableRedis(err);
    }
  }
}

/// Removes all keys starting with `prefix` (Redis SCAN or memory iteration).
export async function cacheDelPrefix(prefix) {
  for (const key of [...memory.keys()]) {
    if (key.startsWith(prefix)) memory.delete(key);
  }
  if (redisReady && redis) {
    try {
      const stream = redis.scanStream({ match: `${prefix}*`, count: 100 });
      const keys = [];
      for await (const batch of stream) keys.push(...batch);
      if (keys.length) await redis.del(...keys);
    } catch (err) {
      disableRedis(err);
    }
  }
}

export function cacheHealth() {
  return { mode: redisReady ? 'redis' : 'memory' };
}
