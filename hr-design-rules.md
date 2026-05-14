# HR Management Web Design Rules

**Design System:** The Alpha Standard for HR Management SaaS  
**Target Project:** 엑셀/CSV 업로드 기반 Supabase 인사관리 통계 웹 프로그램  
**Purpose:** 인사팀이 직원정보, 월별직원명단, 급여명단을 업로드하고 통계 데이터를 조회하는 업무용 웹 프로그램의 UI/UX 규칙을 정의한다.

---

## 1. Design Direction

### 1.1 Core Principles

- UI는 **Neutral-Heavy Palette**를 기반으로 한다.
- 장식보다 **데이터 가독성, 업무 흐름, 정보 밀도, 오류 방지**를 우선한다.
- 인사/급여 데이터는 민감정보이므로 신뢰감 있고 절제된 엔터프라이즈 UI를 적용한다.
- 구조적 구분은 그림자나 장식 효과가 아니라 **간격, 정렬, 1px border**로 표현한다.
- 모든 화면은 대량 데이터 조회, 업로드 검증, 통계 확인에 적합해야 한다.

### 1.2 Do Not Use

다음 표현은 사용하지 않는다.

- Decorative shadow
- Gradient
- Glassmorphism
- 과도한 border-radius
- 과도한 애니메이션
- 데이터 가독성을 떨어뜨리는 강한 배경색
- 의미 없는 장식 아이콘
- Primary color의 남용

---

## 2. Color System

### 2.1 Base Tokens

| Token | Usage | Color |
|---|---|---|
| `surface-body` | 전체 페이지 배경 | `#F2F4F7` |
| `surface-card` | 카드, 패널, 컨테이너 배경 | `#FFFFFF` |
| `border-default` | 기본 구조선 | `#DBDBDB` |
| `text-primary` | 주요 텍스트 | `#1F2937` |
| `text-secondary` | 보조 텍스트 | `#6B7280` |
| `primary` | 주요 CTA | `#FF7200` |
| `positive` | 완료, 정상, 증가 | `#33732E` |
| `negative` | 오류, 실패, 감소, 위험 | `#BF3030` |

### 2.2 Primary Color Usage

`#FF7200`은 주요 액션에만 제한적으로 사용한다.

사용 가능:

- 업로드 실행
- 저장
- 다음 단계
- 조회 실행
- 최종 제출

사용 금지:

- 삭제
- 덮어쓰기
- 재업로드 확정
- 오류 표시
- 급여 위험 알림
- 일반 장식 요소

### 2.3 Semantic Colors

| Meaning | Color Family | Usage |
|---|---|---|
| Success | Green / Emerald | 업로드 완료, 저장 성공, 정상 데이터 |
| Warning | Amber | 검증 필요, 매핑 누락, 확인 필요 |
| Error | Red / Rose | 오류, 실패, 삭제, 덮어쓰기 위험 |
| Info | Blue / Slate | 일반 안내, 중립 상태, 도움말 |

### 2.4 Chart Colors

- 차트는 고대비·저채도 팔레트를 사용한다.
- gradient는 사용하지 않는다.
- 색상만으로 의미를 전달하지 말고 범례와 수치 라벨을 함께 제공한다.
- 급여, 인원, 비율 그래프는 시각적 화려함보다 해석 가능성을 우선한다.

---

## 3. Typography

### 3.1 Korean-Friendly Font Stack

한국어 라벨, 직원명, 부서명, 직종명, 숫자 데이터가 많은 화면이므로 sans-serif 기반 폰트를 사용한다.

```css
font-family: "Pretendard", "Apple SD Gothic Neo", "Noto Sans KR", "Malgun Gothic", system-ui, sans-serif;
font-size: 14px;
line-height: 1.5;
letter-spacing: 0.01em;
```

### 3.2 Font Size

| Element | Size |
|---|---:|
| Body text | `14px` |
| Table cell | `14px` |
| Form label | `13px` 또는 `14px` |
| Section title | `16px` 또는 `18px` |
| Page title | `20px` 또는 `24px` |
| KPI number | `24px` 또는 `28px` |

### 3.3 Numeric Data

숫자 데이터는 정렬 안정성을 위해 항상 tabular numbers를 사용한다.

```css
font-variant-numeric: tabular-nums;
```

적용 대상:

- 급여금액
- 급여 합계
- 평균 급여
- 인원수
- 비율
- 기준월
- 날짜
- 직원번호
- 업로드 건수

---

## 4. Layout System

### 4.1 8-Point Grid

모든 margin, padding, gap, spacing은 **8pt grid system**을 따른다.

| Token | Value | Usage |
|---|---:|---|
| `space-1` | `8px` | 최소 간격 |
| `space-2` | `16px` | 기본 내부 여백 |
| `space-3` | `24px` | 카드/위젯 간격 |
| `space-4` | `32px` | 섹션 간격 |
| `space-5` | `40px` | 큰 영역 분리 |

### 4.2 Page Layout

- 페이지 배경은 `#F2F4F7`을 사용한다.
- 주요 콘텐츠는 `#FFFFFF` 카드 또는 패널에 배치한다.
- 카드, 패널, 테이블, 입력 영역은 `1px solid #DBDBDB` border를 사용한다.
- 대시보드 카드와 위젯 간 간격은 `24px`로 유지한다.
- 사용자의 작업 완료 액션은 **하단 우측**에 배치한다.

### 4.3 Density Rule

- 인사관리 시스템은 데이터 밀도가 높아야 하지만, 행 간격과 구분선은 충분히 유지한다.
- 한 화면에 너무 많은 CTA를 노출하지 않는다.
- 표, 필터, 업로드 단계, 오류 결과는 각각 명확한 영역으로 구분한다.

---

## 5. Borders, Radius, and Elevation

### 5.1 Border

- 기본 구조선은 `1px solid #DBDBDB`를 사용한다.
- 테이블, 카드, 입력 컴포넌트, 배지 모두 border 기준을 통일한다.
- 화면 구분은 shadow가 아니라 border와 spacing으로 처리한다.

### 5.2 Radius

| Component | Rule |
|---|---|
| Card / Panel | Minimal radius |
| Button | Moderate radius |
| Status Badge | Capsule / pill style 허용 |
| Technical Badge | Subtle rounded corner |
| Enterprise Label | Minimal rounded corner |

### 5.3 Shadow

- 기본적으로 shadow는 사용하지 않는다.
- hover, focus 상태에서도 장식용 shadow는 사용하지 않는다.
- focus는 outline 또는 border 강조로 표현한다.

---

## 6. Buttons and Actions

### 6.1 Primary Action

- 저장, 업로드, 다음 단계, 조회 등 주요 액션은 하단 우측에 배치한다.
- Primary CTA 색상은 `#FF7200`을 사용한다.
- 하나의 작업 영역에는 Primary CTA를 1개만 둔다.

### 6.2 Secondary Action

- 취소, 이전, 초기화, 닫기 등 보조 액션은 Primary CTA의 좌측에 배치한다.
- Secondary 버튼은 흰색 배경과 `1px solid #DBDBDB` border를 사용한다.

### 6.3 Destructive Action

삭제, 덮어쓰기, 재업로드 확정과 같은 위험 작업은 별도 규칙을 따른다.

- Primary orange를 사용하지 않는다.
- Red 계열을 사용하되 과도한 배경 강조는 피한다.
- 반드시 확인 모달을 제공한다.
- 급여 데이터 삭제, 기준월 데이터 삭제, 기존 데이터 덮어쓰기는 작업 전 영향 범위를 표시한다.
- 확인 문구에는 대상 데이터구분, 기준월, 예상 삭제/수정 건수를 명확히 표시한다.

예시:

```text
2026-01 직원급여명단 128건을 삭제 후 재업로드합니다. 이 작업은 되돌릴 수 없습니다.
```

---

## 7. Spreadsheet and Data Grid UI

### 7.1 Grid Architecture

- 직원정보, 월별직원명단, 급여명단, 업로드 미리보기 화면은 spreadsheet-like grid로 구현한다.
- CSS Grid, Flexbox 또는 검증된 Data Grid 컴포넌트를 사용할 수 있다.
- 대량 데이터 조회와 필터링에 적합해야 한다.

### 7.2 Dimensions

| Element | Fixed Height |
|---|---:|
| Header Row | `48px` |
| Data Row | `40px` |

### 7.3 Column Alignment

| Column Type | Alignment |
|---|---|
| 성명, 부서, 직종, 비고 | Left |
| 급여, 인원, 비율, 건수 | Right |
| 상태, 재직여부, 지급여부, 배지 | Center |
| 기준월, 날짜 | Center or Right |
| 직원번호, 코드 | Center or Left |

### 7.4 Inline Editing

- 셀은 click-to-edit inline interaction을 지원할 수 있다.
- 보기 상태와 편집 상태 전환 시 layout shift가 발생하면 안 된다.
- 편집 input은 기존 셀의 width, height, padding을 유지한다.
- 저장 전 변경된 셀은 과도하지 않은 표시로 구분한다.

### 7.5 Table Readability

- 숫자는 천 단위 구분을 적용한다.
- 비율은 `%` 단위를 표시한다.
- 급여 데이터는 우측 정렬한다.
- 누락값은 빈칸보다 `-` 또는 명확한 placeholder를 사용한다.
- 오류 행은 강한 배경색 대신 좌측 border, 아이콘, 상태 텍스트로 표시한다.

---

## 8. Upload Flow UI

엑셀/CSV 업로드는 이 프로젝트의 핵심 업무 흐름이므로 단계형 UI로 구성한다.

### 8.1 Upload Steps

업로드 화면은 다음 흐름을 따른다.

1. 데이터구분 선택
2. 기준월 입력 또는 선택
3. 파일 업로드
4. 파일 컬럼 자동 분석
5. 표준 컬럼 매핑
6. 업로드 전 미리보기
7. 검증 오류 확인
8. Supabase DB 저장

### 8.2 Data Type Selection

데이터구분은 명확하게 선택하게 한다.

- 직원정보
- 월별직원명단
- 직원급여명단

선택된 데이터구분에 따라 필수 매핑 필드와 검증 규칙을 다르게 표시한다.

### 8.3 기준월 UI

- 기준월 형식은 `YYYY-MM`을 사용한다.
- 파일에 기준월 컬럼이 없을 경우 업로드 화면에서 입력한 기준월을 전체 행에 적용한다.
- 기준월이 통계 기준임을 명확히 안내한다.

### 8.4 Column Mapping UI

- 실제 업로드 컬럼과 시스템 표준 컬럼을 나란히 보여준다.
- 필수 매핑 필드는 누락 시 저장 버튼을 비활성화한다.
- 자동 매핑된 컬럼과 사용자가 직접 수정한 컬럼을 구분해서 표시한다.
- 예시 표준 컬럼: 기준월, 직원번호, 성명, 성별, 직종, 입사일, 퇴사일, 급여금액, 재직여부, 재직상태, 부서, 직급, 고용형태

### 8.5 Preview UI

- 저장 전 최소 일부 행을 미리 보여준다.
- 급여명단 업로드 시 급여금액 컬럼은 우측 정렬하고 숫자 형식을 적용한다.
- 컬럼 매핑 오류, 필수값 누락, 숫자 형식 오류는 미리보기 단계에서 확인 가능해야 한다.

---

## 9. Validation and Error UI

### 9.1 Validation Principles

- 오류는 DB 저장 전에 표시한다.
- 사용자가 어느 행, 어느 컬럼, 어떤 문제가 있는지 즉시 이해할 수 있어야 한다.
- 오류 메시지는 개발자 용어가 아니라 업무 담당자가 이해할 수 있는 한국어로 작성한다.

### 9.2 Validation Categories

업로드 검증 결과는 다음 유형으로 구분한다.

| Type | Meaning | UI Treatment |
|---|---|---|
| Error | 저장 불가 | Red text, icon, row marker |
| Warning | 저장 가능하지만 확인 필요 | Amber text, icon |
| Info | 참고 정보 | Slate or Blue text |

### 9.3 Required Validation Items

- 필수 컬럼 누락
- 기준월 누락
- 직원번호 누락
- 성별 값 오류
- 직종 누락
- 급여금액 숫자 형식 오류
- 입사일/퇴사일 날짜 형식 오류
- 동일 기준월 + 직원번호 중복
- 동일 파일 반복 업로드 가능성
- 표준 컬럼 매핑 누락

### 9.4 Error Row Display

- 오류 행은 과도한 붉은 배경으로 채우지 않는다.
- 좌측 border, 오류 아이콘, 오류 배지, 오류 메시지를 조합한다.
- 오류 목록 클릭 시 해당 행으로 이동할 수 있게 한다.

---

## 10. HR Dashboard and Analytics

### 10.1 KPI Cards

대시보드 상단에는 기본적으로 4개의 Summary Card를 배치한다.

권장 구성:

1. 당월 총 인원
2. 당월 입사 인원
3. 당월 퇴사 인원
4. 당월 급여 합계 또는 평균 급여

급여 화면 전용 구성:

1. 급여 총액
2. 평균 급여
3. 급여 대상 인원
4. 0원 급여 인원

### 10.2 KPI Card Rules

- 카드 배경은 `#FFFFFF`를 사용한다.
- 카드 border는 `1px solid #DBDBDB`를 사용한다.
- shadow는 사용하지 않는다.
- 카드 간격은 `24px`로 고정한다.
- KPI 숫자에는 tabular numbers를 적용한다.
- 증가/정상은 `#33732E`, 감소/오류는 `#BF3030`을 사용한다.

### 10.3 Statistics Tables

통계 표는 다음 항목에 최적화한다.

- 직종별 월별 남녀 인원/비율
- 직종별 월별 급여 합계/평균
- 직종별 월별 입퇴사 인원/비율

표에는 기준월, 직종, 인원, 비율, 급여금액을 명확히 표시한다.

### 10.4 Salary Average Rule UI

급여 평균 계산 기준은 화면에서 설명 가능해야 한다.

```text
급여 평균은 급여금액이 0원 초과인 직원만 포함하여 계산합니다.
0원 급여자는 평균 계산에서만 제외되며, 인원 통계에서는 제외하지 않습니다.
```

---

## 11. Label and Badge System

### 11.1 Status Semantic Badge

일반 업무 상태 표시에 사용한다.

예시:

- 업로드 완료
- 검증 중
- 저장 완료
- 재직
- 퇴사
- 지급
- 미지급

규칙:

- Capsule / pill shape 사용
- 저채도 배경색 사용
- 고대비 텍스트 사용
- 상태 텍스트를 반드시 포함
- 필요 시 아이콘 또는 dot 추가

### 11.2 Rectangular Accent Badge

기술적 상태, 검증 오류, 배치 처리 상태에 사용한다.

예시:

- 매핑 누락
- 중복 데이터
- 급여 오류
- 날짜 형식 오류
- 업로드 실패

규칙:

- 사각형 기반 형태 사용
- subtle rounded corner 적용
- 좌측 `4px` accent border 사용 가능
- 오류 심각도에 따라 색상을 다르게 적용

### 11.3 Classic Enterprise Label

데이터 밀도가 높은 인사관리 화면에 사용한다.

예시:

- 직종 코드
- 재직상태
- 고용형태
- 부서 코드
- 지급여부

규칙:

- 최소한의 rounded corner 사용
- 작은 status dot 사용 가능
- small, bold typography 사용
- 텍스트가 표 데이터보다 과도하게 튀지 않게 한다.

### 11.4 Entity Label

직원, 부서, 조직 식별에 사용한다.

규칙:

- 직원은 `성명 + 직원번호`를 함께 표시한다.
- 부서는 `부서명 + 부서코드`를 함께 표시할 수 있다.
- 동명이인 가능성을 고려하여 성명만 단독 식별값으로 사용하지 않는다.

### 11.5 Metadata Tag

기준월, 데이터구분, 업로드 파일명, 업로드 건수 등 보조 정보를 표시한다.

예시:

```text
기준월: 2026-01 | 데이터구분: 직원급여명단 | 상태: 업로드 완료
```

---

## 12. Sensitive Data and Security UI

인사정보와 급여정보는 민감정보이므로 UI에서 다음 규칙을 따른다.

### 12.1 Salary Data Display

- 급여 화면은 일반 직원정보 화면보다 더 명확한 접근 권한 표시를 제공한다.
- 필요 시 급여 금액 마스킹 옵션을 제공한다.
- 급여 다운로드, 삭제, 재업로드 작업은 확인 절차를 강화한다.

### 12.2 Permission Awareness

- 권한이 없는 사용자는 급여 데이터, 삭제 버튼, 재업로드 확정 버튼을 볼 수 없어야 한다.
- 버튼만 비활성화하지 말고 권한 부족 사유를 명확히 안내한다.

### 12.3 Audit-Friendly UI

다음 정보는 업로드 이력 화면에서 확인 가능해야 한다.

- 업로드 일시
- 업로드자
- 파일명
- 데이터구분
- 기준월
- 총건수
- 성공건수
- 오류건수
- 중복 처리 방식

---

## 13. Empty, Loading, and Confirmation States

### 13.1 Empty State

데이터가 없는 화면은 다음 정보를 제공한다.

- 현재 데이터가 없다는 설명
- 사용자가 다음에 해야 할 행동
- 관련 CTA

예시:

```text
아직 업로드된 직원급여명단이 없습니다.
기준월을 선택한 뒤 엑셀 또는 CSV 파일을 업로드해 주세요.
```

### 13.2 Loading State

- 업로드, 검증, 저장, 통계 계산 중에는 진행 상태를 표시한다.
- 대량 데이터 처리 시 단계별 상태를 보여준다.
- 로딩 중 중복 클릭을 방지한다.

### 13.3 Confirmation Dialog

위험 작업에는 확인 모달을 사용한다.

필수 표시 항목:

- 작업명
- 데이터구분
- 기준월
- 영향 건수
- 되돌릴 수 없는지 여부
- 확인/취소 버튼

---

## 14. Accessibility and Readability

- 색상만으로 상태를 전달하지 않는다.
- 상태는 텍스트, 아이콘, dot, border 등을 함께 사용한다.
- 모든 버튼과 입력 요소는 keyboard focus 상태를 제공한다.
- 텍스트 대비는 업무용 화면에서 충분히 읽을 수 있어야 한다.
- 숫자와 비율에는 단위를 함께 표시한다.
- 표 헤더는 스크롤 시 고정할 수 있도록 설계한다.
- 긴 표에서는 가로 스크롤과 고정 컬럼을 고려한다.

---

## 15. Implementation Tokens

```css
:root {
  --surface-body: #F2F4F7;
  --surface-card: #FFFFFF;
  --border-default: #DBDBDB;

  --text-primary: #1F2937;
  --text-secondary: #6B7280;

  --primary: #FF7200;
  --positive: #33732E;
  --negative: #BF3030;

  --space-1: 8px;
  --space-2: 16px;
  --space-3: 24px;
  --space-4: 32px;
  --space-5: 40px;

  --grid-header-height: 48px;
  --grid-row-height: 40px;

  --font-body: "Pretendard", "Apple SD Gothic Neo", "Noto Sans KR", "Malgun Gothic", system-ui, sans-serif;
}
```

---

## 16. Production Checklist

UI 구현 시 다음 항목을 확인한다.

### 16.1 Visual Checklist

- [ ] 전체 배경은 `#F2F4F7`인가?
- [ ] 카드와 컨테이너는 `#FFFFFF` 배경과 `1px solid #DBDBDB` border를 사용하는가?
- [ ] shadow와 gradient를 제거했는가?
- [ ] 모든 spacing이 8pt grid를 따르는가?
- [ ] 카드/위젯 간격이 `24px`로 유지되는가?
- [ ] Primary orange가 주요 CTA에만 제한적으로 사용되는가?

### 16.2 Data Grid Checklist

- [ ] 표 헤더 높이가 `48px`, 행 높이가 `40px`인가?
- [ ] 숫자 데이터에 `font-variant-numeric: tabular-nums`가 적용되어 있는가?
- [ ] 급여, 인원, 비율은 우측 정렬되어 있는가?
- [ ] 텍스트, 숫자, 상태 컬럼의 정렬 규칙이 지켜졌는가?
- [ ] inline edit 전환 시 layout shift가 없는가?

### 16.3 Upload Flow Checklist

- [ ] 데이터구분, 기준월, 파일 업로드, 컬럼 매핑, 미리보기, 검증, 저장 단계가 구분되어 있는가?
- [ ] 실제 업로드 컬럼과 표준 컬럼의 매핑 상태가 명확한가?
- [ ] 필수 매핑 누락 시 저장 버튼이 비활성화되는가?
- [ ] 검증 오류가 행/컬럼 단위로 표시되는가?
- [ ] 저장 전 오류 데이터를 확인할 수 있는가?

### 16.4 HR Security Checklist

- [ ] 급여 데이터 화면에 권한 및 민감정보 처리가 반영되어 있는가?
- [ ] 삭제, 덮어쓰기, 재업로드 확정 작업에 확인 모달이 있는가?
- [ ] 위험 작업에 Primary orange를 사용하지 않는가?
- [ ] 업로드 이력과 영향 건수를 확인할 수 있는가?

---

## 17. Final Delivery Standard

모든 산출물은 production-ready 수준이어야 한다.  
UI는 높은 정보 밀도를 유지하면서도 전문적이고 정돈된 인상을 제공해야 한다.  
최종 목표는 **업무 생산성, 데이터 가독성, 오류 예방, 민감정보 보호, 엔터프라이즈급 신뢰감**을 동시에 만족하는 것이다.
