import { EmptyWarning } from "@/components/empty-warning";
import { PageHeader } from "@/components/page-header";
import { RosterListContent } from "@/components/roster-list-content";
import { getRosters } from "@/lib/data";

export const dynamic = "force-dynamic";

export default async function RostersPage() {
  const { data, error } = await getRosters();

  return (
    <>
      <PageHeader title="월별 직원명단 조회" description="기준월별 직원 스냅샷을 확인합니다." />
      <EmptyWarning message={error} />
      <RosterListContent rows={data} />
    </>
  );
}
