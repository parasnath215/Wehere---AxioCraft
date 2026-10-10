import { NextResponse } from 'next/server';

export async function DELETE(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const apiUrl = process.env.API_URL || 'http://backend:4000';
    const apiKey = process.env.INTERNAL_API_KEY || '';

    const res = await fetch(`${apiUrl}/api/admin/users/${id}`, {
      method: 'DELETE',
      headers: {
        'x-api-key': apiKey,
      },
    });

    const data = await res.json();
    return NextResponse.json(data, { status: res.status });
  } catch (error) {
    return NextResponse.json({ error: 'Failed to delete user' }, { status: 500 });
  }
}

export async function PUT(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const body = await req.json();
    const apiUrl = process.env.API_URL || 'http://backend:4000';
    const apiKey = process.env.INTERNAL_API_KEY || '';

    const res = await fetch(`${apiUrl}/api/admin/users/${id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
      },
      body: JSON.stringify(body),
    });

    const data = await res.json();
    return NextResponse.json(data, { status: res.status });
  } catch (error) {
    return NextResponse.json({ error: 'Failed to update user' }, { status: 500 });
  }
}
