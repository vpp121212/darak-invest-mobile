# Darak Waheek — Microservices Boundaries

*Version: 1.0 — Design document (no physical split yet).*

## Goals

Keep the monolith deployable today while defining service boundaries so heavy paths
(cache, queues, websockets, AVM) can be split later without contract changes.

## Current Shared Services

| Service | Module | Fallback | Production mode |
| --- | --- | --- | --- |
| Cache | `src/services/cache.js` | in-memory `Map` | Redis (`REDIS_URL`) |
| Queue | `src/services/queue.js` | inline (`setImmediate`) | BullMQ (Redis) |
| Circuit breaker | `src/services/circuitBreaker.js` | memory fallbacks | uses cache |
| Socket.io adapter | `src/server.js` | in-memory adapter | `@socket.io/redis-adapter` |

All shared services degrade gracefully: **no Redis → no behavior change**.

## Proposed Service Map

| Service | Owned routes | Owns |
| --- | --- | --- |
| **Gateway / API** | everything under `/api` today | auth JWT middleware, rate limits, static `public/`, socket.io hub |
| **properties-search** | `/api/properties/*`, `/api/search/*`, `/api/listings`, `/api/map` | Postgres `properties` reads/writes, geospatial queries |
| **auth** | `/api/auth/*`, `/api/users/*` | accounts, sessions, roles, email verification |
| **payments** | `/api/payments/*`, `/api/subscriptions`, `/api/packages` | billing, invoices, webhooks |
| **ai-valuation** | `/api/avm/*`, `/api/valuation/*`, `/api/valuation-reports`, `/api/indicators` | AVM model, market indices, price index |
| **media** | `/api/upload/*` | image processing (sharp via queue), static `/uploads` |
| **skills** | `/api/skills/*` | PDF/EPUB → skill conversion (long jobs via queue) |
| **market-data** | `/api/market/*` | SAMA/TASI/CMA/gold/oil/indices fetchers, cached 30 min |

## Split Rules

- **Contract first**: keep the JSON shapes in `routes/*` identical after a split;
  only the HTTP base URL changes (behind the gateway).
- **Shared services move first**: `cache.js` and `queue.js` already speak Redis,
  so a split only requires each service to get `REDIS_URL`.
- **No service talks to Postgres directly except its own tables.**
- **Long-running work** (`/api/skills/convert`, image batches) must stay behind the
  queue and expose `202 { jobId }` + `GET /:jobId/status` — never block the gateway.
- **Websockets**: chat rooms must go through the redis adapter so any instance can
  deliver a message; the gateway remains the only socket.io endpoint.

## Migration Path (when needed)

1. Extract `auth` → validate gateway passes verified JWT to downstream services.
2. Extract `media` + `skills` (independent, queue-backed, few DB tables).
3. Extract `market-data` (read-only, cache-first).
4. Extract `properties-search` and `ai-valuation` (largest DB surface).
5. Extract `payments` last (needs webhook + reconciliation).

Until step 5, the monolith remains the deployment unit — all previous B items
(B-P1 cache, B-P2 queues, B-P3 redis adapter) work today without a split.
