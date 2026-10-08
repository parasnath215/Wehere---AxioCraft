export default async function AdminDashboard() {
  let stats = { totalUsers: 0, activeMatches: 0, totalMessages: 0, reportedUsers: 0, recentUsers: [] };
  
  try {
    const apiUrl = process.env.API_URL || 'http://backend:4000';
    if (!apiUrl) throw new Error("API_URL is not defined");
    const res = await fetch(`${apiUrl}/api/admin/stats`, {
      cache: 'no-store',
      headers: {
        'x-api-key': process.env.INTERNAL_API_KEY || ''
      }
    });
    if (res.ok) {
      stats = await res.json();
    } else {
      console.error("API ERROR fetch admin stats:", res.status, res.statusText);
    }
  } catch (err) {
    console.error("Failed to fetch admin stats", err);
  }

  const { totalUsers, activeMatches, totalMessages, reportedUsers, recentUsers } = stats;

  return (
    <main className="flex-1 overflow-y-auto relative z-10 scrollbar-hide">
      <header className="px-10 py-8 flex justify-between items-center border-b border-white/5 bg-[#151822]/50 backdrop-blur-xl sticky top-0 z-20">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight text-white">Overview Dashboard</h2>
          <p className="text-gray-400 text-sm mt-1">Monitor your community and platform metrics</p>
        </div>
        <button className="bg-white text-gray-900 px-6 py-2.5 rounded-xl text-sm font-semibold shadow-lg shadow-white/10 hover:shadow-white/20 hover:scale-105 transition-all">
          Export Report
        </button>
      </header>

      <div className="p-10 max-w-7xl mx-auto">
        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-10">
          <div className="bg-white/5 backdrop-blur-xl p-6 rounded-3xl border border-white/10 relative overflow-hidden group hover:border-indigo-500/30 transition-colors">
            <div className="absolute top-0 right-0 w-32 h-32 bg-indigo-500/10 blur-2xl rounded-full -translate-y-1/2 translate-x-1/2 group-hover:bg-indigo-500/20 transition-colors"></div>
            <h3 className="text-gray-400 text-sm font-medium">Total Users</h3>
            <p className="text-4xl font-bold text-white mt-3 tracking-tight">{totalUsers}</p>
            <div className="mt-4 flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-emerald-400 shadow-[0_0_8px_rgba(52,211,153,0.8)]"></span>
              <span className="text-gray-400 text-xs font-medium uppercase tracking-wider">Active platform</span>
            </div>
          </div>
          
          <div className="bg-white/5 backdrop-blur-xl p-6 rounded-3xl border border-white/10 relative overflow-hidden group hover:border-purple-500/30 transition-colors">
            <div className="absolute top-0 right-0 w-32 h-32 bg-purple-500/10 blur-2xl rounded-full -translate-y-1/2 translate-x-1/2 group-hover:bg-purple-500/20 transition-colors"></div>
            <h3 className="text-gray-400 text-sm font-medium">Active Matches</h3>
            <p className="text-4xl font-bold text-white mt-3 tracking-tight">{activeMatches}</p>
            <div className="mt-4 flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-purple-400 shadow-[0_0_8px_rgba(192,132,252,0.8)]"></span>
              <span className="text-gray-400 text-xs font-medium uppercase tracking-wider">Peer connections</span>
            </div>
          </div>
          
          <div className="bg-white/5 backdrop-blur-xl p-6 rounded-3xl border border-white/10 relative overflow-hidden group hover:border-blue-500/30 transition-colors">
            <div className="absolute top-0 right-0 w-32 h-32 bg-blue-500/10 blur-2xl rounded-full -translate-y-1/2 translate-x-1/2 group-hover:bg-blue-500/20 transition-colors"></div>
            <h3 className="text-gray-400 text-sm font-medium">Messages Sent</h3>
            <p className="text-4xl font-bold text-white mt-3 tracking-tight">{totalMessages}</p>
            <div className="mt-4 flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-blue-400 shadow-[0_0_8px_rgba(96,165,250,0.8)]"></span>
              <span className="text-gray-400 text-xs font-medium uppercase tracking-wider">Total volume</span>
            </div>
          </div>
          
          <div className="bg-white/5 backdrop-blur-xl p-6 rounded-3xl border border-white/10 relative overflow-hidden group hover:border-rose-500/30 transition-colors">
            <div className="absolute top-0 right-0 w-32 h-32 bg-rose-500/10 blur-2xl rounded-full -translate-y-1/2 translate-x-1/2 group-hover:bg-rose-500/20 transition-colors"></div>
            <h3 className="text-gray-400 text-sm font-medium">Reported Users</h3>
            <p className="text-4xl font-bold text-white mt-3 tracking-tight">{reportedUsers}</p>
            <div className="mt-4 flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-rose-400 shadow-[0_0_8px_rgba(251,113,133,0.8)]"></span>
              <span className="text-gray-400 text-xs font-medium uppercase tracking-wider">Needs review</span>
            </div>
          </div>
        </div>

        {/* Recent Activity Table */}
        <div className="bg-white/5 backdrop-blur-xl rounded-3xl border border-white/10 overflow-hidden shadow-2xl shadow-black/20">
          <div className="px-8 py-6 border-b border-white/5 bg-white/5">
            <h3 className="text-lg font-semibold text-white tracking-tight">Recent Signups</h3>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse min-w-max">
              <thead>
                <tr className="bg-white/5 text-gray-400 text-xs uppercase tracking-wider border-b border-white/5">
                  <th className="px-8 py-4 font-medium">User ID</th>
                  <th className="px-8 py-4 font-medium">Pseudonym</th>
                  <th className="px-8 py-4 font-medium">Role</th>
                  <th className="px-8 py-4 font-medium">Joined</th>
                  <th className="px-8 py-4 font-medium">Status</th>
                </tr>
              </thead>
              <tbody className="text-sm text-gray-300">
                {recentUsers.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="px-8 py-12 text-center text-gray-500">
                      <div className="flex flex-col items-center justify-center">
                        <div className="w-16 h-16 rounded-full bg-white/5 flex items-center justify-center mb-4">
                          <span className="text-2xl opacity-50">👤</span>
                        </div>
                        <p>No recent users found.</p>
                      </div>
                    </td>
                  </tr>
                ) : (
                  recentUsers.map((user: any) => (
                    <tr key={user.id} className="hover:bg-white/5 border-b border-white/5 transition-colors group">
                      <td className="px-8 py-5 font-mono text-xs text-gray-500 group-hover:text-gray-400">{user.id.substring(0, 12)}...</td>
                      <td className="px-8 py-5 font-medium text-white">{user.pseudonym || 'Anonymous'}</td>
                      <td className="px-8 py-5">
                        <span className={user.role === 'ADMIN' ? "bg-indigo-500/20 text-indigo-300 border border-indigo-500/20 px-3 py-1 rounded-full text-xs font-semibold" : "bg-white/10 text-gray-300 border border-white/10 px-3 py-1 rounded-full text-xs font-semibold"}>
                          {user.role}
                        </span>
                      </td>
                      <td className="px-8 py-5 text-gray-400">{new Date(user.createdAt).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })}</td>
                      <td className="px-8 py-5">
                        <div className="flex items-center gap-2">
                          <div className="w-2 h-2 rounded-full bg-emerald-400"></div>
                          <span className="text-emerald-400 font-medium">Active</span>
                        </div>
                      </td>
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
