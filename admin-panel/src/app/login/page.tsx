'use client';

import { useActionState } from 'react';
import { loginAction, LoginState } from './actions';

export default function LoginPage() {
  const [state, formAction, isPending] = useActionState<LoginState | null, FormData>(
    loginAction,
    null
  );

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#0f111a] px-4">
      {/* Background radial glow */}
      <div className="absolute w-[450px] h-[450px] bg-indigo-500/10 blur-[130px] rounded-full pointer-events-none"></div>
      
      <div className="w-full max-w-md bg-[#151822] border border-white/10 rounded-3xl p-8 shadow-2xl relative z-10">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-extrabold bg-gradient-to-r from-indigo-400 to-purple-400 bg-clip-text text-transparent">
            Wehere Admin
          </h1>
          <p className="text-gray-400 text-sm mt-2">Sign in with authorized administrator credentials</p>
        </div>

        {state?.error && (
          <div className="mb-6 p-4 rounded-xl bg-red-500/10 border border-red-500/30 text-red-300 text-sm text-center">
            {state.error}
          </div>
        )}

        <form action={formAction} className="space-y-5">
          <div>
            <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-2">
              Email Address
            </label>
            <input
              type="email"
              name="email"
              required
              autoComplete="email"
              placeholder="admin@wehere.app"
              className="w-full px-4 py-3 bg-[#0f111a] border border-white/10 rounded-xl text-gray-100 placeholder-gray-500 focus:outline-none focus:border-indigo-500 transition-colors"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-2">
              Password
            </label>
            <input
              type="password"
              name="password"
              required
              autoComplete="current-password"
              placeholder="••••••••••••"
              className="w-full px-4 py-3 bg-[#0f111a] border border-white/10 rounded-xl text-gray-100 placeholder-gray-500 focus:outline-none focus:border-indigo-500 transition-colors"
            />
          </div>

          <button
            type="submit"
            disabled={isPending}
            className="w-full mt-2 py-3.5 px-4 bg-gradient-to-r from-indigo-500 to-purple-500 hover:from-indigo-600 hover:to-purple-600 text-white font-semibold rounded-xl shadow-lg shadow-indigo-500/25 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isPending ? 'Authenticating...' : 'Sign In to Dashboard'}
          </button>
        </form>

        <p className="text-center text-xs text-gray-500 mt-8">
          Restricted access. Internal monitoring & audit logs enabled.
        </p>
      </div>
    </div>
  );
}
