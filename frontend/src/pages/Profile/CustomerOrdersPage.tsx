import React, { useEffect, useState, useCallback } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import axiosClient from '../../api/axiosClient';
import { toast } from 'react-toastify';
import type { Order } from '../../types';

export const CustomerOrdersPage: React.FC = () => {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const location = useLocation();
  const navigate = useNavigate();

  const fetchOrders = useCallback(async () => {
    try {
      setLoading(true);
      const res: any = await axiosClient.get('/orders?page=1&pageSize=50');
      if (res.data && res.data.items) {
        setOrders(res.data.items);
      }
    } catch (error) {
      toast.error('Không thể tải lịch sử đơn hàng');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    // Check if coming back from PayOS successfully
    const searchParams = new URLSearchParams(location.search);
    const code = searchParams.get('code');
    const orderCode = searchParams.get('orderCode');
    const cancel = searchParams.get('cancel');

    if (code === '00' && orderCode) {
      axiosClient.get(`/payment/check-status/${orderCode}`).then(() => {
        toast.success('Thanh toán thành công! Đơn hàng của bạn đã được cập nhật.', { toastId: 'payos-success' });
        fetchOrders();
      });
      window.history.replaceState({}, '', '/history');
    } else if (cancel === 'true') {
      toast.error('Bạn đã huỷ thanh toán đơn hàng.', { toastId: 'payos-cancel' });
      window.history.replaceState({}, '', '/history');
    } else if (location.state?.method === 'PayAtStore') {
      toast.success('Đặt hàng thành công! Đơn hàng của bạn đang được xử lý.', { toastId: 'pay-store' });
      // Remove state
      navigate('/history', { replace: true });
    }
  }, [location, navigate, fetchOrders]);

  useEffect(() => {
    const fetchOrders = async () => {
      try {
        setLoading(true);
        const res: any = await axiosClient.get('/orders?page=1&pageSize=50');
        if (res.data && res.data.items) {
          setOrders(res.data.items);
        }
      } catch (error) {
        toast.error('Không thể tải lịch sử đơn hàng');
      } finally {
        setLoading(false);
      }
    };
    fetchOrders();
  }, []);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Pending': return 'bg-yellow-100 text-yellow-800';
      case 'Confirmed': return 'bg-blue-100 text-blue-800';
      case 'Shipped': return 'bg-purple-100 text-purple-800';
      case 'Delivered': return 'bg-green-100 text-green-800';
      case 'Cancelled': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const handleCheckPaymentStatus = async (orderCode: number) => {
    try {
      const toastId = toast.loading('Đang kiểm tra trạng thái thanh toán từ PayOS...');
      const res: any = await axiosClient.get(`/payment/check-status/${orderCode}`);
      console.log('[CheckPayment] API response:', res);
      
      const responseData = res.data?.data;
      
      if (responseData?.paid === true) {
        toast.update(toastId, { render: 'Đã cập nhật trạng thái thanh toán thành công!', type: 'success', isLoading: false, autoClose: 3000 });
        fetchOrders();
      } else {
        const payosStatus = responseData?.payosStatus || 'unknown';
        const message = res.data?.message || 'Không rõ';
        toast.update(toastId, { render: `PayOS trạng thái: ${payosStatus} - ${message}`, type: 'warning', isLoading: false, autoClose: 5000 });
      }
    } catch (error: any) {
      toast.dismiss();
      const errorMsg = error?.response?.data?.message || error?.message || 'Lỗi không xác định';
      console.error('[CheckPayment] Error:', errorMsg, error?.response?.data);
      toast.error(`Lỗi kiểm tra: ${errorMsg}`, { autoClose: 8000 });
    }
  };

  const getPaymentStatusColor = (status: string) => {
    if (status === 'Paid') return 'bg-green-100 text-green-800 border-green-200';
    if (status === 'Unpaid') return 'bg-red-100 text-red-800 border-red-200';
    return 'bg-gray-100 text-gray-800 border-gray-200';
  };

  if (loading) return <div className="text-center py-20">Đang tải lịch sử mua hàng...</div>;

  return (
    <div className="container mx-auto px-4 py-8 max-w-5xl font-sans">
      <h1 className="text-3xl font-bold mb-8 text-gray-800">Lịch sử mua hàng</h1>
      
      {orders.length === 0 ? (
        <div className="bg-white p-10 rounded-xl shadow-sm border border-gray-200 text-center">
          <svg className="w-16 h-16 mx-auto text-gray-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"></path></svg>
          <p className="text-gray-500 mb-6">Bạn chưa có đơn hàng nào.</p>
          <button onClick={() => navigate('/')} className="bg-blue-600 text-white px-6 py-2 rounded-lg font-medium hover:bg-blue-700 transition">Tiếp tục mua sắm</button>
        </div>
      ) : (
        <div className="space-y-6">
          {orders.map((order) => (
            <div key={order.id} className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
              {/* Order Header */}
              <div className="bg-gray-50 px-6 py-4 border-b flex flex-wrap justify-between items-center gap-4">
                <div>
                  <p className="text-sm text-gray-500 font-medium">Mã Đơn Hàng</p>
                  <p className="font-bold text-gray-800">#{order.orderCode}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500 font-medium">Ngày Đặt</p>
                  <p className="font-semibold text-gray-800">{new Date(order.createdAt).toLocaleDateString('vi-VN')} {new Date(order.createdAt).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500 font-medium mb-1">Trạng Thái Đơn</p>
                  <span className={`px-3 py-1 rounded-full text-xs font-bold ${getStatusColor(order.status)}`}>
                    {order.status === 'Pending' ? 'Chờ xác nhận' : order.status === 'Confirmed' ? 'Đã xác nhận' : order.status === 'Shipped' ? 'Đang giao' : order.status === 'Delivered' ? 'Đã giao' : 'Đã huỷ'}
                  </span>
                </div>
                <div>
                  <p className="text-sm text-gray-500 font-medium mb-1">Thanh Toán</p>
                  <div className="flex flex-col gap-2 items-start">
                    <span className={`px-3 py-1 rounded-full text-xs font-bold border ${getPaymentStatusColor(order.paymentStatus)}`}>
                      {order.paymentStatus === 'Paid' ? 'Đã thanh toán' : 'Chưa thanh toán'}
                    </span>
                    {order.paymentStatus === 'Unpaid' && order.paymentMethod === 'PayOS' && (
                      <button 
                        onClick={() => handleCheckPaymentStatus(order.orderCode)}
                        className="text-xs bg-blue-50 hover:bg-blue-100 text-blue-700 font-semibold px-2 py-1 rounded transition-colors"
                      >
                        Kiểm tra thanh toán
                      </button>
                    )}
                  </div>
                </div>
              </div>

              {/* Order Items */}
              <div className="px-6 py-4">
                <div className="space-y-4">
                  {order.items.map((item, idx) => (
                    <div key={idx} className="flex gap-4 items-center">
                      <div className="w-20 h-20 border rounded-lg p-2 flex-shrink-0 bg-white">
                        <img src={item.productImage || 'https://via.placeholder.com/100'} alt={item.productName} className="w-full h-full object-contain" />
                      </div>
                      <div className="flex-1">
                        <h4 className="font-bold text-gray-800 line-clamp-1">{item.productName}</h4>
                        <div className="text-sm text-gray-500 mt-1">
                          {item.storage && <span className="mr-2">Dung lượng: {item.storage}</span>}
                          {item.color && <span>Màu: {item.color}</span>}
                        </div>
                        <p className="text-sm font-medium mt-1">x{item.quantity}</p>
                      </div>
                      <div className="font-bold text-red-600">
                        {new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(item.price * item.quantity)}
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Order Footer */}
              <div className="bg-gray-50 px-6 py-4 border-t flex flex-col sm:flex-row justify-between items-end sm:items-center gap-4">
                <div className="text-sm text-gray-500 max-w-sm">
                  <p><span className="font-medium text-gray-700">Người nhận:</span> {order.receiverName || order.userName} - {order.phone}</p>
                  <p><span className="font-medium text-gray-700">Địa chỉ:</span> {order.shippingAddress}</p>
                  {order.note && <p><span className="font-medium text-gray-700">Ghi chú:</span> {order.note}</p>}
                </div>
                <div className="text-right">
                  <p className="text-gray-500 text-sm mb-1">Phương thức: <span className="font-medium text-gray-700">{order.paymentMethod === 'PayOS' ? 'Chuyển khoản / Online' : 'Tiền mặt / Tại cửa hàng'}</span></p>
                  <p className="text-lg">Tổng tiền: <span className="text-2xl font-bold text-red-600">{new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(order.finalAmount)}</span></p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
