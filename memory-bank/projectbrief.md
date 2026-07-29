# دارك وحيك — Project Brief

## Vision
Arabic RTL real estate platform enabling individuals and small brokers to list, discover, and analyze properties across Saudi Arabia without intermediaries.

## Core Goals
- Self-service property listing (post, edit, manage)
- Rich property discovery (search, filter, map, favorites)
- Neighborhood intelligence (مؤشر نبض الحي الذكي)
- Business tools (invoices, vendors, packages)
- Zero intermediary fees — direct owner-to-renter/buyer

## Target Users
- Individual property owners
- Small/medium real estate brokers
- Renters and buyers searching for properties

## Tech Stack
- **Backend**: Node.js + Express 5.2.1 (ESM)
- **Database**: PostgreSQL via `postgres` tagged-template library (Railway)
- **Frontend**: Single-page vanilla HTML/CSS/JS (no framework)
- **Auth**: JWT (access + refresh tokens) with bcrypt
- **Validation**: Zod (general) + Joi (property-specific)
- **Deployment**: Render (start: `node scripts/seed.js && node src/server.js`)
- **GitHub**: `https://github.com/vpp121212/darak-invest-mobile`

## Design Constraints
- RTL layout, dark theme, gold accent (#d4af37)
- Arabic-first UI
- Mobile-responsive
- 24/7 cloud service with persistent PostgreSQL storage
