import type { Metadata } from "next";
import Link from "next/link";
import { BarChart3, Database, FileClock, FileUp, UsersRound, WalletCards } from "lucide-react";
import "./globals.css";

export const metadata: Metadata = {
  title: "인사관리 통계",
  description: "DB 기반 인사관리 통계 웹 프로그램"
};

const navItems = [
  {
    href: "/",
    label: "대시보드",
    icon: BarChart3,
    badgeClass: "bg-blue-50 text-blue-700 ring-blue-200"
  },
  {
    href: "/employees",
    label: "직원정보",
    icon: UsersRound,
    badgeClass: "bg-emerald-50 text-emerald-700 ring-emerald-200"
  },
  {
    href: "/rosters",
    label: "월별명단",
    icon: Database,
    badgeClass: "bg-amber-50 text-amber-700 ring-amber-200"
  },
  {
    href: "/payroll",
    label: "급여명단",
    icon: WalletCards,
    badgeClass: "bg-rose-50 text-rose-700 ring-rose-200"
  },
  {
    href: "/imports",
    label: "업로드 이력",
    icon: FileClock,
    badgeClass: "bg-violet-50 text-violet-700 ring-violet-200"
  },
  {
    href: "/upload",
    label: "업로드",
    icon: FileUp,
    badgeClass: "bg-cyan-50 text-cyan-700 ring-cyan-200"
  }
];

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko">
      <body>
        <div className="min-h-screen">
          <header className="border-b border-border bg-white">
            <div className="mx-auto flex h-16 max-w-[1440px] items-center justify-between px-6">
              <div>
                <div className="text-lg font-semibold tracking-normal text-gray-900">인사관리 통계</div>
              </div>
              <nav className="flex items-center gap-1">
                {navItems.map((item) => {
                  const Icon = item.icon;
                  return (
                    <Link
                      key={item.href}
                      href={item.href}
                      className="flex h-10 items-center gap-2 rounded-md border border-transparent px-2.5 text-sm font-medium text-gray-600 transition-colors hover:border-border hover:bg-gray-50 hover:text-gray-900"
                    >
                      <span
                        className={`inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-md ring-1 ${item.badgeClass}`}
                        aria-hidden="true"
                      >
                        <Icon size={16} strokeWidth={2.2} />
                      </span>
                      {item.label}
                    </Link>
                  );
                })}
              </nav>
            </div>
          </header>
          <main className="mx-auto max-w-[1440px] px-6 py-6">{children}</main>
        </div>
      </body>
    </html>
  );
}
