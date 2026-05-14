export function formatMonth(value: string | null | undefined) {
  if (!value) return "-";
  return value.slice(0, 7);
}

export function formatNumber(value: number | string | null | undefined) {
  const number = Number(value ?? 0);
  return new Intl.NumberFormat("ko-KR").format(number);
}

export function formatCurrency(value: number | string | null | undefined) {
  return `${formatNumber(value)}원`;
}

export function formatRatio(value: number | string | null | undefined) {
  if (value === null || value === undefined) return "-";
  return `${Number(value).toFixed(2)}%`;
}
