import React, { useEffect, useState } from 'react';
import { adminApi } from '../../../api/adminApi';
import type { Category } from '../../../types';
import { CategoryFormModal } from './CategoryFormModal';
import { ActionButton, EditIcon, TrashIcon } from '../../../components/AdminActionButtons';
import { ConfirmModal } from '../../../components/Layout/ConfirmModal';
import { toast } from 'react-toastify';
import { CustomSelect } from '../../../components/Layout/CustomSelect';

export const AdminCategoriesPage: React.FC = () => {
  const [categories, setCategories] = useState<Category[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);
  const [confirmModalOpen, setConfirmModalOpen] = useState(false);
  const [confirmMessage, setConfirmMessage] = useState('');
  const [confirmAction, setConfirmAction] = useState<(() => Promise<void>) | null>(null);
  const [confirmLoading, setConfirmLoading] = useState(false);

  // Filters & Pagination
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [search, setSearch] = useState('');

  const fetchCategories = async () => {
    try {
      setIsLoading(true);
      const data = await adminApi.getCategories();
      setCategories(data);
    } catch (error) {
      toast.error('Lỗi khi tải danh sách danh mục');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchCategories();
  }, []);

  const handleCreate = () => {
    setEditingCategory(null);
    setIsModalOpen(true);
  };

  const handleEdit = (category: Category) => {
    setEditingCategory(category);
    setIsModalOpen(true);
  };

  const handleDelete = async (id: string) => {
    setConfirmMessage('Bạn có chắc chắn muốn xóa danh mục này không?');
    setConfirmAction(() => async () => {
      try {
        await adminApi.deleteCategory(id);
        toast.success('Xóa danh mục thành công');
        fetchCategories();
      } catch (error) {
        toast.error('Lỗi khi xóa danh mục');
      }
    });
    setConfirmModalOpen(true);
  };

  // Client-side filtering
  const filteredCategories = categories.filter(c => c.name.toLowerCase().includes(search.toLowerCase()) || (c.description && c.description.toLowerCase().includes(search.toLowerCase())));
  const totalPages = Math.ceil(filteredCategories.length / pageSize) || 1;
  const paginatedCategories = filteredCategories.slice((page - 1) * pageSize, page * pageSize);

  return (
    <div className="p-6">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-6 gap-4">
        <h1 className="text-2xl font-bold text-gray-800">Quản lý Danh mục</h1>
        <button onClick={handleCreate} className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-medium transition-colors shadow-sm">
          + Thêm Danh mục
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-4 mb-6">
        <input
          type="text"
          placeholder="Tìm tên hoặc mô tả..."
          className="border border-zinc-200 rounded-lg px-4 py-2 w-full md:w-64 bg-white shadow-sm"
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1); }}
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
          <table className="w-full text-left border-collapse min-w-[600px]">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-200">
                <th className="p-4 font-medium text-gray-600">Tên Danh mục</th>
                <th className="p-4 font-medium text-gray-600">Mô tả</th>
                <th className="p-4 font-medium text-gray-600">Trạng thái</th>
                <th className="p-4 font-medium text-gray-600 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {isLoading ? (
                <tr><td colSpan={4} className="p-8 text-center text-gray-500">Đang tải dữ liệu...</td></tr>
              ) : paginatedCategories.length === 0 ? (
                <tr><td colSpan={4} className="p-8 text-center text-gray-500">Không tìm thấy danh mục nào.</td></tr>
              ) : (
                paginatedCategories.map((category) => (
                  <tr key={category.id} className="hover:bg-gray-50">
                    <td className="p-4 font-medium text-gray-900">{category.name}</td>
                    <td className="p-4 text-gray-600">{category.description || '—'}</td>
                    <td className="p-4">
                      <span className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${category.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-700'}`}>
                        {category.isActive ? 'Hoạt động' : 'Bị ẩn'}
                      </span>
                    </td>
                    <td className="p-4 text-right">
                      <div className="inline-flex items-center justify-end gap-2">
                        <ActionButton label="Sửa" onClick={() => handleEdit(category)} icon={<EditIcon />} variant="secondary" />
                        <ActionButton label="Xóa" onClick={() => handleDelete(category.id)} icon={<TrashIcon />} variant="danger" />
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Controls */}
        {!isLoading && filteredCategories.length > 0 && (
          <div className="p-4 border-t border-gray-200 flex items-center justify-between bg-gray-50">
            <span className="text-sm text-gray-600">
              Hiển thị {((page - 1) * pageSize) + 1} đến {Math.min(page * pageSize, filteredCategories.length)} trong số {filteredCategories.length} kết quả
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

      <ConfirmModal
        isOpen={confirmModalOpen}
        title="Xác nhận hành động"
        description={confirmMessage}
        confirmLabel="Có"
        cancelLabel="Không"
        isLoading={confirmLoading}
        onConfirm={async () => {
          if (!confirmAction) return;
          setConfirmLoading(true);
          await confirmAction();
          setConfirmLoading(false);
          setConfirmModalOpen(false);
          setConfirmAction(null);
        }}
        onClose={() => {
          setConfirmModalOpen(false);
          setConfirmAction(null);
        }}
      />
      <CategoryFormModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} category={editingCategory} onSuccess={fetchCategories} />
    </div>
  );
};
