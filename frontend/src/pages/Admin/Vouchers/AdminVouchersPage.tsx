import React, { useEffect, useState } from 'react';
import { adminApi } from '../../../api/adminApi';
import type { Voucher } from '../../../types';
import { VoucherFormModal } from './VoucherFormModal';
import { ActionButton, EditIcon, TrashIcon } from '../../../components/AdminActionButtons';
import { toast } from 'react-toastify';

export const AdminVouchersPage: React.FC = () => {
  const [vouchers, setVouchers] = useState<Voucher[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingVoucher, setEditingVoucher] = useState<Voucher | null>(null);

  // Filters & Pagination
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [search, setSearch] = useState('');

  const fetchVouchers = async () => {
    try {
      setIsLoading(true);
      const data = await adminApi.getVouchers();
      setVouchers(data);
    } catch (error) {
      toast.error('Lỗi khi tải danh sách mã giảm giá');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchVouchers();
  }, []);

  const handleCreate = () => {
    setEditingVoucher(null);
    setIsModalOpen(true);
  };

  const handleEdit = (voucher: Voucher) => {
    setEditingVoucher(voucher);
    setIsModalOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa mã giảm giá này không?')) {
      try {
        await adminApi.deleteVoucher(id);
        toast.success('Xóa mã giảm giá thành công');
        fetchVouchers();
      } catch (error) {
        toast.error('Lỗi khi xóa mã giảm giá');
      }
    }
  };

  // Client-side filtering
  const filteredVouchers = vouchers.filter(v => v.code.toLowerCase().includes(search.toLowerCase()) || (v.description && v.description.toLowerCase().includes(search.toLowerCase())));
  const totalPages = Math.ceil(filteredVouchers.length / pageSize) || 1;
  const paginatedVouchers = filteredVouchers.slice((page - 1) * pageSize, page * pageSize);

  return (
    <div className="p-6">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-6 gap-4">
        <h1 className="text-2xl font-bold text-gray-800">Quản lý Mã giảm giá</h1>
        <button onClick={handleCreate} className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-medium transition-colors shadow-sm">
          + Thêm Mã giảm giá
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-4 mb-6">
        <input
          type="text"
          placeholder="Tìm mã hoặc mô tả..."
          className="border rounded px-3 py-2 w-full md:w-64 bg-white"
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1); }}
        />

        <select 
          className="border rounded px-3 py-2 bg-white"
          value={pageSize}
          onChange={(e) => { setPageSize(Number(e.target.value)); setPage(1); }}
        >
          <option value={10}>10 dòng / trang</option>
          <option value={20}>20 dòng / trang</option>
          <option value={50}>50 dòng / trang</option>
        </select>
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[800px]">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-200">
                <th className="p-4 font-medium text-gray-600">Mã Voucher</th>
                <th className="p-4 font-medium text-gray-600">Mức giảm</th>
                <th className="p-4 font-medium text-gray-600">Số lượng còn</th>
                <th className="p-4 font-medium text-gray-600">Trạng thái</th>
                <th className="p-4 font-medium text-gray-600 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {isLoading ? (
                <tr><td colSpan={5} className="p-8 text-center text-gray-500">Đang tải dữ liệu...</td></tr>
              ) : paginatedVouchers.length === 0 ? (
                <tr><td colSpan={5} className="p-8 text-center text-gray-500">Không tìm thấy mã giảm giá nào.</td></tr>
              ) : (
                paginatedVouchers.map((voucher) => (
                  <tr key={voucher.id} className="hover:bg-gray-50">
                    <td className="p-4">
                      <div className="font-medium text-gray-900">{voucher.code}</div>
                      <div className="text-sm text-gray-500 mt-1">{voucher.description || 'Không có mô tả'}</div>
                    </td>
                    <td className="p-4 text-gray-600 font-medium text-red-600">
                      {voucher.discountType === 'Percentage' ? `${voucher.discountValue}%` : `${voucher.discountValue.toLocaleString('vi-VN')}đ`}
                    </td>
                    <td className="p-4 text-gray-600">
                      <span className="font-medium">{voucher.quantity - voucher.used}</span> / {voucher.quantity} (đã dùng {voucher.used})
                    </td>
                    <td className="p-4">
                      <span className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${voucher.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-700'}`}>
                        {voucher.isActive ? 'Hoạt động' : 'Bị ẩn'}
                      </span>
                    </td>
                    <td className="p-4 text-right">
                      <div className="inline-flex items-center justify-end gap-2">
                        <ActionButton label="Sửa" onClick={() => handleEdit(voucher)} icon={<EditIcon />} variant="secondary" />
                        <ActionButton label="Xóa" onClick={() => handleDelete(voucher.id)} icon={<TrashIcon />} variant="danger" />
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Controls */}
        {!isLoading && filteredVouchers.length > 0 && (
          <div className="p-4 border-t border-gray-200 flex items-center justify-between bg-gray-50">
            <span className="text-sm text-gray-600">
              Hiển thị {((page - 1) * pageSize) + 1} đến {Math.min(page * pageSize, filteredVouchers.length)} trong số {filteredVouchers.length} kết quả
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

      <VoucherFormModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} voucher={editingVoucher} onSuccess={fetchVouchers} />
    </div>
  );
};
