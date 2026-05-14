import { EmptyWarning } from "@/components/empty-warning";
import { PageHeader } from "@/components/page-header";
import { PayrollContent } from "@/components/payroll-content";
import { getPayrollRows } from "@/lib/data";

export const dynamic = "force-dynamic";

export default async function PayrollPage() {
  const { data, error } = await getPayrollRows();

  return (
    <>
      <PageHeader title="급여명단 조회" description="월별 급여 요약과 차인지급액을 확인합니다." />
      <EmptyWarning message={error} />
      <PayrollContent rows={data} />
    </>
  );
}
