# دارك وحيك — Architecture Decision Records

## ADR-001: Express 5 over Express 4
**Date**: 2025-01
**Context**: Starting the project, needed a web framework.
**Decision**: Express 5.2.1 (latest). Provides built-in async error handling, `app.delete()` without router, improved regex.
**Consequences**: Body parser must be before security middleware (Express 5 quirk).

## ADR-002: Vanilla JS SPA over React/Vue/Svelte
**Date**: 2025-01
**Context**: Need a lightweight frontend that can be served as static files from Express.
**Decision**: Single `index.html` with vanilla JS. No build step, no framework.
**Consequences**: More verbose DOM manipulation, but zero dependencies and instant deploy.

## ADR-003: PostgreSQL via `postgres` library
**Date**: 2025-01
**Context**: Need a database for property listings. Railway provides free PostgreSQL.
**Decision**: `postgres` (tagged-template library) over Sequelize/Knex. Minimal abstraction, raw SQL.
**Consequences**: SQL written by hand, but full control and no ORM overhead.

## ADR-004: Inline schema + seed in database.js
**Date**: 2025-01
**Context**: Need to deploy to Render with automatic setup.
**Decision**: Schema and seed data live in `src/config/database.js`, executed on import. `ON CONFLICT DO NOTHING` for idempotency.
**Consequences**: Schema changes require modifying this file, no migration history.

## ADR-005: Zod + Joi dual validation
**Date**: 2026-07
**Context**: Need input validation on all write routes.
**Decision**: Use Zod for simple schemas (auth, ads, business) and Joi for complex property schemas (Joi has better Arabic error messages for enums).
**Consequences**: Two validation libraries, but each used where it excels.

## ADR-006: Neighborhood Pulse JSON columns
**Date**: 2026-07
**Context**: Pulse data has nested arrays (metro stations, projects, green spaces).
**Decision**: Store as JSON text columns, parse on read. Avoids join tables for data that is almost always read as a whole.
**Consequences**: Cannot query individual metro stations in SQL, but data access pattern is all-or-nothing.

## ADR-007: Memory Bank Documentation
**Date**: 2026-07
**Context**: Need structured project documentation for AI-assisted development.
**Decision**: Adopt the Memory Bank pattern (projectbrief, systemPatterns, activeContext, decisions).
**Consequences**: Documentation lives alongside code, easy to update, clear session handoff.
