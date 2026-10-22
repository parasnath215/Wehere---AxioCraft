'use server';

import { cookies, headers } from 'next/headers';
import { redirect } from 'next/navigation';

export interface LoginState {
  error?: string;
  success?: boolean;
}

export async function loginAction(prevState: LoginState | null, formData: FormData): Promise<LoginState> {
  const email = formData.get('email');
  const password = formData.get('password');

  if (!email || !password || typeof email !== 'string' || typeof password !== 'string') {
    return { error: 'Email and password are required.' };
  }

  const apiUrl = process.env.API_URL || 'http://localhost:4000';

  try {
    const res = await fetch(`${apiUrl}/api/admin/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(process.env.INTERNAL_API_KEY ? { 'x-api-key': process.env.INTERNAL_API_KEY } : {}),
      },
      body: JSON.stringify({ email: email.trim(), password }),
    });

    const data = await res.json();

    if (!res.ok || !data.token) {
      return { error: data.message || 'Invalid credentials or access denied.' };
    }

    const headerList = await headers();
    const proto = headerList.get('x-forwarded-proto') || '';
    const referer = headerList.get('referer') || '';
    const isHttps = proto === 'https' || referer.startsWith('https://');

    const cookieStore = await cookies();
    cookieStore.set('admin_token', data.token, {
      httpOnly: true,
      secure: isHttps,
      sameSite: 'lax',
      maxAge: 12 * 60 * 60, // 12 hours
      path: '/',
    });
  } catch (err: any) {
    return { error: 'Failed to connect to authentication server.' };
  }

  redirect('/');
}

export async function logoutAction() {
  const cookieStore = await cookies();
  cookieStore.delete('admin_token');
  redirect('/login');
}
