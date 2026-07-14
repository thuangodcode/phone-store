import React, { useEffect, useState } from 'react';
import { adminApi } from '../../../api/adminApi';
import type { Order } from '../../../types';
import { toast } from 'react-toastify';

interface OrderStatusModalProps {
  isOpen: boolean;
  onClose: () => void;
  order: Order | null;
  onSuccess: () => void;
}

const statusOptions = [
  { value: 'Pending', label: 'Chờ xác nhận' },
  { value: 'Processing', label: 'Đang xử lý' },
  { value: 'Shipped', label: 'Đang giao' },
  { value: 'Delivered', label: 'Đã giao' },
  { value: 'Cancelled', label: 'Đã huỷ' }
];

export const OrderStatusModal: React.FC<OrderStatusModalProps> = ({ isOpen, onClose, order, onSuccess }) => {
  const [status, setStatus] = useState('Pending');
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    setStatus(order?.status || 'Pending');
  }, [order, isOpen]);

  if (!isOpen || !order) return null;

  const onSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    try {
      setIsLoading(true);
      await adminApi.updateOrderStatus(order.id, { status });
      toast.success('Cập nhật trạng thái đơn hàng thành công');
      onSuccess();
      onClose();
    } catch (error: any) {
      toast.error(error?.message || 'Có lỗi khi cập nhật trạng thái');
    } finally {
      setIsLoading(false);
    }
  };

  const translateStatus = (s: string) => {
    return statusOptions.find(opt => opt.value === s)?.label || s;
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 overflow-y-auto px-4 py-10">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-lg">
        <div className="flex justify-between items-center p-6 border-b">
          <h2 className="text-xl font-bold">Cập nhật Trạng thái Đơn hàng</h2>
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
          </button>
        </div>

        <form onSubmit={onSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">Chọn trạng thái mới</label>
            <select value={status} onChange={(e) => setStatus(e.target.value)} className="w-full border rounded-md px-3 py-2">
              {statusOptions.map((option) => (
                <option key={option.value} value={option.value}>{option.label}</option>
              ))}
            </select>
          </div>

          <div className="bg-gray-50 rounded-md p-4 text-sm text-gray-600">
            <div><strong>Mã đơn:</strong> #{order.orderCode}</div>
            <div><strong>Khách hàng:</strong> {order.receiverName}</div>
            <div><strong>Trạng thái hiện tại:</strong> {translateStatus(order.status)}</div>
          </div>

          <div className="flex justify-end pt-4 border-t gap-2">
            <button type="button" onClick={onClose} className="px-4 py-2 border rounded-md text-gray-700 hover:bg-gray-50">Hủy</button>
            <button type="submit" disabled={isLoading} className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50">
              {isLoading ? 'Đang cập nhật...' : 'Lưu trạng thái'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
