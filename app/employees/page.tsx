import { DataPanel } from "@/components/data-panel";
import { EmptyWarning } from "@/components/empty-warning";
import { PageHeader } from "@/components/page-header";
import { getEmployees } from "@/lib/data";

export const dynamic = "force-dynamic";

export default async function EmployeesPage() {
  const { data, error } = await getEmployees();

  return (
    <>
      <PageHeader title="직원정보 조회" description="직원번호 기준으로 기본정보, 부서, 직종, 재직상태를 확인합니다." />
      <EmptyWarning message={error} />
      <DataPanel title="직원정보">
        <table className="data-table">
          <thead>
            <tr>
              <th>직원번호</th>
              <th>성명</th>
              <th>성별</th>
              <th>부서</th>
              <th>직종</th>
              <th>직책</th>
              <th>고용형태</th>
              <th>재직상태</th>
              <th>입사일</th>
              <th>퇴사일</th>
            </tr>
          </thead>
          <tbody>
            {data.map((row) => (
              <tr key={row.employee_code}>
                <td className="numeric">{row.employee_code}</td>
                <td>{row.employee_name}</td>
                <td className="text-center">{row.gender ?? "-"}</td>
                <td>{row.department_name ?? "-"}</td>
                <td>{row.job_category_name ?? "-"}</td>
                <td>{row.position_name ?? "-"}</td>
                <td>{row.employment_type_name ?? "-"}</td>
                <td>{row.status_name ?? "-"}</td>
                <td className="numeric">{row.hire_date ?? "-"}</td>
                <td className="numeric">{row.retirement_date ?? "-"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </DataPanel>
    </>
  );
}
