'use client';

import { useState } from 'react';
import Link from 'next/link';

export default function UsersClient({ initialUsers }: { initialUsers: any[] }) {
  const [users, setUsers] = useState(initialUsers);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editingUser, setEditingUser] = useState<any>(null);
  const [newUser, setNewUser] = useState({ email: '', password: '', pseudonym: '', role: 'USER' });
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Scheduled Deletion Modal State
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [userToDelete, setUserToDelete] = useState<any>(null);
  const [scheduledDateInput, setScheduledDateInput] = useState<string>('');

  const openDeleteModal = (user: any) => {
    setUserToDelete(user);
    if (user.scheduledDeletionDate) {
      const dt = new Date(user.scheduledDeletionDate);
      const iso = new Date(dt.getTime() - dt.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
      setScheduledDateInput(iso);
    } else {
      // Default to 30 days from now
      const defaultDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
      const iso = new Date(defaultDate.getTime() - defaultDate.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
      setScheduledDateInput(iso);
    }
    setIsDeleteModalOpen(true);
  };

  const handleImmediateDelete = async (id: string) => {
    if (!confirm('Are you sure you want to permanently delete this user right now? This cannot be undone.')) return;
    setIsSubmitting(true);
    try {
      const res = await fetch(`/api/admin/users/${id}`, { method: 'DELETE' });
      if (res.ok) {
        setUsers(users.filter((u) => u.id !== id));
        setIsDeleteModalOpen(false);
        setUserToDelete(null);
      } else {
        alert('Failed to delete user');
      }
    } catch (err) {
      console.error(err);
      alert('Error deleting user');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleSaveScheduledDeletion = async (id: string, dateStr: string | null) => {
    setIsSubmitting(true);
    try {
      const res = await fetch(`/api/admin/users/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          scheduledDeletionDate: dateStr ? new Date(dateStr).toISOString() : null
        })
      });
      if (res.ok) {
        const updatedUser = await res.json();
        setUsers(users.map(u => u.id === updatedUser.id ? { ...u, ...updatedUser } : u));
        setIsDeleteModalOpen(false);
        setUserToDelete(null);
      } else {
        const err = await res.json();
        alert(err.error || 'Failed to update scheduled deletion date');
      }
    } catch (err) {
      console.error(err);
      alert('Error scheduling deletion');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleSetQuickPreset = (hours: number) => {
    const targetDate = new Date(Date.now() + hours * 60 * 60 * 1000);
    const iso = new Date(targetDate.getTime() - targetDate.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
    setScheduledDateInput(iso);
  };

  const handleAddUser = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      const res = await fetch('/api/admin/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newUser)
      });
      if (res.ok) {
        const addedUser = await res.json();
        setUsers([addedUser, ...users]);
        setIsAddModalOpen(false);
        setNewUser({ email: '', password: '', pseudonym: '', role: 'USER' });
      } else {
        const err = await res.json();
        alert(err.error || 'Failed to add user');
      }
    } catch (err) {
      console.error(err);
      alert('Error adding user');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleEditUser = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingUser) return;
    setIsSubmitting(true);
    try {
      const res = await fetch(`/api/admin/users/${editingUser.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: editingUser.email,
          pseudonym: editingUser.pseudonym,
          role: editingUser.role,
          scheduledDeletionDate: editingUser.scheduledDeletionDate || null
        })
      });
      if (res.ok) {
        const updatedUser = await res.json();
        setUsers(users.map(u => u.id === updatedUser.id ? { ...u, ...updatedUser } : u));
        setIsEditModalOpen(false);
        setEditingUser(null);
      } else {
        const err = await res.json();
        alert(err.error || 'Failed to update user');
      }
    } catch (err) {
      console.error(err);
      alert('Error updating user');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <>
      <header className="px-10 py-8 flex justify-between items-center border-b border-white/5 bg-[#151822]/50 backdrop-blur-xl sticky top-0 z-20">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight text-white">User Management</h2>
          <p className="text-gray-400 text-sm mt-1">Manage users, scheduled account deletions, and auto-cleanup jobs</p>
        </div>
        <button 
          onClick={() => setIsAddModalOpen(true)}
          className="bg-indigo-600 text-white px-6 py-2.5 rounded-xl text-sm font-semibold shadow-lg shadow-indigo-600/20 hover:bg-indigo-500 hover:shadow-indigo-500/40 hover:scale-105 transition-all">
          Add User
        </button>
      </header>

      <div className="p-10 max-w-7xl mx-auto">
        <div className="bg-white/5 backdrop-blur-xl rounded-3xl border border-white/10 overflow-hidden shadow-2xl shadow-black/20">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse min-w-max">
              <thead>
                <tr className="bg-white/5 text-gray-400 text-xs uppercase tracking-wider border-b border-white/5">
                  <th className="px-8 py-4 font-medium">User ID</th>
                  <th className="px-8 py-4 font-medium">Email</th>
                  <th className="px-8 py-4 font-medium">Pseudonym</th>
                  <th className="px-8 py-4 font-medium">Role</th>
                  <th className="px-8 py-4 font-medium">Status / Deletion</th>
                  <th className="px-8 py-4 font-medium">Joined</th>
                  <th className="px-8 py-4 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="text-sm text-gray-300">
                {users.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="px-8 py-12 text-center text-gray-500">
                      <div className="flex flex-col items-center justify-center">
                        <div className="w-16 h-16 rounded-full bg-white/5 flex items-center justify-center mb-4">
                          <span className="text-2xl opacity-50">👥</span>
                        </div>
                        <p>No users found in the system.</p>
                      </div>
                    </td>
                  </tr>
                ) : (
                  users.map((user: any) => {
                    const hasDeletion = user.scheduledDeletionDate != null;
                    const isExpired = hasDeletion && new Date(user.scheduledDeletionDate).getTime() <= Date.now();

                    return (
                      <tr key={user.id} className="hover:bg-white/5 border-b border-white/5 transition-colors group">
                        <td className="px-8 py-5 font-mono text-xs text-gray-500 group-hover:text-gray-400">{user.id.substring(0, 12)}...</td>
                        <td className="px-8 py-5 text-gray-400">{user.email || 'N/A'}</td>
                        <td className="px-8 py-5 font-medium text-white">{user.pseudonym || 'Anonymous'}</td>
                        <td className="px-8 py-5">
                          <span className={user.role === 'ADMIN' ? "bg-indigo-500/20 text-indigo-300 border border-indigo-500/20 px-3 py-1 rounded-full text-xs font-semibold" : "bg-white/10 text-gray-300 border border-white/10 px-3 py-1 rounded-full text-xs font-semibold"}>
                            {user.role}
                          </span>
                        </td>
                        <td className="px-8 py-5">
                          {hasDeletion ? (
                            <span 
                              title={`Scheduled for auto-deletion on ${new Date(user.scheduledDeletionDate).toLocaleString()}`}
                              className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold border ${
                                isExpired 
                                  ? 'bg-red-500/20 text-red-300 border-red-500/30' 
                                  : 'bg-amber-500/20 text-amber-300 border-amber-500/30'
                              }`}>
                              <span>⏳</span>
                              <span>
                                {isExpired ? 'Deleting soon' : `Deleting: ${new Date(user.scheduledDeletionDate).toLocaleDateString()}`}
                              </span>
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1.5 bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 px-3 py-1 rounded-full text-xs font-semibold">
                              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400"></span>
                              Active
                            </span>
                          )}
                        </td>
                        <td className="px-8 py-5 text-gray-400">{new Date(user.createdAt).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })}</td>
                        <td className="px-8 py-5 text-right space-x-2">
                          <Link href={`/users/${user.id}`} className="text-blue-400 hover:text-blue-300 font-medium px-3 py-1.5 rounded-lg hover:bg-blue-500/10 transition-colors inline-block">Analytics</Link>
                          <button onClick={() => { setEditingUser(user); setIsEditModalOpen(true); }} className="text-indigo-400 hover:text-indigo-300 font-medium px-3 py-1.5 rounded-lg hover:bg-indigo-500/10 transition-colors">Edit</button>
                          <button onClick={() => openDeleteModal(user)} className="text-red-400 hover:text-red-300 font-medium px-3 py-1.5 rounded-lg hover:bg-red-500/10 transition-colors">
                            {hasDeletion ? 'Manage Deletion' : 'Delete'}
                          </button>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Add User Modal */}
      {isAddModalOpen && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-[#1a1d27] border border-white/10 rounded-2xl p-8 max-w-md w-full shadow-2xl">
            <h3 className="text-xl font-bold text-white mb-6">Add New User</h3>
            <form onSubmit={handleAddUser} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-400 mb-1">Email</label>
                <input required type="email" value={newUser.email} onChange={e => setNewUser({...newUser, email: e.target.value})} className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-2.5 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-400 mb-1">Pseudonym</label>
                <input required type="text" value={newUser.pseudonym} onChange={e => setNewUser({...newUser, pseudonym: e.target.value})} className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-2.5 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-400 mb-1">Password</label>
                <input required type="password" value={newUser.password} onChange={e => setNewUser({...newUser, password: e.target.value})} className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-2.5 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-400 mb-1">Role</label>
                <select value={newUser.role} onChange={e => setNewUser({...newUser, role: e.target.value})} className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-2.5 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500">
                  <option value="USER">USER</option>
                  <option value="ADMIN">ADMIN</option>
                </select>
              </div>
              <div className="flex gap-4 pt-4">
                <button type="button" onClick={() => setIsAddModalOpen(false)} className="flex-1 px-4 py-2.5 text-gray-400 hover:text-white bg-white/5 hover:bg-white/10 rounded-xl transition-colors font-medium">Cancel</button>
                <button type="submit" disabled={isSubmitting} className="flex-1 bg-indigo-600 text-white px-4 py-2.5 rounded-xl font-medium shadow-lg shadow-indigo-600/20 hover:bg-indigo-500 disabled:opacity-50 transition-colors">
                  {isSubmitting ? 'Adding...' : 'Add User'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Edit User Modal */}
      {isEditModalOpen && editingUser && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-[#1a1d27] border border-white/10 rounded-2xl p-8 max-w-md w-full shadow-2xl">
            <h3 className="text-xl font-bold text-white mb-6">Edit User</h3>
            <form onSubmit={handleEditUser} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-400 mb-1">Email</label>
                <input required type="email" value={editingUser.email || ''} onChange={e => setEditingUser({...editingUser, email: e.target.value})} className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-2.5 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-400 mb-1">Pseudonym</label>
                <input required type="text" value={editingUser.pseudonym || ''} onChange={e => setEditingUser({...editingUser, pseudonym: e.target.value})} className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-2.5 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-400 mb-1">Role</label>
                <select value={editingUser.role} onChange={e => setEditingUser({...editingUser, role: e.target.value})} className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-2.5 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500">
                  <option value="USER">USER</option>
                  <option value="ADMIN">ADMIN</option>
                </select>
              </div>
              <div>
                <div className="flex justify-between items-center mb-1">
                  <label className="block text-sm font-medium text-gray-400">Scheduled Deletion Date</label>
                  {editingUser.scheduledDeletionDate && (
                    <button
                      type="button"
                      onClick={() => setEditingUser({ ...editingUser, scheduledDeletionDate: null })}
                      className="text-xs text-amber-400 hover:text-amber-300 underline">
                      Cancel Deletion
                    </button>
                  )}
                </div>
                <input 
                  type="datetime-local" 
                  value={editingUser.scheduledDeletionDate ? new Date(new Date(editingUser.scheduledDeletionDate).getTime() - new Date(editingUser.scheduledDeletionDate).getTimezoneOffset() * 60000).toISOString().slice(0, 16) : ''} 
                  onChange={e => setEditingUser({...editingUser, scheduledDeletionDate: e.target.value ? new Date(e.target.value).toISOString() : null})} 
                  className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-2.5 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500" 
                />
                <p className="text-xs text-gray-500 mt-1">Leave empty to keep account active. When this date arrives, backend automatically deletes user permanently.</p>
              </div>
              <div className="flex gap-4 pt-4">
                <button type="button" onClick={() => { setIsEditModalOpen(false); setEditingUser(null); }} className="flex-1 px-4 py-2.5 text-gray-400 hover:text-white bg-white/5 hover:bg-white/10 rounded-xl transition-colors font-medium">Cancel</button>
                <button type="submit" disabled={isSubmitting} className="flex-1 bg-indigo-600 text-white px-4 py-2.5 rounded-xl font-medium shadow-lg shadow-indigo-600/20 hover:bg-indigo-500 disabled:opacity-50 transition-colors">
                  {isSubmitting ? 'Saving...' : 'Save Changes'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Account Deletion & Scheduled Deletion Management Modal */}
      {isDeleteModalOpen && userToDelete && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-md z-50 flex items-center justify-center p-4">
          <div className="bg-[#1a1d27] border border-white/15 rounded-3xl p-8 max-w-lg w-full shadow-2xl space-y-6">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-2xl bg-red-500/20 text-red-400 flex items-center justify-center text-xl font-bold">
                ⚠️
              </div>
              <div>
                <h3 className="text-xl font-bold text-white">Account Deletion Manager</h3>
                <p className="text-sm text-gray-400">Target: <span className="text-white font-medium">{userToDelete.pseudonym || userToDelete.email || userToDelete.id}</span></p>
              </div>
            </div>

            {userToDelete.scheduledDeletionDate && (
              <div className="bg-amber-500/10 border border-amber-500/30 rounded-2xl p-4 flex items-start gap-3">
                <span className="text-amber-400 text-lg">⏳</span>
                <div className="text-xs text-amber-200 leading-relaxed">
                  <p className="font-semibold text-amber-300">Account is currently scheduled for deletion:</p>
                  <p className="mt-0.5">{new Date(userToDelete.scheduledDeletionDate).toLocaleString()}</p>
                  <p className="text-amber-400/80 mt-1">The automated server job will permanently remove all data and images on this exact date/time.</p>
                </div>
              </div>
            )}

            <div className="space-y-3 bg-white/5 border border-white/10 p-5 rounded-2xl">
              <label className="block text-sm font-semibold text-white">
                Set Scheduled Deletion Date & Time
              </label>
              <input 
                type="datetime-local" 
                value={scheduledDateInput} 
                onChange={(e) => setScheduledDateInput(e.target.value)}
                className="w-full bg-[#12141c] border border-white/20 rounded-xl px-4 py-2.5 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm" 
              />

              <div className="flex flex-wrap gap-2 pt-1">
                <button 
                  type="button" 
                  onClick={() => handleSetQuickPreset(1)}
                  className="px-3 py-1 text-xs bg-white/10 hover:bg-white/20 text-gray-300 rounded-lg transition-colors">
                  In 1 Hour
                </button>
                <button 
                  type="button" 
                  onClick={() => handleSetQuickPreset(24)}
                  className="px-3 py-1 text-xs bg-white/10 hover:bg-white/20 text-gray-300 rounded-lg transition-colors">
                  In 24 Hours
                </button>
                <button 
                  type="button" 
                  onClick={() => handleSetQuickPreset(24 * 7)}
                  className="px-3 py-1 text-xs bg-white/10 hover:bg-white/20 text-gray-300 rounded-lg transition-colors">
                  In 7 Days
                </button>
                <button 
                  type="button" 
                  onClick={() => handleSetQuickPreset(24 * 30)}
                  className="px-3 py-1 text-xs bg-white/10 hover:bg-white/20 text-gray-300 rounded-lg transition-colors">
                  In 30 Days (Default)
                </button>
              </div>

              <div className="pt-2 flex gap-3">
                <button
                  type="button"
                  disabled={isSubmitting || !scheduledDateInput}
                  onClick={() => handleSaveScheduledDeletion(userToDelete.id, scheduledDateInput)}
                  className="flex-1 bg-amber-600 hover:bg-amber-500 disabled:opacity-50 text-white font-medium py-2 px-4 rounded-xl text-xs transition-colors shadow-lg shadow-amber-600/20">
                  {isSubmitting ? 'Scheduling...' : 'Set Scheduled Deletion Date'}
                </button>
                {userToDelete.scheduledDeletionDate && (
                  <button
                    type="button"
                    disabled={isSubmitting}
                    onClick={() => handleSaveScheduledDeletion(userToDelete.id, null)}
                    className="bg-emerald-600/30 hover:bg-emerald-600/50 text-emerald-300 font-medium py-2 px-4 rounded-xl text-xs transition-colors border border-emerald-500/30">
                    Cancel Deletion
                  </button>
                )}
              </div>
            </div>

            <div className="border-t border-white/10 pt-4 flex flex-col gap-3">
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="text-sm font-semibold text-red-400">Immediate Permanent Deletion</h4>
                  <p className="text-xs text-gray-500">Skip schedule and purge database records & photos immediately.</p>
                </div>
                <button
                  type="button"
                  disabled={isSubmitting}
                  onClick={() => handleImmediateDelete(userToDelete.id)}
                  className="bg-red-600/20 hover:bg-red-600 text-red-300 hover:text-white border border-red-500/30 px-4 py-2 rounded-xl text-xs font-semibold transition-all">
                  Delete Now
                </button>
              </div>
            </div>

            <div className="pt-2 flex justify-end">
              <button 
                type="button" 
                onClick={() => { setIsDeleteModalOpen(false); setUserToDelete(null); }}
                className="px-6 py-2 text-sm text-gray-400 hover:text-white bg-white/5 hover:bg-white/10 rounded-xl transition-colors font-medium">
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
