import React, { useEffect, useState } from 'react';
import { adminApi } from '../../../api/adminApi';
import type { Order } from '../../../types';
import { CustomSelect } from '../../../components/Layout/CustomSelect';
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
      <div className="bg-white rounded-lg shadow-xl w-full max-w-3xl max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center p-6 border-b sticky top-0 bg-white z-10">
          <h2 className="text-xl font-bold">Cập nhật Trạng thái Đơn hàng</h2>
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
          </button>
        </div>

        <div className="p-6 space-y-6">
          <form onSubmit={onSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-1">Chọn trạng thái mới</label>
              <CustomSelect
                options={statusOptions}
                value={status}
                onChange={(val) => setStatus(val)}
              />
            </div>

            <div className="bg-gray-50 rounded-md p-4 text-sm text-gray-600">
              <div><strong>Mã đơn:</strong> #{order.orderCode}</div>
              <div><strong>Khách hàng:</strong> {order.receiverName}</div>
              <div><strong>Trạng thái hiện tại:</strong> {translateStatus(order.status)}</div>
              {order.staffName && (
                <div><strong>Nhân viên xử lý:</strong> {order.staffName}</div>
              )}
            </div>

            <div className="flex justify-end pt-4 border-t gap-2">
              <button type="button" onClick={onClose} className="px-4 py-2 border rounded-md text-gray-700 hover:bg-gray-50 transition-colors">Hủy</button>
              <button type="submit" disabled={isLoading} className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 transition-colors shadow-sm">
                {isLoading ? 'Đang cập nhật...' : 'Lưu trạng thái'}
              </button>
            </div>
          </form>

          {order.auditLogs && order.auditLogs.length > 0 && (
            <div className="border-t pt-4">
              <h3 className="text-lg font-semibold text-gray-800 mb-3">Lịch sử thay đổi</h3>
              <div className="space-y-3">
                {order.auditLogs
                  .slice()
                  .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
                  .map((log) => (
                    <div key={log.id} className="bg-gray-50 rounded-lg p-4 border border-gray-200">
                      <div className="flex justify-between items-start">
                        <div>
                          <div className="font-semibold text-gray-800">{log.staffName}</div>
                          <div className="text-sm text-gray-600 mt-1">{log.details}</div>
                        </div>
                        <div className="text-xs text-gray-500">
                          {new Date(log.timestamp).toLocaleDateString('vi-VN')} {new Date(log.timestamp).toLocaleTimeString('vi-VN')}
                        </div>
                      </div>
                      {log.oldValue && log.newValue && (
                        <div className="mt-2 text-sm text-gray-600">
                          <span className="text-red-600 line-through">{log.oldValue}</span>
                          <span className="mx-2">→</span>
                          <span className="text-green-600 font-medium">{log.newValue}</span>
                        </div>
                      )}
                    </div>
                  ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
