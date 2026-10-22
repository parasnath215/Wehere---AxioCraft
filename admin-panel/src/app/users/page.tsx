import UsersClient from './UsersClient';
import { adminFetch } from '@/lib/api';

export default async function UsersPage() {
  let users = [];
  try {
    const res = await adminFetch('/api/admin/users', {
      cache: 'no-store',
    });
    if (res.ok) {
      const data = await res.json();
      users = Array.isArray(data) ? data : (data.users || []);
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
