export default function SettingsPage() {
  return (
    <main className="flex-1 overflow-y-auto relative z-10 scrollbar-hide">
      <header className="px-10 py-8 border-b border-white/5 bg-[#151822]/50 backdrop-blur-xl sticky top-0 z-20">
        <h2 className="text-2xl font-semibold tracking-tight text-white">Admin Settings</h2>
        <p className="text-gray-400 text-sm mt-1">Configure global application variables and roles</p>
      </header>
      
      <div className="p-10 max-w-7xl mx-auto">
        <div className="bg-white/5 backdrop-blur-xl rounded-3xl border border-white/10 p-16 text-center shadow-2xl shadow-black/20">
          <div className="w-20 h-20 rounded-full bg-blue-500/10 flex items-center justify-center mx-auto mb-6 border border-blue-500/20">
            <span className="text-4xl">⚙️</span>
          </div>
          <h3 className="text-2xl font-semibold text-white mb-3">Platform Configuration</h3>
          <p className="text-gray-400 max-w-md mx-auto">Global app settings and role management interfaces will appear here in the next update.</p>
        </div>
      </div>
    </main>
  );
}
