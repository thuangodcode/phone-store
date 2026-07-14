import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import axiosClient from '../../api/axiosClient';

export const CheckoutPage: React.FC = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    receiverName: '',
    phone: '',
    shippingAddress: '',
    note: '',
    paymentMethod: 'PayAtStore'
  });
  const [loading, setLoading] = useState(false);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      // 1. Create Order
      const orderResponse = await axiosClient.post('/orders', formData);
      const order = orderResponse.data?.data;
      
      if (!order) throw new Error("Order creation failed");

      if (formData.paymentMethod === 'PayOS') {
        // 2. Generate PayOS Link
        const paymentResponse = await axiosClient.post(`/payment/create-link/${order.id}?returnUrl=${window.location.origin}/payment-success&cancelUrl=${window.location.origin}/payment-cancel`);
        const checkoutUrl = paymentResponse.data?.data;
        if (checkoutUrl) {
          window.location.href = checkoutUrl;
        } else {
          alert('Không thể tạo link thanh toán');
        }
      } else {
        // Redirect to success page for PayAtStore
        navigate('/payment-success', { state: { orderId: order.id, method: 'PayAtStore' } });
      }
    } catch (error) {
      console.error('Checkout error:', error);
      alert('Có lỗi xảy ra khi đặt hàng.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container mx-auto px-4 py-8 max-w-3xl">
      <h1 className="text-3xl font-bold mb-8 text-center">Thanh toán & Đặt hàng</h1>
      
      <form onSubmit={handleSubmit} className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 space-y-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Tên người nhận</label>
          <input required type="text" name="receiverName" value={formData.receiverName} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500" placeholder="Nhập họ tên" />
        </div>
        
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Số điện thoại</label>
          <input required type="text" name="phone" value={formData.phone} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500" placeholder="Nhập số điện thoại" />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Địa chỉ giao hàng</label>
          <input required type="text" name="shippingAddress" value={formData.shippingAddress} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500" placeholder="Số nhà, đường, phường/xã, quận/huyện, tỉnh/thành" />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Ghi chú (Tuỳ chọn)</label>
          <textarea name="note" value={formData.note} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500" placeholder="Ghi chú thêm về đơn hàng..."></textarea>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Phương thức thanh toán</label>
          <div className="space-y-3">
            <label className="flex items-center p-3 border rounded-lg cursor-pointer hover:bg-gray-50 transition">
              <input type="radio" name="paymentMethod" value="PayAtStore" checked={formData.paymentMethod === 'PayAtStore'} onChange={handleChange} className="w-4 h-4 text-blue-600" />
              <span className="ml-3 font-medium">Thanh toán tại cửa hàng (Tiền mặt / Quét mã QR)</span>
            </label>
            <label className="flex items-center p-3 border rounded-lg cursor-pointer hover:bg-gray-50 transition">
              <input type="radio" name="paymentMethod" value="PayOS" checked={formData.paymentMethod === 'PayOS'} onChange={handleChange} className="w-4 h-4 text-blue-600" />
              <span className="ml-3 font-medium">Thanh toán Online an toàn qua PayOS (Thẻ / Chuyển khoản)</span>
            </label>
          </div>
        </div>

        <button disabled={loading} type="submit" className={`w-full py-3 rounded-xl font-bold text-white transition duration-300 ${loading ? 'bg-gray-400 cursor-not-allowed' : 'bg-blue-600 hover:bg-blue-700 shadow-md hover:shadow-lg'}`}>
          {loading ? 'Đang xử lý...' : 'Xác nhận Đặt hàng'}
        </button>
      </form>
    </div>
  );
};
