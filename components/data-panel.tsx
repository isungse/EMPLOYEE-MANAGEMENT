export function DataPanel({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="panel overflow-hidden">
      <div className="border-b border-border px-5 py-4">
        <h2 className="text-base font-bold text-gray-900">{title}</h2>
      </div>
      <div className="overflow-x-auto">{children}</div>
    </section>
  );
}
