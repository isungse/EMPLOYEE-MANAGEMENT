"use client";

import { useMemo, useState } from "react";
import { DataPanel } from "@/components/data-panel";
import type { EmployeeRow } from "@/lib/data";

type EmployeeListContentProps = {
  rows: EmployeeRow[];
};

export function EmployeeListContent({ rows }: EmployeeListContentProps) {
  const [department, setDepartment] = useState("all");
  const [search, setSearch] = useState("");
  const departments = useMemo(
    () => Array.from(new Set(rows.map((row) => row.department_name).filter(Boolean) as string[])).sort((a, b) => a.localeCompare(b, "ko")),
    [rows]
  );
  const normalizedSearch = search.trim().toLowerCase();
  const filteredRows = rows.filter((row) => {
    const departmentMatches = department === "all" || row.department_name === department;
    const searchMatches = !normalizedSearch || row.employee_name.toLowerCase().includes(normalizedSearch);
    return departmentMatches && searchMatches;
  });

  return (
    <>
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

      <DataPanel title="직원정보">
        <table className="data-table">
          <thead>
            <tr>
              <th>직원번호</th>
              <th>성명</th>
              <th>성별</th>
              <th>부서</th>
              <th>직종</th>
              <th>직책</th>
              <th>고용형태</th>
              <th>재직상태</th>
              <th>입사일</th>
              <th>퇴사일</th>
            </tr>
          </thead>
          <tbody>
            {filteredRows.map((row) => (
              <tr key={row.employee_code}>
                <td className="numeric">{row.employee_code}</td>
                <td>{row.employee_name}</td>
                <td>{row.gender ?? "-"}</td>
                <td>{row.department_name ?? "-"}</td>
                <td>{row.job_category_name ?? "-"}</td>
                <td>{row.position_name ?? "-"}</td>
                <td>{row.employment_type_name ?? "-"}</td>
                <td>{row.status_name ?? "-"}</td>
                <td className="numeric">{row.hire_date ?? "-"}</td>
                <td className="numeric">{row.retirement_date ?? "-"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </DataPanel>
    </>
  );
}
