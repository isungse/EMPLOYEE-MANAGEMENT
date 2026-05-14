import { DataPanel } from "@/components/data-panel";
import { EmptyWarning } from "@/components/empty-warning";
import { PageHeader } from "@/components/page-header";
import { formatMonth } from "@/lib/format";
import { getRosters } from "@/lib/data";

export const dynamic = "force-dynamic";

export default async function RostersPage() {
  const { data, error } = await getRosters();

  return (
    <>
      <PageHeader title="월별 직원명단 조회" description="기준월별 직원 스냅샷을 확인합니다." />
      <EmptyWarning message={error} />
      <DataPanel title="월별 직원명단">
        <table className="data-table">
          <thead>
            <tr>
              <th>기준월</th>
              <th>직원번호</th>
              <th>성명</th>
              <th>부서</th>
              <th>직책</th>
              <th>입사일</th>
              <th>퇴사일</th>
              <th>재직기간</th>
            </tr>
          </thead>
          <tbody>
            {data.map((row) => (
              <tr key={`${row.roster_month}-${row.employee_code_snapshot}`}>
                <td className="numeric">{formatMonth(row.roster_month)}</td>
                <td className="numeric">{row.employee_code_snapshot}</td>
                <td>{row.employee_name_snapshot ?? "-"}</td>
                <td>{row.department_name_snapshot ?? "-"}</td>
                <td>{row.position_name_snapshot ?? "-"}</td>
                <td className="numeric">{row.hire_date ?? "-"}</td>
                <td className="numeric">{row.resignation_date ?? "-"}</td>
                <td>{row.tenure_text ?? "-"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </DataPanel>
    </>
  );
}
