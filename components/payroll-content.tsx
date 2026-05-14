"use client";

import { useMemo, useState } from "react";
import { DataPanel } from "@/components/data-panel";
import { KpiCard } from "@/components/kpi-card";
import type { PayrollRow } from "@/lib/data";
import { formatCurrency, formatMonth, formatNumber } from "@/lib/format";

type PayrollContentProps = {
  rows: PayrollRow[];
};

function monthKey(month: string) {
  return month.slice(0, 7);
}

function isTotalRow(row: PayrollRow) {
  return row.department_name_snapshot === "총계" || row.employee_code_snapshot.endsWith("명");
}

export function PayrollContent({ rows }: PayrollContentProps) {
  const months = useMemo(() => Array.from(new Set(rows.map((row) => row.period_month))).sort((a, b) => b.localeCompare(a)), [rows]);
  const [selectedMonth, setSelectedMonth] = useState(months[0] ?? "");
  const [department, setDepartment] = useState("all");
  const [search, setSearch] = useState("");
  const selectedRows = rows.filter((row) => row.period_month === selectedMonth);
  const totalRow = selectedRows.find(isTotalRow);
  const departments = useMemo(
    () =>
      Array.from(
        new Set(
          rows
            .filter((row) => !isTotalRow(row))
            .map((row) => row.department_name_snapshot)
            .filter(Boolean) as string[]
        )
      ).sort((a, b) => a.localeCompare(b, "ko")),
    [rows]
  );
  const normalizedSearch = search.trim().toLowerCase();
  const employeeRows = selectedRows.filter((row) => {
    if (isTotalRow(row)) return false;
    const departmentMatches = department === "all" || row.department_name_snapshot === department;
    const searchMatches = !normalizedSearch || (row.employee_name_snapshot ?? "").toLowerCase().includes(normalizedSearch);
    return departmentMatches && searchMatches;
  });

  function selectMonth(month: string) {
    setSelectedMonth(month);
    window.history.replaceState(null, "", `/payroll?month=${monthKey(month)}`);
  }

  return (
    <>
      <nav className="month-tabs mb-5" aria-label="급여 기준월 선택">
        {months.map((month) => (
          <button key={month} className={selectedMonth === month ? "active" : ""} type="button" onClick={() => selectMonth(month)}>
            {formatMonth(month)}
          </button>
        ))}
      </nav>

      <div className="mb-6 grid grid-cols-5 gap-6">
        <KpiCard label="급여 인원" value={totalRow?.employee_code_snapshot ?? formatNumber(employeeRows.length)} />
        <KpiCard label="기본급 합계" value={totalRow ? formatCurrency(totalRow.base_salary) : "-"} />
        <KpiCard label="지급합계" value={totalRow ? formatCurrency(totalRow.earning_total) : "-"} />
        <KpiCard label="공제합계" value={totalRow ? formatCurrency(totalRow.deduction_total) : "-"} tone="negative" />
        <KpiCard label="차인지급액" value={totalRow ? formatCurrency(totalRow.net_payment) : "-"} tone="positive" />
      </div>

      <section className="filter-panel mb-5">
        <label>
          <span>부서</span>
          <select value={department} onChange={(event) => setDepartment(event.target.value)}>
            <option value="all">전체 부서</option>
            {departments.map((name) => (
              <option key={name} value={name}>
                {name}
              </option>
            ))}
          </select>
        </label>
        <label>
          <span>검색</span>
          <input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="성명" />
        </label>
        <div className="filter-count">조회 {employeeRows.length.toLocaleString("ko-KR")}명</div>
      </section>

      <DataPanel title={`${formatMonth(selectedMonth)} 직원급여명단`}>
        <table className="data-table">
          <thead>
            <tr>
              <th>기준월</th>
              <th>직원번호</th>
              <th>성명</th>
              <th>부서</th>
              <th>기본급</th>
              <th>지급합계</th>
              <th>급여합계</th>
              <th>공제합계</th>
              <th>차인지급액</th>
            </tr>
          </thead>
          <tbody>
            {employeeRows.map((row) => (
              <tr key={`${row.period_month}-${row.employee_code_snapshot}`}>
                <td className="numeric">{formatMonth(row.period_month)}</td>
                <td className="numeric">{row.employee_code_snapshot}</td>
                <td>{row.employee_name_snapshot ?? "-"}</td>
                <td>{row.department_name_snapshot ?? "-"}</td>
                <td className="numeric">{formatCurrency(row.base_salary)}</td>
                <td className="numeric">{formatCurrency(row.earning_total)}</td>
                <td className="numeric">{formatCurrency(row.salary_total)}</td>
                <td className="numeric">{formatCurrency(row.deduction_total)}</td>
                <td className="numeric">{formatCurrency(row.net_payment)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </DataPanel>
    </>
  );
}
