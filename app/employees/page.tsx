import { EmployeeListContent } from "@/components/employee-list-content";
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
      <EmployeeListContent rows={data} />
    </>
  );
}
