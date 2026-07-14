import React, { useEffect, useState } from 'react';
import { adminApi } from '../../../api/adminApi';
import type { Order } from '../../../types';
import { OrderStatusModal } from './OrderStatusModal';
import { ActionButton, RefreshIcon } from '../../../components/AdminActionButtons';
import { toast } from 'react-toastify';

export const AdminOrdersPage: React.FC = () => {
  const [orders, setOrders] = useState<Order[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);

  // Filters & Pagination
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [paymentStatusFilter, setPaymentStatusFilter] = useState('');

  const fetchOrders = async () => {
    try {
      setIsLoading(true);
      const data = await adminApi.getOrders(page, pageSize, search, statusFilter, paymentStatusFilter);
      setOrders(data.items || []);
      setTotalCount(data.totalCount || 0);
    } catch (error) {
      toast.error('Lỗi khi tải danh sách đơn hàng');
      setOrders([]);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders();
  }, [page, pageSize, statusFilter, paymentStatusFilter]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    setPage(1);
    fetchOrders();
  };

  const handleStatusChange = (order: Order) => {
    setSelectedOrder(order);
    setIsModalOpen(true);
  };

  const handlePaymentConfirm = async (orderId: string) => {
    if (window.confirm('Xác nhận đã nhận được tiền cho đơn hàng này?')) {
      try {
        await adminApi.updatePaymentStatus(orderId, 'Paid');
        toast.success('Đã cập nhật trạng thái thanh toán');
        fetchOrders();
      } catch (error) {
        toast.error('Có lỗi xảy ra');
      }
    }
  };

  const totalPages = Math.ceil(totalCount / pageSize) || 1;

  const translateStatus = (status: string) => {
    switch (status) {
      case 'Pending': return 'Chờ xác nhận';
      case 'Processing': return 'Đang xử lý';
      case 'Shipped': return 'Đang giao';
      case 'Delivered': return 'Đã giao';
      case 'Cancelled': return 'Đã huỷ';
      default: return status;
    }
  };

  const translatePaymentStatus = (status: string) => {
    return status === 'Paid' ? 'Đã thanh toán' : 'Chưa thanh toán';
  };

  return (
    <div className="p-6">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-6 gap-4">
        <h1 className="text-2xl font-bold text-gray-800">Quản lý Đơn hàng</h1>
        
        <form onSubmit={handleSearch} className="flex gap-2 w-full md:w-auto">
          <input
            type="text"
            placeholder="Tìm mã ĐH hoặc tên KH..."
            className="border rounded px-3 py-2 w-full md:w-64"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          <button type="submit" className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700">Tìm kiếm</button>
        </form>
      </div>

      <div className="flex flex-wrap gap-4 mb-6">
        <select 
          className="border rounded px-3 py-2 bg-white"
          value={statusFilter}
          onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }}
        >
          <option value="">Tất cả trạng thái đơn</option>
          <option value="Pending">Chờ xác nhận</option>
          <option value="Processing">Đang xử lý</option>
          <option value="Shipped">Đang giao</option>
          <option value="Delivered">Đã giao</option>
          <option value="Cancelled">Đã huỷ</option>
        </select>

        <select 
          className="border rounded px-3 py-2 bg-white"
          value={paymentStatusFilter}
          onChange={(e) => { setPaymentStatusFilter(e.target.value); setPage(1); }}
        >
          <option value="">Tất cả trạng thái thanh toán</option>
          <option value="Paid">Đã thanh toán</option>
          <option value="Unpaid">Chưa thanh toán</option>
        </select>

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
                <th className="p-4 font-medium text-gray-600">Đơn hàng</th>
                <th className="p-4 font-medium text-gray-600">Khách hàng</th>
                <th className="p-4 font-medium text-gray-600">Tổng tiền</th>
                <th className="p-4 font-medium text-gray-600">Trạng thái</th>
                <th className="p-4 font-medium text-gray-600">Thanh toán</th>
                <th className="p-4 font-medium text-gray-600">Ngày đặt</th>
                <th className="p-4 font-medium text-gray-600 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {isLoading ? (
                <tr><td colSpan={7} className="p-8 text-center text-gray-500">Đang tải dữ liệu...</td></tr>
              ) : orders.length === 0 ? (
                <tr><td colSpan={7} className="p-8 text-center text-gray-500">Không tìm thấy đơn hàng nào.</td></tr>
              ) : (
                orders.map((order) => (
                  <tr key={order.id} className="hover:bg-gray-50">
                    <td className="p-4">
                      <div className="font-medium text-gray-900">#{order.orderCode}</div>
                      <div className="text-xs text-gray-500 mt-1">{order.paymentMethod === 'PayOS' ? 'Chuyển khoản' : 'Thanh toán tại cửa hàng'}</div>
                    </td>
                    <td className="p-4">
                      <div className="font-medium text-gray-900">{order.receiverName}</div>
                      <div className="text-sm text-gray-500">{order.phone}</div>
                    </td>
                    <td className="p-4 font-medium text-red-600">{order.finalAmount.toLocaleString('vi-VN')} đ</td>
                    <td className="p-4">
                      <span className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${order.status === 'Delivered' ? 'bg-green-100 text-green-700' : order.status === 'Cancelled' ? 'bg-red-100 text-red-700' : 'bg-yellow-100 text-yellow-700'}`}>
                        {translateStatus(order.status)}
                      </span>
                    </td>
                    <td className="p-4">
                      <span className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${order.paymentStatus === 'Paid' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-700'}`}>
                        {translatePaymentStatus(order.paymentStatus)}
                      </span>
                    </td>
                    <td className="p-4 text-gray-600 text-sm">{new Date(order.createdAt).toLocaleDateString('vi-VN')} {new Date(order.createdAt).toLocaleTimeString('vi-VN')}</td>
                    <td className="p-4 text-right">
                      <div className="flex justify-end gap-2">
                        {order.paymentStatus !== 'Paid' && (
                           <ActionButton label="Đã thu tiền" onClick={() => handlePaymentConfirm(order.id)} icon={<RefreshIcon />} variant="secondary" />
                        )}
                        <ActionButton label="Cập nhật" onClick={() => handleStatusChange(order)} icon={<RefreshIcon />} variant="primary" />
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
        
        {/* Pagination Controls */}
        {!isLoading && totalCount > 0 && (
          <div className="p-4 border-t border-gray-200 flex items-center justify-between">
            <span className="text-sm text-gray-600">
              Hiển thị {((page - 1) * pageSize) + 1} đến {Math.min(page * pageSize, totalCount)} trong số {totalCount} kết quả
            </span>
            <div className="flex gap-1">
              <button 
                disabled={page === 1}
                onClick={() => setPage(p => p - 1)}
                className="px-3 py-1 border rounded hover:bg-gray-50 disabled:opacity-50"
              >
                Trước
              </button>
              <button 
                disabled={page === totalPages}
                onClick={() => setPage(p => p + 1)}
                className="px-3 py-1 border rounded hover:bg-gray-50 disabled:opacity-50"
              >
                Sau
              </button>
            </div>
          </div>
        )}
      </div>

      <OrderStatusModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} order={selectedOrder} onSuccess={fetchOrders} />
    </div>
  );
};
