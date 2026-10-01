export default async function MatchesPage() {
  let matches = [];
  try {
    const apiUrl = process.env.NEXT_PUBLIC_API_URL;
    if (!apiUrl) throw new Error("NEXT_PUBLIC_API_URL is not defined");
    const res = await fetch(`${apiUrl}/api/admin/matches`, {
      cache: 'no-store',
      headers: {
        'x-api-key': process.env.INTERNAL_API_KEY || ''
      }
    });
    if (res.ok) {
      matches = await res.json();
    }
  } catch (err) {
    console.error("Failed to fetch admin matches", err);
  }

  return (
    <main className="flex-1 overflow-y-auto">
      <header className="bg-white shadow-sm px-8 py-4">
        <h2 className="text-xl font-semibold text-gray-800">Matches & Connections</h2>
      </header>
      <div className="p-8">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50 text-gray-600 text-sm">
                <th className="px-6 py-3 border-b border-gray-200">Match ID</th>
                <th className="px-6 py-3 border-b border-gray-200">User A</th>
                <th className="px-6 py-3 border-b border-gray-200">User B</th>
                <th className="px-6 py-3 border-b border-gray-200">Status</th>
                <th className="px-6 py-3 border-b border-gray-200">Score</th>
                <th className="px-6 py-3 border-b border-gray-200">Created At</th>
              </tr>
            </thead>
            <tbody className="text-sm text-gray-700">
              {matches.map((match: any) => (
                <tr key={match.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 border-b border-gray-100 font-mono text-xs">{match.id.substring(0, 8)}...</td>
                  <td className="px-6 py-4 border-b border-gray-100">{match.userA?.pseudonym || 'Unknown'}</td>
                  <td className="px-6 py-4 border-b border-gray-100">{match.userB?.pseudonym || 'Unknown'}</td>
                  <td className="px-6 py-4 border-b border-gray-100">
                    <span className="bg-green-100 text-green-700 px-2 py-1 rounded text-xs font-semibold">{match.status}</span>
                  </td>
                  <td className="px-6 py-4 border-b border-gray-100">{match.matchScore}%</td>
                  <td className="px-6 py-4 border-b border-gray-100">{new Date(match.createdAt).toLocaleDateString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </main>
  );
}
