export default async function MatchesPage() {
  let matches = [];
  try {
    const apiUrl = process.env.API_URL || 'http://backend:4000';
    if (!apiUrl) throw new Error("API_URL is not defined");
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
    <main className="flex-1 overflow-y-auto relative z-10 scrollbar-hide">
      <header className="px-10 py-8 border-b border-white/5 bg-[#151822]/50 backdrop-blur-xl sticky top-0 z-20">
        <h2 className="text-2xl font-semibold tracking-tight text-white">Matches & Connections</h2>
        <p className="text-gray-400 text-sm mt-1">Review user connection metrics and match history</p>
      </header>
      
      <div className="p-10 max-w-7xl mx-auto">
        <div className="bg-white/5 backdrop-blur-xl rounded-3xl border border-white/10 overflow-hidden shadow-2xl shadow-black/20">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse min-w-max">
              <thead>
                <tr className="bg-white/5 text-gray-400 text-xs uppercase tracking-wider border-b border-white/5">
                  <th className="px-8 py-4 font-medium">Match ID</th>
                  <th className="px-8 py-4 font-medium">User A</th>
                  <th className="px-8 py-4 font-medium">User B</th>
                  <th className="px-8 py-4 font-medium">Status</th>
                  <th className="px-8 py-4 font-medium">Score</th>
                  <th className="px-8 py-4 font-medium text-right">Created At</th>
                </tr>
              </thead>
              <tbody className="text-sm text-gray-300">
                {matches.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-8 py-12 text-center text-gray-500">
                      <div className="flex flex-col items-center justify-center">
                        <div className="w-16 h-16 rounded-full bg-white/5 flex items-center justify-center mb-4">
                          <span className="text-2xl opacity-50">🔗</span>
                        </div>
                        <p>No active matches found.</p>
                      </div>
                    </td>
                  </tr>
                ) : (
                  matches.map((match: any) => (
                    <tr key={match.id} className="hover:bg-white/5 border-b border-white/5 transition-colors group">
                      <td className="px-8 py-5 font-mono text-xs text-gray-500 group-hover:text-gray-400">{match.id.substring(0, 12)}...</td>
                      <td className="px-8 py-5 font-medium text-white">{match.userA?.pseudonym || 'Unknown'}</td>
                      <td className="px-8 py-5 font-medium text-white">{match.userB?.pseudonym || 'Unknown'}</td>
                      <td className="px-8 py-5">
                        <span className="bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 px-3 py-1 rounded-full text-xs font-semibold">
                          {match.status}
                        </span>
                      </td>
                      <td className="px-8 py-5 text-gray-400">{match.matchScore}%</td>
                      <td className="px-8 py-5 text-gray-400 text-right">{new Date(match.createdAt).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </main>
  );
}
