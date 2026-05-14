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
  const selectedRows = rows.filter((row) => row.period_month === selectedMonth);
  const totalRow = selectedRows.find(isTotalRow);
  const employeeRows = selectedRows.filter((row) => !isTotalRow(row));

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
