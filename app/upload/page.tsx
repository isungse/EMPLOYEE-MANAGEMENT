import { PageHeader } from "@/components/page-header";
import { UploadWorkspace } from "@/components/upload-workspace";

export default function UploadPage() {
  return (
    <>
      <PageHeader title="엑셀/CSV 업로드" description="업로드 파일의 컬럼 구조와 샘플 데이터를 먼저 분석합니다." />
      <UploadWorkspace />
    </>
  );
}
