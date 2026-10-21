import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';

export async function adminFetch(endpoint: string, init: RequestInit = {}) {
  const apiUrl = process.env.API_URL || 'http://localhost:4000';
  let token: string | undefined;

  try {
    const cookieStore = await cookies();
    token = cookieStore.get('admin_token')?.value;
  } catch (_) {
    // If called outside request context (e.g. build time static analysis)
  }

  const headers = new Headers(init.headers || {});

  if (process.env.INTERNAL_API_KEY) {
    headers.set('x-api-key', process.env.INTERNAL_API_KEY);
  }

  if (token) {
    headers.set('Authorization', `Bearer ${token}`);
  }

  if (!headers.has('Content-Type') && !(init.body instanceof FormData)) {
    headers.set('Content-Type', 'application/json');
  }

  const url = endpoint.startsWith('http')
    ? endpoint
    : `${apiUrl}${endpoint.startsWith('/') ? '' : '/'}${endpoint}`;

  // 4s timeout to avoid build hangs if backend is offline
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 4000);

  try {
    const res = await fetch(url, {
      ...init,
      headers,
      signal: init.signal || controller.signal,
    });

    if (res.status === 401) {
      try {
        const cookieStore = await cookies();
        cookieStore.delete('admin_token');
      } catch (_) {}
      redirect('/login');
    }

    return res;
  } finally {
    clearTimeout(timeoutId);
  }
}
