import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import Link from 'next/link';

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Wehere Admin",
  description: "Admin dashboard",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}>
      <body className="flex h-screen bg-[#0f111a] text-gray-100 overflow-hidden font-sans">
        {/* Persistent Sidebar */}
        <aside className="w-64 bg-[#151822] border-r border-white/10 flex flex-col shrink-0 relative overflow-hidden">
          {/* Subtle gradient glow in sidebar */}
          <div className="absolute top-0 left-0 w-full h-32 bg-indigo-500/10 blur-3xl rounded-full -translate-y-1/2"></div>
          
          <div className="p-8 relative z-10">
            <h1 className="text-2xl font-bold bg-gradient-to-r from-indigo-400 to-purple-400 bg-clip-text text-transparent tracking-tight">Wehere Admin</h1>
          </div>
          
          <nav className="flex-1 px-4 space-y-2 relative z-10 mt-4">
            <Link href="/" className="block px-5 py-3 rounded-xl bg-indigo-500/10 text-indigo-300 font-medium border border-indigo-500/20 transition-all hover:bg-indigo-500/20">Dashboard</Link>
            <Link href="/users" className="block px-5 py-3 rounded-xl text-gray-400 hover:text-gray-100 hover:bg-white/5 font-medium transition-all">Users</Link>
            <Link href="/matches" className="block px-5 py-3 rounded-xl text-gray-400 hover:text-gray-100 hover:bg-white/5 font-medium transition-all">Matches</Link>
            <Link href="/analytics" className="block px-5 py-3 rounded-xl text-gray-400 hover:text-gray-100 hover:bg-white/5 font-medium transition-all">Analytics</Link>
            <Link href="/settings" className="block px-5 py-3 rounded-xl text-gray-400 hover:text-gray-100 hover:bg-white/5 font-medium transition-all">Settings</Link>
          </nav>
          
          <div className="p-6 border-t border-white/10 relative z-10 flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-indigo-500 to-purple-500 flex items-center justify-center shadow-lg shadow-indigo-500/20">
              <span className="font-bold text-white">SA</span>
            </div>
            <div>
              <p className="text-sm font-semibold text-gray-200">Super Admin</p>
              <p className="text-xs text-gray-500">System Owner</p>
            </div>
          </div>
        </aside>

        {/* Dynamic Page Content */}
        <div className="flex-1 flex flex-col overflow-hidden relative">
          {/* Main Background Gradients */}
          <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-purple-500/10 blur-[120px] rounded-full pointer-events-none -translate-y-1/2 translate-x-1/3"></div>
          <div className="absolute bottom-0 left-0 w-[500px] h-[500px] bg-indigo-500/10 blur-[120px] rounded-full pointer-events-none translate-y-1/3 -translate-x-1/3"></div>
          
          {children}
        </div>
      </body>
    </html>
  );
}
