# Next Task

Last updated: 2026-05-14

## Immediate Next Session Priorities

1. Configure linting properly for Next.js 15:
   - Replace deprecated `next lint` script with ESLint CLI.
   - Add a project ESLint config.
   - Verify `npm run lint` runs non-interactively.
2. Implement real upload persistence:
   - Save upload batch metadata.
   - Persist column mappings.
   - Validate required fields.
   - Show row-level validation errors.
   - Support reupload policy: delete existing rows for same period and data type, then import.
3. Replace upload history table-count view with true upload history:
   - `upload_batches` / `csv_import_batches` records.
   - File name, period month, uploader, row counts, success/error counts.
4. Improve list-page scalability:
   - Move filtering/search to server-side query params or API/RPC.
   - Add pagination or virtualized tables for large datasets.
   - Keep client filtering only for small lookup lists.

## High-Priority Product Follow-Ups

- Add explicit filters where useful:
  - 직원정보: 부서, 성명, 직종, 재직상태, 고용형태.
  - 월별명단: 기준월, 부서, 성명, 직책.
  - 급여명단: 기준월, 부서, 성명, 지급액 범위 if needed.
- Add empty-state messages when filters return 0 rows.
- Add reset filters button.
- Add export/download after filtering.
- Add row count and selected filter summary to each data panel.
- Add DB-backed code management UI for job category, gender, employment status, and payroll status mappings.

## Technical Follow-Ups

- Add a shared reusable filter bar component after finalizing filter requirements.
- Add a normalized payroll total strategy:
  - Prefer excluding total rows during transform or storing them in a separate monthly payroll summary table.
  - Avoid relying permanently on string checks like `총계` or employee code ending with `명`.
- Add API routes or server actions for upload processing instead of client-only parsing.
- Keep service role key server-only. Never expose it in client code.
- Add authentication before exposing HR/payroll data beyond local development.
- Review Supabase views for `security_invoker` and RLS posture before production.

## Intentionally Postponed

- Full browser-to-Supabase upload save.
- Column mapping editor.
- Validation error grid.
- Auth and role-based access control.
- Server-side pagination and database search.
- Automated tests.
- Deployment setup.

## Current Design Direction

- Quiet ERP-style admin UI.
- Dense but readable tables.
- Central-aligned table data per user preference.
- Neutral color palette with restrained orange accent.
- No marketing-style landing page.
- Keep HR/payroll terminology in Korean.

## Important Context For Next Agent

- The user prefers practical implementation over proposals.
- The user has repeatedly corrected UI details; preserve the current design tone and avoid heavy typography.
- The user asked that visible `Supabase` wording be replaced with `DB`. Internal code identifiers may still use Supabase names.
- Search fields were changed to name-only by user request. Do not revert to employee number search unless explicitly asked.
- Payroll total rows are present in data as rows where department is `총계` and employee code is like `844명`.
- Real HR/payroll CSV files are intentionally ignored under `supabase/upload_ready/`.
