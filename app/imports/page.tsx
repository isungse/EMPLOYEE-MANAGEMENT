import { DataPanel } from "@/components/data-panel";
import { EmptyWarning } from "@/components/empty-warning";
import { PageHeader } from "@/components/page-header";
import { formatNumber } from "@/lib/format";
import { getImportCounts } from "@/lib/data";

export const dynamic = "force-dynamic";

const tableLabels: Record<string, string> = {
  employee_info_imports: "직원정보 원본",
  monthly_roster_imports: "월별직원명단 원본",
  payroll_imports: "직원급여명단 원본",
  employees: "직원정보",
  monthly_employee_rosters: "월별직원명단",
  payroll_records: "직원급여명단",
  payroll_line_items: "급여 상세항목"
};

export default async function ImportsPage() {
  const { data, error } = await getImportCounts();

  return (
    <>
      <PageHeader title="업로드 이력" description="raw import 테이블과 정규 테이블의 적재 건수를 확인합니다." />
      <EmptyWarning message={error} />
      <DataPanel title="적재 현황">
        <table className="data-table">
          <thead>
            <tr>
              <th>테이블</th>
              <th className="text-right">건수</th>
              <th>상태</th>
            </tr>
          </thead>
          <tbody>
            {data.map((row) => (
              <tr key={row.table_name}>
                <td>{row.table_name} ({tableLabels[row.table_name] ?? "미지정"})</td>
                <td className="numeric text-right">{formatNumber(row.row_count)}</td>
                <td>
                  <span className="badge">{row.error ? "확인 필요" : "정상"}</span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </DataPanel>
    </>
  );
}
