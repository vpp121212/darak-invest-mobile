# دارك وحيك — System Patterns

## Architecture Overview

```
public/index.html (SPA vanilla JS)
        ↕ fetch() / DOM manipulation
src/server.js (Express 5 entry)
        ↕ mount routes
src/routes/*.js (23 route modules)
        ↕ SQL via postgres tagged templates
src/config/database.js (schema + seed)
src/middleware/ (auth, security, validate, errorHandler)
src/validators/ (Zod + Joi schemas)
```

## Key Patterns

### 1. Route Module Pattern
Every route file exports a `Router` and is mounted in `server.js`:
- `signup.js` + `auth.js` → `/api/auth`
- `properties.js` → `/api/properties`
- `business.js` → `/api/business`
- `pulse.js` → `/api/pulse`
- etc.

### 2. Validation Middleware Pattern
Two-stage validation on write routes:
1. Zod/Joi schema validates shape + types in `validate.body()`
2. Route handler validates business logic (e.g., duplicate email)

### 3. Database Schema-as-Code
`src/config/database.js` contains:
- Full SQL schema (CREATE TABLE IF NOT EXISTS)
- Inline seed data with `ON CONFLICT DO NOTHING`
- Single `sql` export used by all routes

### 4. API Error Shape
- Success: `{ success: true, data... }`
- Validation error: `{ error: 'بيانات غير صالحة', details: [{ field, message }] }`
- Business error: `{ error: '...' }`
- Server error: `{ error: 'خطأ داخلي' }`

### 5. JWT Auth Flow
1. Login/Register → server returns `{ accessToken, refreshToken }`
2. Frontend stores in localStorage
3. `Authorization: Bearer <token>` on protected routes
4. Auth middleware populates `req.user`
5. Refresh endpoint for token rotation

### 6. Neighborhood Pulse Pattern
- Dedicated table `neighbourhood_pulse`
- Pre-seeded with 46 districts across 6 cities
- Two endpoints: `GET /api/pulse/:district`, `GET /api/pulse/city/:city`
- JSON columns for arrays (metro_stations, nearby_projects, green_spaces)
- Frontend: fetch on property detail overlay, show scored card

## Data Flow: Property Search
```
GET /api/properties?city=&type=&purpose=&minPrice=&maxPrice=&page=&limit=
  ↓ validate.query(propertyQuerySchema) [Zod]
  ↓ propertiesBreaker circuit breaker
  ↓ SQL query with dynamic WHERE conditions
  ↓ formatProperty() → JSON response
```

## Directory Structure
```
public/
  index.html         — SPA frontend
src/
  server.js          — Express entry + mount
  config/
    database.js      — Schema + seed
  middleware/
    auth.js          — JWT generate/verify
    security.js      — Helmet, rate limit, sanitize
    errorHandler.js  — Global error handler
    validate.js      — Body/query/params validation
  validators/
    auth.js          — Zod: register, login, refresh, profile
    property.js      — Joi: create/update, Zod: query
    business.js      — Zod: invoice, vendor
    ad.js            — Zod: create ad
  routes/
    auth.js, signup.js, properties.js, users.js, agents.js,
    search.js, upload.js, ai.js, notifications.js,
    propertyRequests.js, packages.js, myProperties.js,
    finance.js, marketing.js, legal.js, business.js,
    market.js, placeholder.js, tiles.js, chat.js,
    ads.js, pulse.js, panorama.js
  services/
    circuitBreaker.js
scripts/
  seed.js            — 47 properties across 6 cities
memory-bank/
  projectbrief.md    — This file
  systemPatterns.md  — This file
  activeContext.md   — Current state
  decisions.md       — ADR log
```
