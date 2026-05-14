import type { Metadata } from "next";
import Link from "next/link";
import { BarChart3, Database, FileClock, FileUp, UsersRound, WalletCards } from "lucide-react";
import "./globals.css";

export const metadata: Metadata = {
  title: "인사관리 통계",
  description: "DB 기반 인사관리 통계 웹 프로그램"
};

const navItems = [
  { href: "/", label: "대시보드", icon: BarChart3 },
  { href: "/employees", label: "직원정보", icon: UsersRound },
  { href: "/rosters", label: "월별명단", icon: Database },
  { href: "/payroll", label: "급여명단", icon: WalletCards },
  { href: "/imports", label: "업로드 이력", icon: FileClock },
  { href: "/upload", label: "업로드", icon: FileUp }
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
                      className="flex h-9 items-center gap-2 rounded-md border border-transparent px-3 text-sm font-medium text-gray-600 transition-colors hover:border-border hover:bg-gray-50 hover:text-gray-900"
                    >
                      <Icon size={16} />
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
