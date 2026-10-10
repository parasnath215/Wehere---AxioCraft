import Link from 'next/link';

export default async function UserAnalyticsPage({ params }: { params: { id: string } }) {
  let data: any = null;
  try {
    const apiUrl = process.env.API_URL || 'http://backend:4000';
    if (!apiUrl) throw new Error("API_URL is not defined");
    
    // We can't use route handler cache because we need the latest stats for user
    const res = await fetch(`${apiUrl}/api/admin/users/${params.id}/analytics`, {
      cache: 'no-store',
      headers: {
        'x-api-key': process.env.INTERNAL_API_KEY || ''
      }
    });
    if (res.ok) {
      data = await res.json();
    }
  } catch (err) {
    console.error("Failed to fetch user analytics", err);
  }

  if (!data || !data.user) {
    return (
      <main className="flex-1 overflow-y-auto relative z-10 p-10 flex flex-col items-center justify-center min-h-screen">
        <h2 className="text-2xl font-bold text-white mb-4">User Not Found</h2>
        <Link href="/users" className="text-indigo-400 hover:text-indigo-300">← Back to Users</Link>
      </main>
    );
  }

  const { user, stats } = data;

  return (
    <main className="flex-1 overflow-y-auto relative z-10 scrollbar-hide pb-20">
      <header className="px-10 py-8 flex gap-4 items-center border-b border-white/5 bg-[#151822]/50 backdrop-blur-xl sticky top-0 z-20">
        <Link href="/users" className="w-10 h-10 rounded-xl bg-white/5 flex items-center justify-center text-gray-400 hover:text-white hover:bg-white/10 transition-colors">
          ←
        </Link>
        <div>
          <h2 className="text-2xl font-semibold tracking-tight text-white flex items-center gap-3">
            {user.pseudonym} 
            {user.isBanned && <span className="text-xs bg-red-500/20 text-red-400 px-2 py-1 rounded-md">BANNED</span>}
            {user.role === 'ADMIN' && <span className="text-xs bg-indigo-500/20 text-indigo-400 px-2 py-1 rounded-md">ADMIN</span>}
          </h2>
          <p className="text-gray-400 text-sm mt-1">{user.email || 'No email provided'} • ID: {user.id}</p>
        </div>
      </header>

      <div className="p-10 max-w-7xl mx-auto space-y-8">
        
        {/* Top KPI Cards like Shopify */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="bg-white/5 backdrop-blur-xl rounded-3xl border border-white/10 p-6 shadow-2xl shadow-black/20 flex flex-col">
            <span className="text-sm font-medium text-gray-400 mb-2">Total Matches</span>
            <span className="text-4xl font-bold text-white">{stats.totalMatches}</span>
            <span className="text-xs text-indigo-400 mt-2">{stats.activeMatches} Currently Active</span>
          </div>
          <div className="bg-white/5 backdrop-blur-xl rounded-3xl border border-white/10 p-6 shadow-2xl shadow-black/20 flex flex-col">
            <span className="text-sm font-medium text-gray-400 mb-2">Messages Sent</span>
            <span className="text-4xl font-bold text-white">{stats.messagesSent}</span>
            <span className="text-xs text-emerald-400 mt-2">Engagement metric</span>
          </div>
          <div className="bg-white/5 backdrop-blur-xl rounded-3xl border border-white/10 p-6 shadow-2xl shadow-black/20 flex flex-col">
            <span className="text-sm font-medium text-gray-400 mb-2">Journals Written</span>
            <span className="text-4xl font-bold text-white">{stats.journalsWritten}</span>
            <span className="text-xs text-blue-400 mt-2">Community contributions</span>
          </div>
          <div className="bg-white/5 backdrop-blur-xl rounded-3xl border border-white/10 p-6 shadow-2xl shadow-black/20 flex flex-col justify-center">
            <div className="space-y-4">
              <div>
                <span className="text-xs font-medium text-gray-500 uppercase tracking-wider block mb-1">Joined Date</span>
                <span className="text-sm text-gray-300 font-medium">{new Date(user.createdAt).toLocaleDateString(undefined, { dateStyle: 'medium'})}</span>
              </div>
              <div>
                <span className="text-xs font-medium text-gray-500 uppercase tracking-wider block mb-1">Last Login</span>
                <span className="text-sm text-gray-300 font-medium">{user.lastLoginAt ? new Date(user.lastLoginAt).toLocaleDateString(undefined, { dateStyle: 'medium'}) : 'Never'}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Detailed Panels */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 bg-white/5 backdrop-blur-xl rounded-3xl border border-white/10 overflow-hidden shadow-2xl shadow-black/20">
            <div className="p-6 border-b border-white/5">
              <h3 className="text-lg font-medium text-white">Activity Timeline</h3>
            </div>
            <div className="p-8 flex flex-col items-center justify-center min-h-[300px] text-gray-500">
              <div className="w-16 h-16 rounded-full bg-white/5 flex items-center justify-center mb-4">
                <span className="text-2xl opacity-50">📈</span>
              </div>
              <p>Activity timeline visualization will appear here.</p>
              <p className="text-sm mt-1">Collecting usage data...</p>
            </div>
          </div>

          <div className="bg-white/5 backdrop-blur-xl rounded-3xl border border-white/10 overflow-hidden shadow-2xl shadow-black/20 h-fit">
            <div className="p-6 border-b border-white/5">
              <h3 className="text-lg font-medium text-white">Actions</h3>
            </div>
            <div className="p-6 space-y-4">
              <button className="w-full bg-white/5 hover:bg-white/10 text-white font-medium py-3 px-4 rounded-xl transition-colors text-left flex justify-between items-center group">
                Reset Password
                <span className="text-gray-500 group-hover:text-white transition-colors">→</span>
              </button>
              <button className="w-full bg-white/5 hover:bg-white/10 text-white font-medium py-3 px-4 rounded-xl transition-colors text-left flex justify-between items-center group">
                {user.isBanned ? 'Unban User' : 'Ban User'}
                <span className="text-gray-500 group-hover:text-white transition-colors">→</span>
              </button>
              <button className="w-full bg-red-500/10 hover:bg-red-500/20 text-red-400 font-medium py-3 px-4 rounded-xl transition-colors text-left flex justify-between items-center group mt-4">
                Delete Account
                <span className="text-red-900 group-hover:text-red-400 transition-colors">→</span>
              </button>
            </div>
          </div>
        </div>

      </div>
    </main>
  );
}
