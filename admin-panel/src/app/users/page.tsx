export default async function UsersPage() {
  let users = [];
  try {
    const apiUrl = process.env.API_URL || 'http://backend:4000';
    if (!apiUrl) throw new Error("API_URL is not defined");
    const res = await fetch(`${apiUrl}/api/admin/users`, {
      cache: 'no-store',
      headers: {
        'x-api-key': process.env.INTERNAL_API_KEY || ''
      }
    });
    if (res.ok) {
      users = await res.json();
    }
  } catch (err) {
    console.error("Failed to fetch admin users", err);
  }

  return (
    <main className="flex-1 overflow-y-auto relative z-10 scrollbar-hide">
      <header className="px-10 py-8 flex justify-between items-center border-b border-white/5 bg-[#151822]/50 backdrop-blur-xl sticky top-0 z-20">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight text-white">User Management</h2>
          <p className="text-gray-400 text-sm mt-1">Manage and monitor platform users</p>
        </div>
        <button className="bg-indigo-600 text-white px-6 py-2.5 rounded-xl text-sm font-semibold shadow-lg shadow-indigo-600/20 hover:bg-indigo-500 hover:shadow-indigo-500/40 hover:scale-105 transition-all">
          Add User
        </button>
      </header>
      
      <div className="p-10 max-w-7xl mx-auto">
        <div className="bg-white/5 backdrop-blur-xl rounded-3xl border border-white/10 overflow-hidden shadow-2xl shadow-black/20">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse min-w-max">
              <thead>
                <tr className="bg-white/5 text-gray-400 text-xs uppercase tracking-wider border-b border-white/5">
                  <th className="px-8 py-4 font-medium">User ID</th>
                  <th className="px-8 py-4 font-medium">Email</th>
                  <th className="px-8 py-4 font-medium">Pseudonym</th>
                  <th className="px-8 py-4 font-medium">Role</th>
                  <th className="px-8 py-4 font-medium">Joined</th>
                  <th className="px-8 py-4 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="text-sm text-gray-300">
                {users.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-8 py-12 text-center text-gray-500">
                      <div className="flex flex-col items-center justify-center">
                        <div className="w-16 h-16 rounded-full bg-white/5 flex items-center justify-center mb-4">
                          <span className="text-2xl opacity-50">👥</span>
                        </div>
                        <p>No users found in the system.</p>
                      </div>
                    </td>
                  </tr>
                ) : (
                  users.map((user: any) => (
                    <tr key={user.id} className="hover:bg-white/5 border-b border-white/5 transition-colors group">
                      <td className="px-8 py-5 font-mono text-xs text-gray-500 group-hover:text-gray-400">{user.id.substring(0, 12)}...</td>
                      <td className="px-8 py-5 text-gray-400">{user.email || 'N/A'}</td>
                      <td className="px-8 py-5 font-medium text-white">{user.pseudonym || 'Anonymous'}</td>
                      <td className="px-8 py-5">
                        <span className={user.role === 'ADMIN' ? "bg-indigo-500/20 text-indigo-300 border border-indigo-500/20 px-3 py-1 rounded-full text-xs font-semibold" : "bg-white/10 text-gray-300 border border-white/10 px-3 py-1 rounded-full text-xs font-semibold"}>
                          {user.role}
                        </span>
                      </td>
                      <td className="px-8 py-5 text-gray-400">{new Date(user.createdAt).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })}</td>
                      <td className="px-8 py-5 text-right">
                        <button className="text-indigo-400 hover:text-indigo-300 font-medium px-4 py-2 rounded-lg hover:bg-indigo-500/10 transition-colors">Edit</button>
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
