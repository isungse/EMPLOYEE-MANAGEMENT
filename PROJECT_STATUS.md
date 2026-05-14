# Project Status

Last updated: 2026-05-14

## Project

Employee Management HR statistics web app built with Next.js, TypeScript, Tailwind CSS, and Supabase/Postgres.

Primary goal: HR users can review employee master data, monthly roster snapshots, payroll records, and statistics loaded from HR CSV/Excel sources.

## Current State

- Local app runs on `http://localhost:3002`.
- Supabase project in use: `mqvovjcveflkhfzpcdcu`.
- Frontend stack: Next.js App Router, React client components where filtering is interactive, Tailwind CSS utility styling, Supabase JS server-side data access.
- DB schema and transform SQL are stored under `supabase/`.
- `.env.local` is intentionally ignored and not committed.
- `supabase/upload_ready/` and `supabase/.temp/` are intentionally ignored to avoid committing real HR/payroll CSV data or local Supabase metadata.
- No repository-level `AGENTS.md` exists in this project.

## Completed Work

- Created initial Next.js HR statistics application structure.
- Connected server-side Supabase data access through `lib/supabase/server.ts`.
- Added dashboard with:
  - Month tabs.
  - Monthly summary KPI cards.
  - Monthly summary trend table.
  - Job-category gender, payroll, and hire/retirement statistics.
  - Client-side month switching to avoid repeated Supabase queries.
- Added employee information page:
  - Full employee list loading.
  - Department filter.
  - Name search.
- Added monthly roster page:
  - Full roster loading.
  - Month tabs.
  - Department filter.
  - Name search.
- Added payroll page:
  - Full payroll loading via paged Supabase REST queries.
  - Month tabs.
  - Total row separated into KPI cards.
  - Department filter.
  - Name search.
  - Total rows excluded from employee payroll table.
- Added upload page:
  - Data type selection.
  - Period month input.
  - CSV/XLS/XLSX file picker.
  - Header detection.
  - Column count and row count.
  - Top 20 row preview.
- Added import status page:
  - Raw/normalized table counts.
  - Korean table labels beside English table names.
- Adjusted UI:
  - Center-aligned table headers and cells.
  - Softer header navigation typography.
  - Removed app header subtitle.
  - Replaced visible `Supabase` wording with `DB`.
  - Tuned KPI card typography.
- Initialized Git repository, committed initial app, and pushed `main` to:
  - `https://github.com/isungse/EMPLOYEE-MANAGEMENT.git`

## Current Data Status

Verified Supabase data previously:

- `employee_info_imports`: 1542 rows
- `monthly_roster_imports`: 3260 rows
- `payroll_imports`: 3290 rows
- `employees`: 1542 rows
- `monthly_employee_rosters`: 3260 rows
- `payroll_records`: 3290 rows
- `payroll_line_items`: 161210 rows
- `v_employee_list`: 1542 rows
- `v_roster_list`: 3260 rows
- `v_payroll_list`: 3290 rows

## Partially Implemented

- Browser upload flow is analysis/preview only. It does not yet save parsed rows to Supabase.
- Column mapping UI is not implemented yet.
- Upload validation UI is not implemented yet.
- Reupload policy UI is not implemented yet.
- Upload history currently shows table counts, not true `upload_batches` history.
- Authentication, user roles, and app-level authorization are not implemented.
- RLS exists in DB design, but the current Next app uses server-side service-role access. This is acceptable for local development only and needs hardening before production.

## Known Risks

- Employee, roster, and payroll list pages currently load full result sets into server memory and pass them to client components for filtering. Current sample size is fine, but this should move to server-side filtering or paginated RPC/API routes as data grows.
- Search is client-side and only supports name search by latest user preference. If HR needs employee number lookup later, add it as a separate explicit field, not as a hidden combined search.
- Filter UI is duplicated across list components. This is acceptable for the current small scope, but a shared filter bar component should be introduced once filters stabilize.
- Payroll total-row detection is based on `department_name_snapshot === "총계"` or employee code ending with `명`. This matches current CSV transforms but should eventually be represented by an explicit `is_total_row` field or excluded during normalization.
- `npm run lint` is not currently configured. `next lint` prompts for setup and is deprecated for this Next.js version.
- No automated test suite exists yet.

## Verification

Last verification performed:

- `npm.cmd run build`: passed.
- `npm.cmd run lint`: not usable yet because Next.js prompts to configure ESLint and reports `next lint` deprecation.
- Browser checks performed during session:
  - Dashboard month tabs work without server reload.
  - Employee/roster/payroll filters render.
  - Name search fields render with placeholder `성명`.
  - Payroll total row is separated from table rows.

## Goal Consistency

Aligned:

- Enterprise-style admin UI direction.
- ERP-style HR data tables, filters, monthly snapshots, and statistics.
- Stable DB-backed architecture direction.

Not aligned / not applicable to this repository:

- Customer + inventory integration.
- Chrome Extension quotation workflow.

Those goals appear to belong to a different quotation/customer-inventory project. This repository is currently scoped to HR employee management and payroll statistics. Do not mix quotation workflow requirements into this HR app unless the product scope is explicitly changed.

## Stable Handoff Notes

- The app is in a stable buildable state.
- Current local working tree may contain post-initial-commit changes for filters and checkpoint docs.
- Before future production work, configure ESLint CLI, add tests, and replace service-role-only access with proper authenticated server routes and authorization rules.
