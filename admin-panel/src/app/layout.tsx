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
      <body className="flex h-screen bg-gray-100 overflow-hidden">
        {/* Persistent Sidebar */}
        <aside className="w-64 bg-indigo-900 text-white flex flex-col shrink-0">
          <div className="p-6">
            <h1 className="text-2xl font-bold">Wehere Admin</h1>
          </div>
          <nav className="flex-1 px-4 space-y-2">
            <Link href="/" className="block px-4 py-2 rounded text-indigo-300 hover:bg-indigo-800 hover:text-white">Dashboard</Link>
            <Link href="/users" className="block px-4 py-2 rounded text-indigo-300 hover:bg-indigo-800 hover:text-white">Users</Link>
            <Link href="/matches" className="block px-4 py-2 rounded text-indigo-300 hover:bg-indigo-800 hover:text-white">Matches</Link>
            <Link href="/analytics" className="block px-4 py-2 rounded text-indigo-300 hover:bg-indigo-800 hover:text-white">Analytics</Link>
            <Link href="/settings" className="block px-4 py-2 rounded text-indigo-300 hover:bg-indigo-800 hover:text-white">Settings</Link>
          </nav>
          <div className="p-4 border-t border-indigo-800">
            <p className="text-sm text-indigo-300">Logged in as <b>Super Admin</b></p>
          </div>
        </aside>

        {/* Dynamic Page Content */}
        <div className="flex-1 flex flex-col overflow-hidden">
          {children}
        </div>
      </body>
    </html>
  );
}
