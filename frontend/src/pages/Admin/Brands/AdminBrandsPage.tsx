import React, { useEffect, useState } from 'react';
import { adminApi } from '../../../api/adminApi';
import type { Brand } from '../../../types';
import { BrandFormModal } from './BrandFormModal';
import { ActionButton, EditIcon, TrashIcon } from '../../../components/AdminActionButtons';
import { toast } from 'react-toastify';
import { CustomSelect } from '../../../components/Layout/CustomSelect';

export const AdminBrandsPage: React.FC = () => {
  const [brands, setBrands] = useState<Brand[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingBrand, setEditingBrand] = useState<Brand | null>(null);

  // Filters & Pagination
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [search, setSearch] = useState('');

  const fetchBrands = async () => {
    try {
      setIsLoading(true);
      const data = await adminApi.getBrands();
      setBrands(data);
    } catch (error) {
      toast.error('Lỗi khi tải danh sách thương hiệu');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchBrands();
  }, []);

  const handleCreate = () => {
    setEditingBrand(null);
    setIsModalOpen(true);
  };

  const handleEdit = (brand: Brand) => {
    setEditingBrand(brand);
    setIsModalOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa thương hiệu này không?')) {
      try {
        await adminApi.deleteBrand(id);
        toast.success('Xóa thương hiệu thành công');
        fetchBrands();
      } catch (error) {
        toast.error('Lỗi khi xóa thương hiệu');
      }
    }
  };

  // Client-side filtering
  const filteredBrands = brands.filter(b => b.name.toLowerCase().includes(search.toLowerCase()));
  const totalPages = Math.ceil(filteredBrands.length / pageSize) || 1;
  const paginatedBrands = filteredBrands.slice((page - 1) * pageSize, page * pageSize);

  return (
    <div className="p-6">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-6 gap-4">
        <h1 className="text-2xl font-bold text-gray-800">Quản lý Thương hiệu</h1>
        <button onClick={handleCreate} className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-medium transition-colors shadow-sm">
          + Thêm Thương hiệu
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-4 mb-6">
        <input
          type="text"
          placeholder="Tìm tên thương hiệu..."
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
                <th className="p-4 font-medium text-gray-600">Thương hiệu</th>
                <th className="p-4 font-medium text-gray-600">Trạng thái</th>
                <th className="p-4 font-medium text-gray-600">Ngày tạo</th>
                <th className="p-4 font-medium text-gray-600 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {isLoading ? (
                <tr><td colSpan={4} className="p-8 text-center text-gray-500">Đang tải dữ liệu...</td></tr>
              ) : paginatedBrands.length === 0 ? (
                <tr><td colSpan={4} className="p-8 text-center text-gray-500">Không tìm thấy thương hiệu nào.</td></tr>
              ) : (
                paginatedBrands.map((brand) => (
                  <tr key={brand.id} className="hover:bg-gray-50">
                    <td className="p-4">
                      <div className="flex items-center gap-3">
                        <img src={brand.logo || 'https://placehold.co/40x40'} alt={brand.name} className="w-10 h-10 rounded object-cover border" />
                        <span className="font-medium text-gray-900">{brand.name}</span>
                      </div>
                    </td>
                    <td className="p-4">
                      <span className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${brand.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-700'}`}>
                        {brand.isActive ? 'Hoạt động' : 'Bị ẩn'}
                      </span>
                    </td>
                    <td className="p-4 text-gray-600 text-sm">{brand.createdAt ? new Date(brand.createdAt).toLocaleDateString('vi-VN') : '—'}</td>
                    <td className="p-4 text-right">
                      <div className="inline-flex items-center justify-end gap-2">
                        <ActionButton label="Sửa" onClick={() => handleEdit(brand)} icon={<EditIcon />} variant="secondary" />
                        <ActionButton label="Xóa" onClick={() => handleDelete(brand.id)} icon={<TrashIcon />} variant="danger" />
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Controls */}
        {!isLoading && filteredBrands.length > 0 && (
          <div className="p-4 border-t border-gray-200 flex items-center justify-between bg-gray-50">
            <span className="text-sm text-gray-600">
              Hiển thị {((page - 1) * pageSize) + 1} đến {Math.min(page * pageSize, filteredBrands.length)} trong số {filteredBrands.length} kết quả
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

      <BrandFormModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} brand={editingBrand} onSuccess={fetchBrands} />
    </div>
  );
};
