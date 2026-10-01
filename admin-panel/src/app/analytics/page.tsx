export default function AnalyticsPage() {
  return (
    <main className="flex-1 overflow-y-auto">
      <header className="bg-white shadow-sm px-8 py-4">
        <h2 className="text-xl font-semibold text-gray-800">Analytics & Reports</h2>
      </header>
      <div className="p-8">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 text-center text-gray-500">
          <h3 className="text-lg font-medium text-gray-800 mb-2">Platform Analytics</h3>
          <p>Graphs and DAU/MAU charts will appear here.</p>
        </div>
      </div>
    </main>
  );
}
