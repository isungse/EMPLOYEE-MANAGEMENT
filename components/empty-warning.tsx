export function EmptyWarning({ message }: { message: string | null }) {
  if (!message) return null;
  return (
    <div className="mb-4 border-l-4 border-amber-500 bg-white px-4 py-3 text-sm font-semibold text-amber-800">
      {message}
    </div>
  );
}
