import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axiosClient from '../../api/axiosClient';
import { cartApi } from '../../api/cartApi';
import { useCart } from '../../contexts/CartContext';
import { LoadingSpinner } from '../../components/ui/LoadingSpinner';
import { toast } from 'react-toastify';

interface CartItem {
  productId: string;
  productName: string;
  productImage: string;
  quantity: number;
  price: number;
  salePrice: number;
  storage?: string;
  color?: string;
}

export const CheckoutPage: React.FC = () => {
  const navigate = useNavigate();
  const [cartItems, setCartItems] = useState<CartItem[]>([]);
  const [loadingCart, setLoadingCart] = useState(true);
  const { fetchCart: globalFetchCart } = useCart();
  
  const [formData, setFormData] = useState({
    receiverName: '',
    phone: '',
    shippingAddress: '',
    note: '',
    paymentMethod: 'PayAtStore'
  });
  
  const [deliveryMethod, setDeliveryMethod] = useState<'Home' | 'Store'>('Home');
  const [voucherCode, setVoucherCode] = useState('');
  const [appliedVoucher, setAppliedVoucher] = useState<any>(null);
  
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const fetchCart = async () => {
      try {
        const data = await cartApi.getCart();
        if (data && data.items) {
           setCartItems(data.items);
        }
      } catch (error) {
        toast.error('Lỗi tải giỏ hàng');
      } finally {
        setLoadingCart(false);
      }
    };
    fetchCart();
  }, []);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleApplyVoucher = async () => {
    if (!voucherCode) return;
    try {
      const res = await axiosClient.get(`/vouchers/code/${voucherCode}`);
      if (res.data?.data) {
        setAppliedVoucher(res.data.data);
        toast.success('Áp dụng mã giảm giá thành công!');
      }
    } catch (error) {
      toast.error('Mã giảm giá không hợp lệ hoặc đã hết hạn');
      setAppliedVoucher(null);
    }
  };

  const totalAmount = cartItems.reduce((sum, item) => sum + item.salePrice * item.quantity, 0);
  
  let discountAmount = 0;
  if (appliedVoucher && totalAmount >= appliedVoucher.minOrderAmount) {
    if (appliedVoucher.discountType === 'Percentage') {
      discountAmount = (totalAmount * appliedVoucher.discountValue) / 100;
      if (appliedVoucher.maxDiscount > 0 && discountAmount > appliedVoucher.maxDiscount) {
        discountAmount = appliedVoucher.maxDiscount;
      }
    } else {
      discountAmount = appliedVoucher.discountValue;
    }
  }

  const finalAmount = totalAmount - discountAmount;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (cartItems.length === 0) {
      toast.warning('Giỏ hàng trống');
      return;
    }

    setLoading(true);
    try {
      const payload = {
        ...formData,
        shippingAddress: deliveryMethod === 'Store' ? 'Nhận tại cửa hàng' : formData.shippingAddress,
        voucherCode: appliedVoucher ? appliedVoucher.code : null
      };

      // 1. Create Order
      const orderResponse: any = await axiosClient.post('/orders', payload);
      const order = orderResponse.data;
      
      if (!order) throw new Error("Order creation failed");

      // Cart is cleared in backend, so update frontend context
      await globalFetchCart();

      if (formData.paymentMethod === 'PayOS') {
        // 2. Generate PayOS Link
        const paymentResponse: any = await axiosClient.post(`/payment/create-link/${order.id}?returnUrl=${window.location.origin}/history&cancelUrl=${window.location.origin}/history`);
        const checkoutUrl = paymentResponse.data;
        if (checkoutUrl) {
          window.location.href = checkoutUrl;
        } else {
          toast.error('Không thể tạo link thanh toán PayOS');
        }
      } else {
        // Redirect to success page for PayAtStore
        navigate('/history', { state: { orderId: order.id, method: 'PayAtStore' } });
      }
    } catch (error) {
      console.error('Checkout error:', error);
      toast.error('Có lỗi xảy ra khi đặt hàng.');
    } finally {
      setLoading(false);
    }
  };

  if (loadingCart) return <LoadingSpinner fullScreen />;

  return (
    <div className="container mx-auto px-4 py-8 max-w-6xl font-sans">
      <h1 className="text-3xl font-bold mb-8">Thanh toán & Đặt hàng</h1>
      
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
        
        {/* Left Column: Form */}
        <div className="lg:col-span-7 space-y-6">
          <form id="checkout-form" onSubmit={handleSubmit} className="bg-white p-6 rounded-xl shadow-sm border border-gray-200 space-y-6">
            
            <div className="border-b pb-4">
              <h2 className="text-xl font-bold mb-4">Thông tin khách hàng</h2>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Tên người nhận</label>
                  <input required type="text" name="receiverName" value={formData.receiverName} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none" placeholder="Nhập họ tên" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Số điện thoại</label>
                  <input required type="text" name="phone" value={formData.phone} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none" placeholder="Nhập số điện thoại" />
                </div>
              </div>
            </div>

            <div className="border-b pb-4">
              <h2 className="text-xl font-bold mb-4">Hình thức nhận hàng</h2>
              <div className="flex gap-4 mb-4">
                <label className={`flex-1 flex items-center justify-center p-3 border rounded-lg cursor-pointer transition ${deliveryMethod === 'Home' ? 'border-red-500 bg-red-50 text-red-600 font-medium' : 'hover:bg-gray-50'}`}>
                  <input type="radio" name="delivery" value="Home" checked={deliveryMethod === 'Home'} onChange={() => setDeliveryMethod('Home')} className="hidden" />
                  Giao hàng tận nơi
                </label>
                <label className={`flex-1 flex items-center justify-center p-3 border rounded-lg cursor-pointer transition ${deliveryMethod === 'Store' ? 'border-red-500 bg-red-50 text-red-600 font-medium' : 'hover:bg-gray-50'}`}>
                  <input type="radio" name="delivery" value="Store" checked={deliveryMethod === 'Store'} onChange={() => setDeliveryMethod('Store')} className="hidden" />
                  Nhận tại cửa hàng
                </label>
              </div>

              {deliveryMethod === 'Home' && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Địa chỉ giao hàng</label>
                  <input required type="text" name="shippingAddress" value={formData.shippingAddress} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none" placeholder="Số nhà, đường, phường/xã, quận/huyện, tỉnh/thành" />
                </div>
              )}
            </div>

            <div className="border-b pb-4">
               <label className="block text-sm font-medium text-gray-700 mb-1">Ghi chú đơn hàng (Tuỳ chọn)</label>
               <textarea name="note" value={formData.note} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none" placeholder="Ghi chú thêm về đơn hàng..."></textarea>
            </div>

            <div>
              <h2 className="text-xl font-bold mb-4">Phương thức thanh toán</h2>
              <div className="space-y-3">
                <label className={`flex items-center p-4 border rounded-xl cursor-pointer transition ${formData.paymentMethod === 'PayAtStore' ? 'border-red-500 bg-red-50' : 'hover:bg-gray-50'}`}>
                  <input type="radio" name="paymentMethod" value="PayAtStore" checked={formData.paymentMethod === 'PayAtStore'} onChange={handleChange} className="w-5 h-5 text-red-600 accent-red-600" />
                  <div className="ml-4">
                    <span className="block font-bold">Thanh toán khi nhận hàng / Tại cửa hàng</span>
                    <span className="text-sm text-gray-500">Thanh toán bằng tiền mặt hoặc quét mã QR tĩnh.</span>
                  </div>
                </label>
                <label className={`flex items-center p-4 border rounded-xl cursor-pointer transition ${formData.paymentMethod === 'PayOS' ? 'border-red-500 bg-red-50' : 'hover:bg-gray-50'}`}>
                  <input type="radio" name="paymentMethod" value="PayOS" checked={formData.paymentMethod === 'PayOS'} onChange={handleChange} className="w-5 h-5 text-red-600 accent-red-600" />
                  <div className="ml-4">
                    <span className="block font-bold">Thanh toán Online (PayOS)</span>
                    <span className="text-sm text-gray-500">Thanh toán an toàn qua thẻ ATM, Visa, MasterCard hoặc chuyển khoản QR.</span>
                  </div>
                </label>
              </div>
            </div>

          </form>
        </div>

        {/* Right Column: Order Summary */}
        <div className="lg:col-span-5 space-y-6">
          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
            <h2 className="text-xl font-bold mb-4">Đơn hàng của bạn</h2>
            
            <div className="max-h-60 overflow-y-auto space-y-4 mb-4 pr-2">
              {cartItems.map((item, idx) => (
                <div key={idx} className="flex gap-4">
                   <div className="w-16 h-16 border rounded-lg overflow-hidden flex-shrink-0 p-1">
                      <img src={item.productImage || 'https://via.placeholder.com/100'} alt={item.productName} className="w-full h-full object-contain" />
                   </div>
                   <div className="flex-1">
                      <h4 className="font-semibold text-sm line-clamp-2">{item.productName}</h4>
                      <div className="text-xs text-gray-500 mb-1">
                        {item.storage && <span className="mr-2">{item.storage}</span>}
                        {item.color && <span>- {item.color}</span>}
                      </div>
                      <p className="text-xs text-gray-500">Số lượng: {item.quantity}</p>
                   </div>
                   <div className="font-bold text-sm">
                      {new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(item.salePrice * item.quantity)}
                   </div>
                </div>
              ))}
            </div>

            <div className="border-t pt-4 mb-4">
               <label className="block text-sm font-medium text-gray-700 mb-2">Mã giảm giá / Voucher</label>
               <div className="flex gap-2">
                  <input 
                    type="text" 
                    value={voucherCode} 
                    onChange={e => setVoucherCode(e.target.value)} 
                    className="flex-1 px-4 py-2 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none" 
                    placeholder="Nhập mã giảm giá..." 
                  />
                  <button onClick={handleApplyVoucher} type="button" className="bg-gray-900 text-white px-4 py-2 rounded-lg hover:bg-gray-800 font-semibold transition">Áp dụng</button>
               </div>
               {appliedVoucher && (
                 <div className="mt-2 text-sm text-green-600 font-medium bg-green-50 p-2 rounded flex justify-between">
                   <span>Đã áp dụng mã: {appliedVoucher.code}</span>
                   <button onClick={() => { setAppliedVoucher(null); setVoucherCode(''); }} className="text-red-500 hover:text-red-700 text-xs">Xoá</button>
                 </div>
               )}
            </div>

            <div className="border-t pt-4 space-y-2">
              <div className="flex justify-between text-gray-600">
                <span>Tạm tính:</span>
                <span>{new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(totalAmount)}</span>
              </div>
              <div className="flex justify-between text-gray-600">
                <span>Phí vận chuyển:</span>
                <span>Miễn phí</span>
              </div>
              {discountAmount > 0 && (
                <div className="flex justify-between text-green-600 font-medium">
                  <span>Giảm giá:</span>
                  <span>-{new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(discountAmount)}</span>
                </div>
              )}
              <div className="flex justify-between text-xl font-bold text-red-600 mt-2 pt-2 border-t">
                <span>Tổng cộng:</span>
                <span>{new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(finalAmount)}</span>
              </div>
            </div>

            <button 
              form="checkout-form"
              disabled={loading} 
              type="submit" 
              className={`w-full mt-6 py-3.5 rounded-xl font-bold text-white text-lg transition duration-300 ${loading ? 'bg-gray-400 cursor-not-allowed' : 'bg-red-600 hover:bg-red-700 shadow-md hover:shadow-lg'}`}
            >
              {loading ? 'Đang xử lý...' : 'ĐẶT HÀNG NGAY'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};


