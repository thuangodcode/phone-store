import React, { useEffect, useState } from 'react';
import { adminApi } from '../../../api/adminApi';
import type { User } from '../../../types';
import { ActionButton, RefreshIcon, TrashIcon } from '../../../components/AdminActionButtons';
import { toast } from 'react-toastify';
import { CustomSelect } from '../../../components/Layout/CustomSelect';

export const AdminUsersPage: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Filters & Pagination
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  // Create User Modal
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [newUser, setNewUser] = useState({ fullName: '', email: '', password: '', phone: '', address: '', role: 'User' });
  const [isCreating, setIsCreating] = useState(false);

  const fetchUsers = async () => {
    try {
      setIsLoading(true);
      const data = await adminApi.getUsers();
      setUsers(data);
    } catch (error) {
      toast.error('Lỗi khi tải danh sách người dùng');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleToggleStatus = async (user: User) => {
    try {
      await adminApi.toggleUserStatus(user.id);
      toast.success(`Đã ${user.isActive ? 'khóa' : 'mở khóa'} tài khoản ${user.fullName}`);
      fetchUsers();
    } catch (error) {
      toast.error('Lỗi khi cập nhật trạng thái');
    }
  };

  const handleDelete = async (id: string, fullName: string) => {
    if (window.confirm(`Bạn có chắc muốn xóa người dùng ${fullName}? Hành động này không thể hoàn tác!`)) {
      try {
        await adminApi.deleteUser(id);
        toast.success('Xóa người dùng thành công');
        fetchUsers();
      } catch (error) {
        toast.error('Lỗi khi xóa người dùng');
      }
    }
  };

  const handleCreateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setIsCreating(true);
      await adminApi.createUser(newUser);
      toast.success('Tạo tài khoản thành công!');
      setIsModalOpen(false);
      setNewUser({ fullName: '', email: '', password: '', phone: '', address: '', role: 'User' });
      fetchUsers();
    } catch (error: any) {
      toast.error(error?.response?.data?.message || 'Có lỗi xảy ra khi tạo tài khoản');
    } finally {
      setIsCreating(false);
    }
  };

  // Client-side filtering
  const filteredUsers = users.filter(u => {
    const matchSearch = u.fullName.toLowerCase().includes(search.toLowerCase()) || u.email.toLowerCase().includes(search.toLowerCase());
    const matchRole = roleFilter ? u.role === roleFilter : true;
    const matchStatus = statusFilter ? (statusFilter === 'active' ? u.isActive : !u.isActive) : true;
    return matchSearch && matchRole && matchStatus;
  });

  const totalPages = Math.ceil(filteredUsers.length / pageSize) || 1;
  const paginatedUsers = filteredUsers.slice((page - 1) * pageSize, page * pageSize);

  return (
    <div className="p-6">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-6 gap-4">
        <h1 className="text-2xl font-bold text-gray-800">Quản lý Người dùng</h1>
        <button 
          onClick={() => setIsModalOpen(true)}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg font-medium hover:bg-blue-700 transition-colors shadow-sm"
        >
          + Tạo tài khoản
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-4 mb-6">
        <input
          type="text"
          placeholder="Tìm tên hoặc email..."
          className="border border-zinc-200 rounded-lg px-4 py-2 w-full md:w-64 bg-white shadow-sm"
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1); }}
        />

        <CustomSelect
          options={[
            { value: '', label: 'Tất cả vai trò' },
            { value: 'Admin', label: 'Quản trị viên (Admin)' },
            { value: 'Staff', label: 'Nhân viên (Staff)' },
            { value: 'Customer', label: 'Người dùng (Customer)' }
          ]}
          value={roleFilter}
          onChange={(val) => { setRoleFilter(val); setPage(1); }}
        />

        <CustomSelect
          options={[
            { value: '', label: 'Tất cả trạng thái' },
            { value: 'active', label: 'Đang hoạt động' },
            { value: 'inactive', label: 'Đã khóa' }
          ]}
          value={statusFilter}
          onChange={(val) => { setStatusFilter(val); setPage(1); }}
        />

        <CustomSelect
          options={[
            { value: '10', label: '10 dòng / trang' },
            { value: '20', label: '20 dòng / trang' },
            { value: '50', label: '50 dòng / trang' }
          ]}
          value={String(pageSize)}
          onChange={(val) => { setPageSize(Number(val)); setPage(1); }}
        />
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[800px]">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-200">
                <th className="p-4 font-medium text-gray-600">Người dùng</th>
                <th className="p-4 font-medium text-gray-600">Vai trò</th>
                <th className="p-4 font-medium text-gray-600">Trạng thái</th>
                <th className="p-4 font-medium text-gray-600">Ngày tham gia</th>
                <th className="p-4 font-medium text-gray-600 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {isLoading ? (
                <tr><td colSpan={5} className="p-8 text-center text-gray-500">Đang tải dữ liệu...</td></tr>
              ) : paginatedUsers.length === 0 ? (
                <tr><td colSpan={5} className="p-8 text-center text-gray-500">Không tìm thấy người dùng nào.</td></tr>
              ) : (
                paginatedUsers.map((user) => (
                  <tr key={user.id} className="hover:bg-gray-50">
                    <td className="p-4">
                      <div className="font-medium text-gray-900">{user.fullName}</div>
                      <div className="text-sm text-gray-500">{user.email}</div>
                    </td>
                    <td className="p-4 text-gray-600">
                      <span className={`px-2 py-1 rounded text-xs font-semibold ${user.role === 'Admin' ? 'bg-purple-100 text-purple-700' : user.role === 'Staff' ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-700'}`}>
                        {user.role}
                      </span>
                    </td>
                    <td className="p-4">
                      <span className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${user.isActive ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                        {user.isActive ? 'Hoạt động' : 'Đã khóa'}
                      </span>
                    </td>
                    <td className="p-4 text-gray-600 text-sm">{user.createdAt ? new Date(user.createdAt).toLocaleDateString('vi-VN') : '—'}</td>
                    <td className="p-4 text-right">
                      <div className="inline-flex items-center justify-end gap-2">
                        <ActionButton
                          label={user.isActive ? 'Khóa' : 'Mở khóa'}
                          onClick={() => handleToggleStatus(user)}
                          icon={<RefreshIcon />}
                          variant="secondary"
                        />
                        <ActionButton label="Xóa" onClick={() => handleDelete(user.id, user.fullName)} icon={<TrashIcon />} variant="danger" />
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Controls */}
        {!isLoading && filteredUsers.length > 0 && (
          <div className="p-4 border-t border-gray-200 flex items-center justify-between bg-gray-50">
            <span className="text-sm text-gray-600">
              Hiển thị {((page - 1) * pageSize) + 1} đến {Math.min(page * pageSize, filteredUsers.length)} trong số {filteredUsers.length} kết quả
            </span>
            <div className="flex gap-1">
              <button 
                disabled={page === 1}
                onClick={() => setPage(p => p - 1)}
                className="px-3 py-1 border rounded bg-white hover:bg-gray-100 disabled:opacity-50 transition-colors"
              >
                Trước
              </button>
              <button 
                disabled={page === totalPages}
                onClick={() => setPage(p => p + 1)}
                className="px-3 py-1 border rounded bg-white hover:bg-gray-100 disabled:opacity-50 transition-colors"
              >
                Sau
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Create User Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-md overflow-hidden">
            <div className="flex justify-between items-center p-5 border-b">
              <h2 className="text-xl font-bold">Tạo tài khoản mới</h2>
              <button onClick={() => setIsModalOpen(false)} className="text-gray-500 hover:text-gray-700">
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
              </button>
            </div>

            <form onSubmit={handleCreateUser} className="p-5 space-y-4">
              <div>
                <label className="block text-sm font-medium mb-1">Họ và tên *</label>
                <input required type="text" value={newUser.fullName} onChange={(e) => setNewUser({...newUser, fullName: e.target.value})} className="w-full border rounded px-3 py-2" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Email *</label>
                <input required type="email" value={newUser.email} onChange={(e) => setNewUser({...newUser, email: e.target.value})} className="w-full border rounded px-3 py-2" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Mật khẩu *</label>
                <input required type="password" value={newUser.password} onChange={(e) => setNewUser({...newUser, password: e.target.value})} className="w-full border rounded px-3 py-2" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Số điện thoại</label>
                <input type="text" value={newUser.phone} onChange={(e) => setNewUser({...newUser, phone: e.target.value})} className="w-full border rounded px-3 py-2" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Địa chỉ</label>
                <input type="text" value={newUser.address} onChange={(e) => setNewUser({...newUser, address: e.target.value})} className="w-full border rounded px-3 py-2" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Vai trò *</label>
                <select value={newUser.role} onChange={(e) => setNewUser({...newUser, role: e.target.value})} className="w-full border rounded px-3 py-2">
                  <option value="User">Người dùng (User)</option>
                  <option value="Staff">Nhân viên (Staff)</option>
                  <option value="Admin">Quản trị viên (Admin)</option>
                </select>
              </div>

              <div className="flex justify-end pt-4 gap-2">
                <button type="button" onClick={() => setIsModalOpen(false)} className="px-4 py-2 border rounded hover:bg-gray-50">Hủy</button>
                <button type="submit" disabled={isCreating} className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50">
                  {isCreating ? 'Đang tạo...' : 'Tạo tài khoản'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
