import React, { useEffect, useState } from 'react';
import { adminApi } from '../../../api/adminApi';
import type { Order } from '../../../types';
import { OrderStatusModal } from './OrderStatusModal';
import { ActionButton, RefreshIcon } from '../../../components/AdminActionButtons';
import { toast } from 'react-toastify';

export const AdminOrdersPage: React.FC = () => {
  const [orders, setOrders] = useState<Order[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);

  const fetchOrders = async () => {
    try {
      setIsLoading(true);
      const data = await adminApi.getOrders();
      setOrders(data);
    } catch (error) {
      toast.error('Failed to fetch orders');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders();
  }, []);

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

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Manage Orders</h1>
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-200">
                <th className="p-4 font-medium text-gray-600">Order</th>
                <th className="p-4 font-medium text-gray-600">Customer</th>
                <th className="p-4 font-medium text-gray-600">Total</th>
                <th className="p-4 font-medium text-gray-600">Status</th>
                <th className="p-4 font-medium text-gray-600">Payment</th>
                <th className="p-4 font-medium text-gray-600">Date</th>
                <th className="p-4 font-medium text-gray-600 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {isLoading ? (
                <tr><td colSpan={6} className="p-8 text-center text-gray-500">Loading orders...</td></tr>
              ) : orders.length === 0 ? (
                <tr><td colSpan={6} className="p-8 text-center text-gray-500">No orders found.</td></tr>
              ) : (
                orders.map((order) => (
                  <tr key={order.id} className="hover:bg-gray-50">
                    <td className="p-4">
                      <div className="font-medium text-gray-900">#{order.id.slice(0, 8)}</div>
                      <div className="text-sm text-gray-500">{order.paymentMethod}</div>
                    </td>
                    <td className="p-4">
                      <div className="font-medium text-gray-900">{order.receiverName}</div>
                      <div className="text-sm text-gray-500">{order.phone}</div>
                    </td>
                    <td className="p-4 text-gray-600">${order.finalAmount.toLocaleString()}</td>
                    <td className="p-4">
                      <span className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${order.status === 'Delivered' ? 'bg-green-100 text-green-700' : order.status === 'Cancelled' ? 'bg-red-100 text-red-700' : 'bg-yellow-100 text-yellow-700'}`}>
                        {order.status}
                      </span>
                    </td>
                    <td className="p-4">
                      <span className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${order.paymentStatus === 'Paid' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-700'}`}>
                        {order.paymentStatus}
                      </span>
                    </td>
                    <td className="p-4 text-gray-600">{new Date(order.createdAt).toLocaleDateString()}</td>
                    <td className="p-4 text-right">
                      <div className="flex justify-end gap-2">
                        {order.paymentStatus !== 'Paid' && (
                           <ActionButton label="Mark Paid" onClick={() => handlePaymentConfirm(order.id)} icon={<RefreshIcon />} variant="secondary" />
                        )}
                        <ActionButton label="Update Status" onClick={() => handleStatusChange(order)} icon={<RefreshIcon />} variant="primary" />
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <OrderStatusModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} order={selectedOrder} onSuccess={fetchOrders} />
    </div>
  );
};
