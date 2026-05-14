"use client";

import { useMemo, useState } from "react";
import { DataPanel } from "@/components/data-panel";
import { KpiCard } from "@/components/kpi-card";
import type { DashboardSummary, GenderStat, HireRetireStat, PayrollStat } from "@/lib/data";
import { formatCurrency, formatMonth, formatNumber, formatRatio } from "@/lib/format";

type DashboardContentProps = {
  summary: DashboardSummary[];
  gender: GenderStat[];
  payroll: PayrollStat[];
  hireRetire: HireRetireStat[];
  initialMonth?: string;
};

function uniqueMonths(...groups: Array<Array<{ period_month: string }>>) {
  return Array.from(new Set(groups.flat().map((row) => row.period_month))).sort((a, b) => b.localeCompare(a));
}

function monthKey(month: string) {
  return month.slice(0, 7);
}

export function DashboardContent({ summary, gender, payroll, hireRetire, initialMonth }: DashboardContentProps) {
  const months = useMemo(() => uniqueMonths(summary, gender, payroll, hireRetire), [summary, gender, payroll, hireRetire]);
  const initialSelectedMonth = initialMonth === "all" ? "all" : months.find((month) => monthKey(month) === initialMonth) ?? months[0] ?? "all";
  const [selectedMonth, setSelectedMonth] = useState(initialSelectedMonth);
  const isAllMonths = selectedMonth === "all";
  const selectedSummary = summary.find((row) => row.period_month === selectedMonth) ?? summary[0];
  const genderRows = isAllMonths ? gender : gender.filter((row) => row.period_month === selectedMonth);
  const payrollRows = isAllMonths ? payroll : payroll.filter((row) => row.period_month === selectedMonth);
  const hireRetireRows = isAllMonths ? hireRetire : hireRetire.filter((row) => row.period_month === selectedMonth);

  function selectMonth(month: string) {
    setSelectedMonth(month);
    const urlMonth = month === "all" ? "all" : monthKey(month);
    window.history.replaceState(null, "", `/?month=${urlMonth}`);
  }

  return (
    <>
      <nav className="month-tabs mb-5" aria-label="기준월 선택">
        <button className={isAllMonths ? "active" : ""} type="button" onClick={() => selectMonth("all")}>
          전체 추이
        </button>
        {months.map((month) => (
          <button key={month} className={selectedMonth === month ? "active" : ""} type="button" onClick={() => selectMonth(month)}>
            {formatMonth(month)}
          </button>
        ))}
      </nav>

      <div className="mb-6 grid grid-cols-4 gap-6">
        <KpiCard label="총 인원" value={selectedSummary?.total_employees} suffix="명" />
        <KpiCard label="입사 인원" value={selectedSummary?.hire_count} suffix="명" tone="positive" />
        <KpiCard label="퇴사 인원" value={selectedSummary?.retirement_count} suffix="명" tone="negative" />
        <KpiCard label="급여 합계" value={selectedSummary ? formatCurrency(selectedSummary.net_payment_total) : "-"} />
      </div>

      <div className="grid gap-6">
        <DataPanel title="월별 요약 추이">
          <table className="data-table">
            <thead>
              <tr>
                <th>기준월</th>
                <th>총 인원</th>
                <th>입사 인원</th>
                <th>퇴사 인원</th>
                <th>급여 합계</th>
                <th>평균 급여</th>
              </tr>
            </thead>
            <tbody>
              {summary.map((row) => (
                <tr key={row.period_month}>
                  <td className="numeric">{formatMonth(row.period_month)}</td>
                  <td className="numeric">{formatNumber(row.total_employees)}</td>
                  <td className="numeric">{formatNumber(row.hire_count)}</td>
                  <td className="numeric">{formatNumber(row.retirement_count)}</td>
                  <td className="numeric">{formatCurrency(row.net_payment_total)}</td>
                  <td className="numeric">{formatCurrency(row.net_payment_average)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </DataPanel>

        <DataPanel title="직종별 월별 성별 인원/비율">
          <table className="data-table">
            <thead>
              <tr>
                <th>기준월</th>
                <th>직종</th>
                <th>총 인원</th>
                <th>남성</th>
                <th>여성</th>
                <th>남성 비율</th>
                <th>여성 비율</th>
              </tr>
            </thead>
            <tbody>
              {genderRows.slice(0, 80).map((row) => (
                <tr key={`${row.period_month}-${row.job_category_name}`}>
                  <td className="numeric">{formatMonth(row.period_month)}</td>
                  <td>{row.job_category_name}</td>
                  <td className="numeric">{formatNumber(row.total_count)}</td>
                  <td className="numeric">{formatNumber(row.male_count)}</td>
                  <td className="numeric">{formatNumber(row.female_count)}</td>
                  <td className="numeric">{formatRatio(row.male_ratio)}</td>
                  <td className="numeric">{formatRatio(row.female_ratio)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </DataPanel>

        <DataPanel title="직종별 월별 급여 합계/평균">
          <table className="data-table">
            <thead>
              <tr>
                <th>기준월</th>
                <th>직종</th>
                <th>급여 인원</th>
                <th>급여 합계</th>
                <th>평균 대상</th>
                <th>0원 급여</th>
                <th>평균 급여</th>
              </tr>
            </thead>
            <tbody>
              {payrollRows.slice(0, 80).map((row) => (
                <tr key={`${row.period_month}-${row.job_category_name}`}>
                  <td className="numeric">{formatMonth(row.period_month)}</td>
                  <td>{row.job_category_name}</td>
                  <td className="numeric">{formatNumber(row.payroll_count)}</td>
                  <td className="numeric">{formatCurrency(row.net_payment_total)}</td>
                  <td className="numeric">{formatNumber(row.average_target_count)}</td>
                  <td className="numeric">{formatNumber(row.zero_payment_count)}</td>
                  <td className="numeric">{formatCurrency(row.net_payment_average)}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="border-t border-border px-5 py-3 text-sm text-gray-600">
            급여 평균은 급여금액이 0원 초과인 직원만 포함하여 계산합니다. 0원 급여자는 평균 계산에서만 제외됩니다.
          </div>
        </DataPanel>

        <DataPanel title="직종별 월별 입퇴사 인원/비율">
          <table className="data-table">
            <thead>
              <tr>
                <th>기준월</th>
                <th>직종</th>
                <th>기준 인원</th>
                <th>입사</th>
                <th>퇴사</th>
                <th>입사 비율</th>
                <th>퇴사 비율</th>
              </tr>
            </thead>
            <tbody>
              {hireRetireRows.slice(0, 80).map((row) => (
                <tr key={`${row.period_month}-${row.job_category_name}`}>
                  <td className="numeric">{formatMonth(row.period_month)}</td>
                  <td>{row.job_category_name}</td>
                  <td className="numeric">{formatNumber(row.base_count)}</td>
                  <td className="numeric">{formatNumber(row.hire_count)}</td>
                  <td className="numeric">{formatNumber(row.retirement_count)}</td>
                  <td className="numeric">{formatRatio(row.hire_ratio)}</td>
                  <td className="numeric">{formatRatio(row.retirement_ratio)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </DataPanel>
      </div>
    </>
  );
}
