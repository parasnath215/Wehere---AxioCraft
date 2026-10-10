import UsersClient from './UsersClient';

export default async function UsersPage() {
  let users = [];
  try {
    const apiUrl = process.env.API_URL || 'http://backend:4000';
    if (!apiUrl) throw new Error("API_URL is not defined");
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
    <main className="flex-1 overflow-y-auto relative z-10 scrollbar-hide">
      <UsersClient initialUsers={users} />
    </main>
  );
}
