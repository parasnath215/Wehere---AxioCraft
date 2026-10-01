export default async function UsersPage() {
  let users = [];
  try {
    const apiUrl = process.env.NEXT_PUBLIC_API_URL;
    if (!apiUrl) throw new Error("NEXT_PUBLIC_API_URL is not defined");
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
    <main className="flex-1 overflow-y-auto">
      <header className="bg-white shadow-sm px-8 py-4 flex justify-between items-center">
        <h2 className="text-xl font-semibold text-gray-800">User Management</h2>
        <button className="bg-indigo-600 text-white px-4 py-2 rounded shadow hover:bg-indigo-700 transition">Add User</button>
      </header>
      <div className="p-8">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50 text-gray-600 text-sm">
                <th className="px-6 py-3 border-b border-gray-200">ID</th>
                <th className="px-6 py-3 border-b border-gray-200">Email</th>
                <th className="px-6 py-3 border-b border-gray-200">Pseudonym</th>
                <th className="px-6 py-3 border-b border-gray-200">Role</th>
                <th className="px-6 py-3 border-b border-gray-200">Joined</th>
                <th className="px-6 py-3 border-b border-gray-200 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="text-sm text-gray-700">
              {users.map((user: any) => (
                <tr key={user.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 border-b border-gray-100 font-mono text-xs">{user.id.substring(0, 8)}...</td>
                  <td className="px-6 py-4 border-b border-gray-100">{user.email || 'N/A'}</td>
                  <td className="px-6 py-4 border-b border-gray-100">{user.pseudonym || 'Anonymous'}</td>
                  <td className="px-6 py-4 border-b border-gray-100">
                    <span className={user.role === 'ADMIN' ? "bg-indigo-100 text-indigo-700 px-2 py-1 rounded text-xs font-semibold" : "bg-gray-100 text-gray-600 px-2 py-1 rounded text-xs font-semibold"}>
                      {user.role}
                    </span>
                  </td>
                  <td className="px-6 py-4 border-b border-gray-100">{new Date(user.createdAt).toLocaleDateString()}</td>
                  <td className="px-6 py-4 border-b border-gray-100 text-right">
                    <button className="text-indigo-600 hover:text-indigo-900 font-medium">Edit</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </main>
  );
}
