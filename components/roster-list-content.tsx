"use client";

import { useMemo, useState } from "react";
import { DataPanel } from "@/components/data-panel";
import type { RosterRow } from "@/lib/data";
import { formatMonth } from "@/lib/format";

type RosterListContentProps = {
  rows: RosterRow[];
};

export function RosterListContent({ rows }: RosterListContentProps) {
  const months = useMemo(() => Array.from(new Set(rows.map((row) => row.roster_month))).sort((a, b) => b.localeCompare(a)), [rows]);
  const [month, setMonth] = useState(months[0] ?? "all");
  const [department, setDepartment] = useState("all");
  const [search, setSearch] = useState("");
  const departments = useMemo(
    () => Array.from(new Set(rows.map((row) => row.department_name_snapshot).filter(Boolean) as string[])).sort((a, b) => a.localeCompare(b, "ko")),
    [rows]
  );
  const normalizedSearch = search.trim().toLowerCase();
  const filteredRows = rows.filter((row) => {
    const monthMatches = month === "all" || row.roster_month === month;
    const departmentMatches = department === "all" || row.department_name_snapshot === department;
    const searchMatches = !normalizedSearch || (row.employee_name_snapshot ?? "").toLowerCase().includes(normalizedSearch);
    return monthMatches && departmentMatches && searchMatches;
  });

  return (
    <>
      <nav className="month-tabs mb-5" aria-label="월별명단 기준월 선택">
        <button className={month === "all" ? "active" : ""} type="button" onClick={() => setMonth("all")}>
          전체
        </button>
        {months.map((monthValue) => (
          <button key={monthValue} className={month === monthValue ? "active" : ""} type="button" onClick={() => setMonth(monthValue)}>
            {formatMonth(monthValue)}
          </button>
        ))}
      </nav>

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
        <div className="filter-count">조회 {filteredRows.length.toLocaleString("ko-KR")}명</div>
      </section>

      <DataPanel title={`${month === "all" ? "전체" : formatMonth(month)} 직원명단`}>
        <table className="data-table">
          <thead>
            <tr>
              <th>기준월</th>
              <th>직원번호</th>
              <th>성명</th>
              <th>부서</th>
              <th>직책</th>
              <th>입사일</th>
              <th>퇴사일</th>
              <th>재직기간</th>
            </tr>
          </thead>
          <tbody>
            {filteredRows.map((row) => (
              <tr key={`${row.roster_month}-${row.employee_code_snapshot}`}>
                <td className="numeric">{formatMonth(row.roster_month)}</td>
                <td className="numeric">{row.employee_code_snapshot}</td>
                <td>{row.employee_name_snapshot ?? "-"}</td>
                <td>{row.department_name_snapshot ?? "-"}</td>
                <td>{row.position_name_snapshot ?? "-"}</td>
                <td className="numeric">{row.hire_date ?? "-"}</td>
                <td className="numeric">{row.resignation_date ?? "-"}</td>
                <td>{row.tenure_text ?? "-"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </DataPanel>
    </>
  );
}
