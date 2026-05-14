# 인사관리 통계 프로젝트 — Code Review 보고서

작성일: 2026-05-14
검토 범위: `app/`, `components/`, `lib/`, `supabase/`, 설정 파일.
빌드 상태: `npm run build` 정상 통과 (Next.js 15.5.18).

---

## 1. 전체 평가

| 항목 | 상태 | 비고 |
|---|---|---|
| 빌드 | OK | 모든 라우트 컴파일 성공 |
| TypeScript strict | OK | `tsconfig.json` strict 활성화 |
| 디자인 일관성 | 양호 | `hr-design-rules.md` 토큰을 `globals.css`/`tailwind.config.ts`에 반영 |
| 보안 | 주의 필요 | service-role 키 노출 차단 보강 권장, RRN 해시 salt 부재 |
| 확장성 | 주의 필요 | 전체 결과를 클라이언트로 직렬화하는 패턴 누적 |
| 린트/테스트 | 미구성 | `npm run lint` 미동작, 자동화 테스트 없음 (`PROJECT_STATUS.md`에 기록됨) |

---

## 2. 우선순위 높은 이슈 (Should-Fix)

### 2.1 service-role 키의 클라이언트 누출 방지
`lib/supabase/server.ts` 가 `SUPABASE_SERVICE_ROLE_KEY`를 사용합니다. 현재 서버 컴포넌트 경유로만 호출되지만, 누군가가 클라이언트 컴포넌트에서 import 해도 빌드가 실패하지 않습니다.
- 권장: 파일 최상단에 `import "server-only";` 추가. 잘못된 import 시 빌드 단계에서 즉시 차단됩니다.

### 2.2 RRN(주민등록번호) 해싱에 salt 부재
`supabase/hr_transform_and_views.sql` 205-228행이 SHA-256만 적용합니다. RRN은 7+6 = 13자리 고정 형식이라 무염 해시는 사실상 회복 가능합니다.
- 권장: 환경 비밀(`current_setting('app.rrn_salt')`)을 prepend 후 해시, 또는 `pgsodium`/HMAC 사용. 데이터 마이그레이션 정책 필요.

### 2.3 `payroll_line_items` 전체 삭제 후 재삽입
`supabase/hr_transform_and_views.sql:321` `delete from public.payroll_line_items;` 가 매 변환마다 전체를 비웁니다. 부분 재업로드 시 다른 월 데이터까지 같이 날아가고, 16만 행 INSERT가 매번 재실행되어 비용이 큽니다.
- 권장: 대상 `payroll_period_id` 범위로 한정해 삭제 → INSERT. 또는 `ON CONFLICT` upsert로 전환.

### 2.4 뷰의 `security_invoker` 미설정
RLS를 켜둔 테이블(`employees`, `monthly_employee_rosters`, `payroll_records`)을 참조하는 뷰(`v_monthly_*`, `v_dashboard_*`)에 `WITH (security_invoker = on)` 옵션이 없습니다. 향후 anon/authenticated 클라이언트로 호출이 열리면 RLS 우회 위험이 있습니다.
- 권장: `create or replace view ... with (security_invoker = on, security_barrier = true) as ...`.

### 2.5 `getImportCounts`의 에러 집계 손실
`lib/data.ts:146-157` 는 각 테이블 쿼리 실패를 per-row `error`에 담지만, 함수 반환의 최상위 `error`는 항상 `null`입니다. `imports` 페이지의 `EmptyWarning`이 절대 트리거되지 않습니다.
- 권장: 실패가 하나라도 있으면 집계 메시지를 최상위 `error`로 올리거나, 행 단위로 "확인 필요" 배지가 이미 있으니 의도라면 주석으로 명시.

---

## 3. 우선순위 중간 이슈 (Worth-Fix)

### 3.1 데드 코드: 사용되지 않는 `monthKey`
`components/roster-list-content.tsx:12-14` 의 `monthKey`는 파일 내 어디서도 호출되지 않습니다. 삭제 권장.

### 3.2 `queryAll`의 `ascending` 결정 방식이 암묵적
`lib/data.ts:98` 가 `ascending: table === "v_employee_list"` 로 정렬 방향을 테이블명 비교로 결정합니다. 새 뷰가 추가될 때 동작이 비명시적입니다.
- 권장: `queryAll(table, { column, ascending }, ...)` 형태로 정렬 옵션을 명시 인자로.

### 3.3 무한 페이지 루프 잠재 위험
`lib/data.ts:97-106` `for (let from = 0; ; from += pageSize)` — API가 항상 `pageSize`만큼 반환하면 무한 루프. 안전망으로 최대 페이지 수(예: 200) 또는 최대 행 수 가드 추가 권장.

### 3.4 URL ↔ 상태 단방향 동기화
- `components/dashboard-content.tsx:35-39` 와 `components/payroll-content.tsx:48-51` 가 `window.history.replaceState` 로 URL을 쓰지만, payroll 페이지는 초기 마운트 시 `searchParams`를 읽지 않아서 URL 새로고침 후 월이 복원되지 않습니다. 대시보드는 props로 받고 있어 OK.
- 권장: payroll도 `searchParams.month` 를 props로 받아 `useState` 초기값에 반영.

### 3.5 `total row` 식별이 문자열 의존
`components/payroll-content.tsx:17-19` `department_name_snapshot === "총계"` / `employee_code.endsWith("명")`. `PROJECT_STATUS.md`/`NEXT_TASK.md`에도 기록된 알려진 한계입니다. 정규화 단계에서 `is_total_row boolean` 컬럼 도입을 추천(중기 과제로 합의됨).

### 3.6 클라이언트 메모리 부담
employees(1,542) / rosters(3,260) / payroll(3,290) 행 전체를 서버에서 직렬화 → 클라이언트에서 필터링하는 구조. 현재는 OK이나 monthly 누적으로 곧 한계.
- 권장: 서버 액션 또는 API 라우트로 필터를 옮기고, `useMemo`로 `departments`/`filteredRows` 메모이즈(필터 디바운스도 고려).

### 3.7 Tailwind ↔ CSS 변수 이중 정의
`tailwind.config.ts`는 색상을 hex 리터럴로 박아두고 (`tailwind.config.ts:7-14`), 같은 색을 `app/globals.css:5-14` 에서 CSS 변수로 재정의합니다. 한쪽이 바뀌면 다른 쪽과 어긋납니다.
- 권장: Tailwind 색상을 `var(--primary)` 형태로 묶어 단일 출처로 통합.

---

## 4. 사소한 이슈 / 일관성

- `app/page.tsx:27`: `initialMonth === "all" ? "all" : months.find(...) ?? months[0] ?? "all"` — 정상 동작하지만 가독성을 위해 괄호 추가 권장.
- `components/payroll-content.tsx:64`: `value={totalRow?.employee_code_snapshot ?? formatNumber(employeeRows.length)}` — `844명` 같은 문자열을 그대로 KPI에 표시. 의도면 OK, 아니면 숫자로 정제.
- `components/upload-workspace.tsx:30`: `body = nonEmptyRows.slice(1).map((row) => header.map((_, index) => normalizeCell(row[index])))` — 헤더 수에 맞춰 셀을 잘라내므로, 헤더보다 많은 컬럼이 있으면 데이터 손실. 현재 미리보기 용도라 OK이나 실제 적재 시 검증 필요.
- `lib/format.ts:1-4`: `formatMonth`이 단순히 `slice(0, 7)` 하므로 입력이 `YYYY-MM-DD` 가정. ISO 외 포맷 입력 시 무음 손실.
- ESLint 설정/실행 미동작 — 이미 `NEXT_TASK.md`의 1순위로 등록됨.

---

## 5. 잘 된 점

- 서버 컴포넌트가 데이터 페치, 클라이언트 컴포넌트가 인터랙션만 처리하는 분리가 일관됨.
- `query` / `queryAll` 헬퍼로 환경변수 누락/오류 처리 일원화.
- `PROJECT_STATUS.md` / `NEXT_TASK.md` / `hr-design-rules.md` 가 잘 정비되어 인수인계 컨텍스트가 분명.
- `force-dynamic` 명시로 DB 종속 라우트의 캐시 함정 회피.
- KPI/필터/테이블 컴포넌트가 적절히 분리되어 추가 페이지 작성 비용 낮음.

---

## 6. 다음 액션 제안 (정리)

1. `lib/supabase/server.ts` 상단에 `import "server-only"` 추가.
2. `roster-list-content.tsx` 의 미사용 `monthKey` 제거.
3. Supabase 뷰에 `security_invoker = on` 적용.
4. `process_hr_raw_imports` 의 `payroll_line_items` 삭제 범위를 처리 대상 기간으로 한정.
5. RRN 해시에 salt(또는 HMAC) 도입 및 재해싱 마이그레이션 계획.
6. `getImportCounts` 의 에러를 최상위로 집계.
7. `queryAll` 정렬 옵션 명시화 + 무한 루프 가드.
8. `NEXT_TASK.md` 의 ESLint 설정 / 서버측 필터링을 다음 작업으로 진행.
