import { EmptyWarning } from "@/components/empty-warning";
import { PageHeader } from "@/components/page-header";
import { PayrollContent } from "@/components/payroll-content";
import { requireAdmin } from "@/lib/auth/session";
import { getPayrollRows } from "@/lib/data";

export const dynamic = "force-dynamic";

type PayrollPageProps = {
  searchParams?: Promise<{ month?: string }>;
};

export default async function PayrollPage({ searchParams }: PayrollPageProps) {
  await requireAdmin();
  const params = await searchParams;
  const { data, error } = await getPayrollRows();

  return (
    <>
      <PageHeader title="급여명단 조회" description="월별 급여 요약과 차인지급액을 확인합니다." />
      <EmptyWarning message={error} />
      <PayrollContent rows={data} initialMonth={params?.month} />
    </>
  );
}
