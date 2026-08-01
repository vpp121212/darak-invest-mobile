# دارك وحيك — Active Context

## Current State
- Server deployed on Render, PostgreSQL on Railway
- 47 seed properties across 6 cities (الرياض, جدة, مكة, الدمام, الخبر, الباحة)
- 46 neighborhoods with pulse data
- Zod + Joi validation on auth, property, ad, business routes
- Full property CRUD with JWT auth
- Neighborhood Pulse Index with scored UI

## Recently Completed
- Added 46-district pulse data (was 8)
- Color-coded pulse UI with overall score (0-100)
- Zod validation: register, login, refresh, profile
- Joi validation: property create/update
- Zod validation: ads, invoices, vendors, property query
- Unified validation middleware (`validate.body/query/params`)

## Current Priority
- Consistent tagged JSON error system across all APIs
- Memory bank documentation

## Open Issues
- Port 5000 occasionally stuck (need `lsof -ti :5000 | xargs kill -9`)
- Some routes still use ad-hoc error messages
- No MLS/API reconciliation for properties
- No property image upload (panorama only)

## Next Session
- Check what the user wants to work on next
- Likely candidates:
  - Unified error system
  - Property image upload
  - Frontend improvements
  - More property seed data
