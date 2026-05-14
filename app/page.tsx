import { DashboardContent } from "@/components/dashboard-content";
import { EmptyWarning } from "@/components/empty-warning";
import { PageHeader } from "@/components/page-header";
import { requireAdmin } from "@/lib/auth/session";
import { getDashboardData } from "@/lib/data";

export const dynamic = "force-dynamic";

type DashboardPageProps = {
  searchParams?: Promise<{ month?: string }>;
};

export default async function DashboardPage({ searchParams }: DashboardPageProps) {
  await requireAdmin();
  const params = await searchParams;
  const { summary, gender, payroll, hireRetire } = await getDashboardData();
  const error = summary.error || gender.error || payroll.error || hireRetire.error;

  return (
    <>
      <PageHeader
        title="통계 대시보드"
        description="기준월과 직종을 기준으로 인원, 성별, 급여, 입퇴사 통계를 조회합니다."
      />
      <EmptyWarning message={error} />
      <DashboardContent
        summary={summary.data}
        gender={gender.data}
        payroll={payroll.data}
        hireRetire={hireRetire.data}
        initialMonth={params?.month}
      />
    </>
  );
}
