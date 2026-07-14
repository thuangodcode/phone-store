import React, { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import axiosClient from '../../api/axiosClient';
import { cartApi } from '../../api/cartApi';

interface CartItem {
  productId: string;
  productName: string;
  productImage: string;
  quantity: number;
  price: number;
  storage?: string;
  color?: string;
}

interface Cart {
  items: CartItem[];
}

export const CartPage: React.FC = () => {
  const [cart, setCart] = useState<Cart | null>(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  const fetchCart = async () => {
    try {
      const response: any = await axiosClient.get('/cart');
      setCart(response.data || { items: [] });
    } catch (error) {
      console.error('Failed to fetch cart', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCart();
  }, []);

  const updateQuantity = async (productId: string, quantity: number, storage?: string, color?: string) => {
    try {
      await cartApi.updateCartItem(productId, quantity, storage, color);
      fetchCart();
    } catch (error) {
      console.error('Failed to update quantity', error);
    }
  };

  const removeFromCart = async (productId: string, storage?: string, color?: string) => {
    try {
      // Use update with 0 quantity to remove specific variant
      await cartApi.updateCartItem(productId, 0, storage, color);
      fetchCart();
    } catch (error) {
      console.error('Failed to remove item', error);
    }
  };

  if (loading) {
    return <div className="container mx-auto px-4 py-8 text-center">Loading cart...</div>;
  }

  const items = cart?.items || [];
  const totalAmount = items.reduce((sum, item) => sum + item.price * item.quantity, 0);

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">Giỏ hàng của bạn</h1>
      
      {items.length === 0 ? (
        <div className="text-center py-12">
          <p className="text-gray-500 mb-4">Giỏ hàng đang trống.</p>
          <Link to="/" className="text-blue-600 hover:underline">Tiếp tục mua sắm</Link>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2 space-y-4">
            {items.map(item => (
              <div key={`${item.productId}-${item.storage}-${item.color}`} className="flex flex-col sm:flex-row items-center bg-white p-4 rounded-xl shadow-sm border border-gray-100 gap-4">
                <img src={item.productImage || 'https://via.placeholder.com/150'} alt={item.productName} className="w-24 h-24 object-contain" />
                <div className="flex-1 text-center sm:text-left">
                  <h3 className="font-semibold text-lg">{item.productName}</h3>
                  <div className="text-sm text-gray-500 mb-1">
                    {item.storage && <span className="mr-3">Dung lượng: {item.storage}</span>}
                    {item.color && <span>Màu sắc: {item.color}</span>}
                  </div>
                  <p className="text-red-600 font-bold">{new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(item.price)}</p>
                </div>
                <div className="flex items-center gap-2">
                  <button onClick={() => updateQuantity(item.productId, item.quantity - 1, item.storage, item.color)} className="w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center hover:bg-gray-200">-</button>
                  <span className="w-8 text-center font-semibold">{item.quantity}</span>
                  <button onClick={() => updateQuantity(item.productId, item.quantity + 1, item.storage, item.color)} className="w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center hover:bg-gray-200">+</button>
                </div>
                <button onClick={() => removeFromCart(item.productId, item.storage, item.color)} className="text-red-500 hover:text-red-700 font-medium">Xoá</button>
              </div>
            ))}
          </div>
          
          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 h-fit">
            <h2 className="text-xl font-bold mb-4">Tổng quan đơn hàng</h2>
            <div className="flex justify-between mb-4">
              <span className="text-gray-600">Tổng tiền:</span>
              <span className="font-bold text-xl text-red-600">{new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(totalAmount)}</span>
            </div>
            <button 
              onClick={() => navigate('/checkout')}
              className="w-full bg-blue-600 text-white font-bold py-3 rounded-xl hover:bg-blue-700 transition duration-300"
            >
              Tiến hành thanh toán
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
