export default async function AdminDashboard() {
  let stats = { totalUsers: 0, activeMatches: 0, totalMessages: 0, reportedUsers: 0, recentUsers: [] };
  
  try {
    const apiUrl = process.env.NEXT_PUBLIC_API_URL;
    if (!apiUrl) throw new Error("NEXT_PUBLIC_API_URL is not defined");
    const res = await fetch(`${apiUrl}/api/admin/stats`, {
      cache: 'no-store',
      headers: {
        'x-api-key': process.env.INTERNAL_API_KEY || ''
      }
    });
    if (res.ok) {
      stats = await res.json();
    }
  } catch (err) {
    console.error("Failed to fetch admin stats", err);
  }

  const { totalUsers, activeMatches, totalMessages, reportedUsers, recentUsers } = stats;

  return (
    <main className="flex-1 overflow-y-auto">
      <header className="bg-white shadow-sm px-8 py-4 flex justify-between items-center">
        <h2 className="text-xl font-semibold text-gray-800">Overview Dashboard</h2>
        <button className="bg-indigo-600 text-white px-4 py-2 rounded shadow hover:bg-indigo-700 transition">
          Export Report
        </button>
      </header>

      <div className="p-8">
        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <h3 className="text-gray-500 text-sm font-medium">Total Users</h3>
            <p className="text-3xl font-bold text-gray-800 mt-2">{totalUsers}</p>
            <span className="text-green-500 text-sm font-semibold">Active platform</span>
          </div>
          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <h3 className="text-gray-500 text-sm font-medium">Active Matches</h3>
            <p className="text-3xl font-bold text-gray-800 mt-2">{activeMatches}</p>
            <span className="text-green-500 text-sm font-semibold">Peer connections</span>
          </div>
          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <h3 className="text-gray-500 text-sm font-medium">Messages Sent</h3>
            <p className="text-3xl font-bold text-gray-800 mt-2">{totalMessages}</p>
            <span className="text-green-500 text-sm font-semibold">Total volume</span>
          </div>
          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <h3 className="text-gray-500 text-sm font-medium">Reported Users</h3>
            <p className="text-3xl font-bold text-gray-800 mt-2">{reportedUsers}</p>
            <span className="text-gray-500 text-sm font-semibold">Needs review</span>
          </div>
        </div>

        {/* Recent Activity Table */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-800">Recent Users</h3>
          </div>
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50 text-gray-600 text-sm">
                <th className="px-6 py-3 border-b border-gray-200">User ID</th>
                <th className="px-6 py-3 border-b border-gray-200">Pseudonym</th>
                <th className="px-6 py-3 border-b border-gray-200">Role</th>
                <th className="px-6 py-3 border-b border-gray-200">Joined</th>
                <th className="px-6 py-3 border-b border-gray-200">Status</th>
              </tr>
            </thead>
            <tbody className="text-sm text-gray-700">
              {recentUsers.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-4 text-center text-gray-500">No recent users found.</td>
                </tr>
              ) : (
                recentUsers.map((user: any) => (
                  <tr key={user.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 border-b border-gray-100 font-mono text-xs">{user.id.substring(0, 8)}...</td>
                    <td className="px-6 py-4 border-b border-gray-100">{user.pseudonym || 'Anonymous'}</td>
                    <td className="px-6 py-4 border-b border-gray-100">
                      <span className={user.role === 'ADMIN' ? "bg-indigo-100 text-indigo-700 px-2 py-1 rounded text-xs font-semibold" : "bg-gray-100 text-gray-600 px-2 py-1 rounded text-xs font-semibold"}>
                        {user.role}
                      </span>
                    </td>
                    <td className="px-6 py-4 border-b border-gray-100">{new Date(user.createdAt).toLocaleDateString()}</td>
                    <td className="px-6 py-4 border-b border-gray-100"><span className="text-green-600 font-semibold">Active</span></td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </main>
  );
}
