"use client";

import { useMemo, useState } from "react";
import Papa from "papaparse";
import * as XLSX from "xlsx";

type DataType = "employee_info" | "monthly_roster" | "payroll";

const dataTypeOptions: Array<{ value: DataType; label: string }> = [
  { value: "employee_info", label: "직원정보" },
  { value: "monthly_roster", label: "월별직원명단" },
  { value: "payroll", label: "직원급여명단" }
];

type ParsedFile = {
  fileName: string;
  rowCount: number;
  columns: string[];
  rows: string[][];
};

function normalizeCell(value: unknown) {
  if (value === null || value === undefined) return "";
  return String(value).trim();
}

function normalizeGrid(rows: unknown[][]) {
  const nonEmptyRows = rows.filter((row) => row.some((cell) => normalizeCell(cell).length > 0));
  const header = (nonEmptyRows[0] ?? []).map(normalizeCell);
  const body = nonEmptyRows.slice(1).map((row) => header.map((_, index) => normalizeCell(row[index])));
  return { header, body };
}

async function parseCsv(file: File) {
  return new Promise<ParsedFile>((resolve, reject) => {
    Papa.parse<string[]>(file, {
      skipEmptyLines: true,
      complete: (result) => {
        const { header, body } = normalizeGrid(result.data);
        resolve({
          fileName: file.name,
          rowCount: body.length,
          columns: header,
          rows: body.slice(0, 20)
        });
      },
      error: (error) => reject(error)
    });
  });
}

async function parseWorkbook(file: File) {
  const buffer = await file.arrayBuffer();
  const workbook = XLSX.read(buffer, { type: "array" });
  const firstSheetName = workbook.SheetNames[0];
  const sheet = workbook.Sheets[firstSheetName];
  const grid = XLSX.utils.sheet_to_json<unknown[]>(sheet, { header: 1, raw: false, defval: "" });
  const { header, body } = normalizeGrid(grid);

  return {
    fileName: file.name,
    rowCount: body.length,
    columns: header,
    rows: body.slice(0, 20)
  };
}

async function parseFile(file: File) {
  const lowerName = file.name.toLowerCase();
  if (lowerName.endsWith(".csv")) return parseCsv(file);
  if (lowerName.endsWith(".xlsx") || lowerName.endsWith(".xls")) return parseWorkbook(file);
  throw new Error("CSV, XLSX, XLS 파일만 선택할 수 있습니다.");
}

export function UploadWorkspace() {
  const [dataType, setDataType] = useState<DataType>("employee_info");
  const [periodMonth, setPeriodMonth] = useState("");
  const [parsedFile, setParsedFile] = useState<ParsedFile | null>(null);
  const [error, setError] = useState<string | null>(null);
  const previewColumns = useMemo(() => parsedFile?.columns.slice(0, 10) ?? [], [parsedFile]);

  async function handleFileChange(file: File | undefined) {
    setError(null);
    setParsedFile(null);
    if (!file) return;

    try {
      const parsed = await parseFile(file);
      if (parsed.columns.length === 0) throw new Error("파일에서 헤더 행을 찾지 못했습니다.");
      setParsedFile(parsed);
    } catch (parseError) {
      setError(parseError instanceof Error ? parseError.message : "파일을 분석하지 못했습니다.");
    }
  }

  return (
    <div className="grid gap-6 lg:grid-cols-[360px_1fr]">
      <section className="panel p-5">
        <h2 className="mb-4 text-base font-bold">업로드 파일 선택</h2>
        <div className="grid gap-4">
          <label className="form-field">
            <span>데이터구분</span>
            <select value={dataType} onChange={(event) => setDataType(event.target.value as DataType)}>
              {dataTypeOptions.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </label>

          <label className="form-field">
            <span>기준월</span>
            <input type="month" value={periodMonth} onChange={(event) => setPeriodMonth(event.target.value)} />
          </label>

          <label className="form-field">
            <span>CSV 또는 엑셀 파일</span>
            <input type="file" accept=".csv,.xlsx,.xls" onChange={(event) => handleFileChange(event.target.files?.[0])} />
          </label>
        </div>

        <div className="mt-5 border-l-4 border-amber-500 bg-amber-50 px-4 py-3 text-sm font-semibold text-amber-900">
          현재 단계는 파일 분석과 미리보기까지 지원합니다. DB 저장은 컬럼 매핑과 재업로드 정책 확정 후 연결합니다.
        </div>
      </section>

      <section className="panel overflow-hidden">
        <div className="border-b border-border px-5 py-4">
          <h2 className="text-base font-bold">파일 분석 결과</h2>
          <p className="mt-1 text-sm text-gray-600">헤더, 행 수, 상위 20개 행을 확인합니다.</p>
        </div>

        {error ? <div className="m-5 border-l-4 border-red-500 bg-red-50 px-4 py-3 text-sm font-semibold text-red-800">{error}</div> : null}

        {!parsedFile ? (
          <div className="px-5 py-12 text-center text-sm font-semibold text-gray-500">파일을 선택하면 컬럼 분석 결과가 표시됩니다.</div>
        ) : (
          <>
            <div className="grid grid-cols-3 border-b border-border text-center">
              <div className="px-4 py-3">
                <div className="text-xs font-bold text-gray-500">파일명</div>
                <div className="mt-1 font-bold">{parsedFile.fileName}</div>
              </div>
              <div className="border-x border-border px-4 py-3">
                <div className="text-xs font-bold text-gray-500">데이터 행 수</div>
                <div className="numeric mt-1 font-bold">{parsedFile.rowCount.toLocaleString("ko-KR")}</div>
              </div>
              <div className="px-4 py-3">
                <div className="text-xs font-bold text-gray-500">컬럼 수</div>
                <div className="numeric mt-1 font-bold">{parsedFile.columns.length.toLocaleString("ko-KR")}</div>
              </div>
            </div>

            <div className="border-b border-border px-5 py-4">
              <div className="mb-2 text-sm font-bold">감지된 컬럼</div>
              <div className="flex flex-wrap gap-2">
                {parsedFile.columns.map((column, index) => (
                  <span key={`${column}-${index}`} className="badge">
                    {column || `빈 컬럼 ${index + 1}`}
                  </span>
                ))}
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="data-table">
                <thead>
                  <tr>
                    {previewColumns.map((column, index) => (
                      <th key={`${column}-${index}`}>{column || `컬럼 ${index + 1}`}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {parsedFile.rows.map((row, rowIndex) => (
                    <tr key={rowIndex}>
                      {previewColumns.map((_, columnIndex) => (
                        <td key={columnIndex}>{row[columnIndex] || "-"}</td>
                      ))}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </>
        )}
      </section>
    </div>
  );
}
