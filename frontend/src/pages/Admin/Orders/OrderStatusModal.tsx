import React from 'react';
import type { Order } from '../../../types';

interface OrderStatusModalProps {
  isOpen: boolean;
  onClose: () => void;
  order: Order | null;
}

const statusOptions = [
  { value: 'Pending', label: 'Chờ xác nhận' },
  { value: 'Confirmed', label: 'Đã xác nhận' },
  { value: 'Processing', label: 'Đang xử lý' },
  { value: 'Shipped', label: 'Đang giao' },
  { value: 'Delivered', label: 'Đã giao' },
  { value: 'Cancelled', label: 'Đã huỷ' },
  { value: 'Paid', label: 'Đã thanh toán' },
  { value: 'Unpaid', label: 'Chưa thanh toán' }
];

export const OrderStatusModal: React.FC<OrderStatusModalProps> = ({ isOpen, onClose, order }) => {
  if (!isOpen || !order) return null;

  const translateStatus = (s: string) => {
    return statusOptions.find(opt => opt.value === s)?.label || s;
  };

  const translateAuditDetails = (details: string) => {
    return details
      .replace(/\bPending\b/g, 'Chờ xác nhận')
      .replace(/\bConfirmed\b/g, 'Đã xác nhận')
      .replace(/\bProcessing\b/g, 'Đang xử lý')
      .replace(/\bShipped\b/g, 'Đang giao')
      .replace(/\bDelivered\b/g, 'Đã giao')
      .replace(/\bCancelled\b/g, 'Đã huỷ')
      .replace(/\bPaid\b/g, 'Đã thanh toán')
      .replace(/\bUnpaid\b/g, 'Chưa thanh toán');
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 overflow-y-auto px-4 py-10">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-3xl max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center p-6 border-b sticky top-0 bg-white z-10">
          <h2 className="text-xl font-bold">Thông tin Đơn hàng</h2>
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700" type="button">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
          </button>
        </div>

        <div className="p-6 space-y-6">
          <div className="bg-gray-50 rounded-md p-4 text-sm text-gray-600">
            <div className="mb-3"><strong>Mã đơn:</strong> #{order.orderCode}</div>
            <div className="mb-3"><strong>Khách hàng:</strong> {order.receiverName}</div>
            <div className="mb-3"><strong>Số điện thoại:</strong> {order.phone}</div>
            <div className="mb-3"><strong>Địa chỉ giao hàng:</strong> {order.shippingAddress}</div>
            <div className="mb-3"><strong>Phương thức thanh toán:</strong> {order.paymentMethod === 'PayOS' ? 'Chuyển khoản Online' : 'Nhận & Thanh toán tại cửa hàng'}</div>
            <div className="mb-3"><strong>Trạng thái hiện tại:</strong> {translateStatus(order.status)}</div>
            <div className="mb-3"><strong>Thanh toán:</strong> {order.paymentStatus === 'Paid' ? 'Đã thanh toán' : 'Chưa thanh toán'}</div>
            {order.staffName && (
              <div className="mb-3"><strong>Nhân viên xử lý:</strong> {order.staffName}</div>
            )}
            {order.note && <div className="mb-3"><strong>Ghi chú:</strong> {order.note}</div>}
          </div>

          <div className="border-t pt-4">
            <h3 className="text-lg font-semibold text-gray-800 mb-3">Sản phẩm đã đặt</h3>
            <div className="space-y-3">
              {order.items?.map((item, index) => (
                <div key={index} className="flex items-center gap-4 bg-gray-50 rounded-lg p-3 border border-gray-200">
                  <img src={item.productImage || 'https://via.placeholder.com/64'} alt={item.productName} className="w-16 h-16 object-cover rounded-md border border-gray-200" />
                  <div className="flex-1">
                    <div className="font-semibold text-gray-800">{item.productName}</div>
                    <div className="text-sm text-gray-600">
                      {item.storage && <span>Phiên bản: {item.storage}</span>}
                      {item.storage && item.color && <span className="mx-1">|</span>}
                      {item.color && <span>Màu: {item.color}</span>}
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-sm text-gray-600 mb-1">SL: {item.quantity}</div>
                    <div className="font-semibold text-red-600">{item.price.toLocaleString('vi-VN')} đ</div>
                  </div>
                </div>
              ))}
            </div>
            
            <div className="mt-4 flex justify-end">
              <div className="w-64 space-y-2 text-sm bg-gray-50 p-3 rounded-md border border-gray-200">
                <div className="flex justify-between">
                  <span className="text-gray-600">Tạm tính:</span>
                  <span className="font-medium text-gray-800">{order.totalAmount?.toLocaleString('vi-VN')} đ</span>
                </div>
                {order.discountAmount > 0 && (
                  <div className="flex justify-between">
                    <span className="text-gray-600">Giảm giá {order.voucherCode ? `(${order.voucherCode})` : ''}:</span>
                    <span className="font-medium text-green-600">- {order.discountAmount.toLocaleString('vi-VN')} đ</span>
                  </div>
                )}
                <div className="flex justify-between border-t border-gray-200 pt-2 mt-2">
                  <span className="font-semibold text-gray-800">Tổng cộng:</span>
                  <span className="font-bold text-red-600 text-lg">{order.finalAmount?.toLocaleString('vi-VN')} đ</span>
                </div>
              </div>
            </div>
          </div>

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
                          <div className="text-sm text-gray-600 mt-1">{translateAuditDetails(log.details)}</div>
                        </div>
                        <div className="text-xs text-gray-500">
                          {new Date(log.timestamp).toLocaleDateString('vi-VN')} {new Date(log.timestamp).toLocaleTimeString('vi-VN')}
                        </div>
                      </div>
                      {log.oldValue && log.newValue && (
                        <div className="mt-2 text-sm text-gray-600">
                          <span className="text-red-600 line-through">{translateStatus(log.oldValue)}</span>
                          <span className="mx-2">→</span>
                          <span className="text-green-600 font-medium">{translateStatus(log.newValue)}</span>
                        </div>
                      )}
                    </div>
                  ))}
              </div>
            </div>
          )}

          <div className="flex justify-end pt-4 border-t">
            <button type="button" onClick={onClose} className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors shadow-sm">Đóng</button>
          </div>
        </div>
      </div>
    </div>
  );
}
;
