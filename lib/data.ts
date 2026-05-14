import { getSupabaseAdmin } from "@/lib/supabase/server";
import type { SupabaseClient } from "@supabase/supabase-js";

export type DashboardSummary = {
  period_month: string;
  total_employees: number;
  hire_count: number;
  retirement_count: number;
  net_payment_total: number;
  net_payment_average: number | null;
};

export type GenderStat = {
  period_month: string;
  job_category_name: string;
  total_count: number;
  male_count: number;
  female_count: number;
  male_ratio: number | null;
  female_ratio: number | null;
};

export type PayrollStat = {
  period_month: string;
  job_category_name: string;
  payroll_count: number;
  net_payment_total: number;
  average_target_count: number;
  zero_payment_count: number;
  net_payment_average: number | null;
};

export type HireRetireStat = {
  period_month: string;
  job_category_name: string;
  base_count: number;
  hire_count: number;
  retirement_count: number;
  hire_ratio: number | null;
  retirement_ratio: number | null;
};

export type EmployeeRow = {
  employee_code: string;
  employee_name: string;
  gender: string | null;
  hire_date: string | null;
  retirement_date: string | null;
  department_name: string | null;
  job_category_name: string | null;
  status_name: string | null;
  employment_type_name: string | null;
  position_name: string | null;
};

export type RosterRow = {
  roster_month: string;
  employee_code_snapshot: string;
  employee_name_snapshot: string | null;
  department_name_snapshot: string | null;
  position_name_snapshot: string | null;
  hire_date: string | null;
  resignation_date: string | null;
  tenure_text: string | null;
};

export type PayrollRow = {
  period_month: string;
  employee_code_snapshot: string;
  employee_name_snapshot: string | null;
  department_name_snapshot: string | null;
  base_salary: number;
  earning_total: number;
  salary_total: number;
  deduction_total: number;
  net_payment: number;
};

type QueryResult<T> = { data: T; error: string | null };
type SupabaseQuery = PromiseLike<{ data: unknown; error: { message: string } | null }>;
type SupabaseTable = "v_employee_list" | "v_roster_list" | "v_payroll_list";
type QueryOrder = { column: string; ascending?: boolean };

async function query<T>(fn: (client: SupabaseClient) => SupabaseQuery, fallback: T): Promise<QueryResult<T>> {
  const client = getSupabaseAdmin();
  if (!client) return { data: fallback, error: "DB 환경변수가 설정되지 않았습니다." };
  const { data, error } = await fn(client);
  return { data: (data as T | null) ?? fallback, error: error?.message ?? null };
}

async function queryAll<T>(table: SupabaseTable, primaryOrder: QueryOrder, secondaryOrder?: QueryOrder): Promise<QueryResult<T[]>> {
  const client = getSupabaseAdmin();
  if (!client) return { data: [], error: "DB 환경변수가 설정되지 않았습니다." };

  const pageSize = 1000;
  const maxPages = 200;
  const rows: T[] = [];

  for (let pageIndex = 0; pageIndex < maxPages; pageIndex++) {
    const from = pageIndex * pageSize;
    let request = client.from(table).select("*").order(primaryOrder.column, { ascending: primaryOrder.ascending ?? true });
    if (secondaryOrder) request = request.order(secondaryOrder.column, { ascending: secondaryOrder.ascending ?? true });
    const { data, error } = await request.range(from, from + pageSize - 1);

    if (error) return { data: rows, error: error.message };
    const page = (data ?? []) as T[];
    rows.push(...page);
    if (page.length < pageSize) break;

    if (pageIndex === maxPages - 1) {
      return { data: rows, error: "조회 가능한 최대 행 수를 초과했습니다. 필터 또는 페이지네이션이 필요합니다." };
    }
  }

  return { data: rows, error: null };
}

export async function getDashboardData() {
  const [summary, gender, payroll, hireRetire] = await Promise.all([
    query<DashboardSummary[]>(
      (client) => client.from("v_dashboard_monthly_summary").select("*").order("period_month", { ascending: false }),
      []
    ),
    query<GenderStat[]>(
      (client) => client.from("v_monthly_gender_stats").select("*").order("period_month", { ascending: false }).limit(80),
      []
    ),
    query<PayrollStat[]>(
      (client) => client.from("v_monthly_payroll_stats").select("*").order("period_month", { ascending: false }).limit(80),
      []
    ),
    query<HireRetireStat[]>(
      (client) => client.from("v_monthly_hire_retire_stats").select("*").order("period_month", { ascending: false }).limit(80),
      []
    )
  ]);

  return { summary, gender, payroll, hireRetire };
}

export async function getEmployees() {
  return queryAll<EmployeeRow>("v_employee_list", { column: "employee_code", ascending: true });
}

export async function getRosters() {
  return queryAll<RosterRow>("v_roster_list", { column: "roster_month", ascending: false }, { column: "employee_code_snapshot" });
}

export async function getPayrollRows() {
  return queryAll<PayrollRow>("v_payroll_list", { column: "period_month", ascending: false }, { column: "employee_code_snapshot" });
}

export async function getImportCounts() {
  const client = getSupabaseAdmin();
  if (!client) return { data: [], error: "DB 환경변수가 설정되지 않았습니다." };
  const tables = ["employee_info_imports", "monthly_roster_imports", "payroll_imports", "employees", "monthly_employee_rosters", "payroll_records", "payroll_line_items"];
  const data = await Promise.all(
    tables.map(async (table) => {
      const { count, error } = await client.from(table).select("*", { count: "exact", head: true });
      return { table_name: table, row_count: count ?? 0, error: error?.message ?? null };
    })
  );
  const failedTables = data.filter((row) => row.error).map((row) => row.table_name);
  return {
    data,
    error: failedTables.length > 0 ? `적재 현황 조회 실패: ${failedTables.join(", ")}` : null
  };
}
