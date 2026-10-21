import { NextResponse } from 'next/server';
import { adminFetch } from '@/lib/api';

export async function POST(req: Request) {
  try {
    const body = await req.json();

    const res = await adminFetch('/api/admin/users', {
      method: 'POST',
      body: JSON.stringify(body),
    });

    const data = await res.json();
    return NextResponse.json(data, { status: res.status });
  } catch (error) {
    return NextResponse.json({ error: 'Failed to add user' }, { status: 500 });
  }
}
