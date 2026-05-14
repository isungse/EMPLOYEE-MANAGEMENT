import { formatNumber } from "@/lib/format";

export function KpiCard({
  label,
  value,
  suffix,
  tone = "neutral"
}: {
  label: string;
  value: number | string | null | undefined;
  suffix?: string;
  tone?: "neutral" | "positive" | "negative";
}) {
  const color = tone === "positive" ? "text-[#33732E]" : tone === "negative" ? "text-[#BF3030]" : "text-gray-900";

  return (
    <div className="panel p-5">
      <div className="text-[10px] font-semibold text-gray-500">{label}</div>
      <div className={`numeric mt-3 text-[20px] font-bold leading-tight ${color}`}>
        {typeof value === "number" ? formatNumber(value) : value ?? "-"}
        {suffix ? <span className="ml-1 text-xs font-semibold text-gray-500">{suffix}</span> : null}
      </div>
    </div>
  );
}
