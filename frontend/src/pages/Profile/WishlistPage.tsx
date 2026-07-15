import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { wishlistApi } from '../../api/wishlistApi';
import { cartApi } from '../../api/cartApi';
import { useCart } from '../../contexts/CartContext';
import { useWishlist } from '../../contexts/WishlistContext';
import { toast } from 'react-toastify';

export const WishlistPage: React.FC = () => {
  const [items, setItems] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const { fetchCart } = useCart();
  const { removeFromWishlist } = useWishlist();

  const fetchWishlist = async () => {
    try {
      setLoading(true);
      const data: any = await wishlistApi.getWishlist();
      if (data && data.items) {
        setItems(data.items);
      }
    } catch (error) {
      console.error('Error fetching wishlist', error);
      toast.error('Không thể tải danh sách yêu thích');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchWishlist();
  }, []);

  const handleRemove = async (productId: string) => {
    try {
      await removeFromWishlist(productId);
      toast.success('Đã xoá khỏi danh sách yêu thích');
      setItems(items.filter(item => item.productId !== productId));
    } catch (error) {
      toast.error('Có lỗi xảy ra');
    }
  };

  const handleAddToCart = async (productId: string) => {
    try {
      await cartApi.addToCart(productId, 1);
      await fetchCart();
      toast.success('Đã thêm sản phẩm vào giỏ hàng');
    } catch (error) {
      toast.error('Lỗi khi thêm vào giỏ hàng');
    }
  };

  if (loading) {
    return <div className="text-center py-20 text-gray-500">Đang tải danh sách yêu thích...</div>;
  }

  return (
    <div className="container mx-auto px-4 py-8 max-w-6xl font-sans">
      <h1 className="text-3xl font-bold mb-8 text-gray-800">Danh sách yêu thích</h1>
      
      {items.length === 0 ? (
        <div className="bg-white p-10 rounded-xl shadow-sm border border-gray-200 text-center">
          <svg className="w-16 h-16 mx-auto text-red-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"></path></svg>
          <p className="text-gray-500 mb-6">Bạn chưa có sản phẩm nào trong danh sách yêu thích.</p>
          <Link to="/" className="bg-red-600 text-white px-6 py-2 rounded-lg font-medium hover:bg-red-700 transition">Khám phá ngay</Link>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {items.map(item => {
            const isSale = item.salePrice > 0 && item.salePrice < item.price;
            const displayPrice = isSale ? item.salePrice : item.price;
            const formattedPrice = new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(displayPrice);
            
            return (
              <div key={item.productId} className="bg-white border rounded-2xl overflow-hidden shadow-sm hover:shadow-lg transition flex flex-col">
                <Link to={`/products/${item.productId}`} className="relative h-48 bg-gray-50 p-4 block">
                  <img src={item.productImage || 'https://via.placeholder.com/200'} alt={item.productName} className="w-full h-full object-contain mix-blend-multiply hover:scale-105 transition-transform" />
                </Link>
                <div className="p-4 flex-1 flex flex-col">
                  <Link to={`/products/${item.productId}`} className="font-bold text-gray-800 line-clamp-2 hover:text-red-600 transition mb-2">
                    {item.productName}
                  </Link>
                  <p className="font-bold text-red-600 text-lg mb-4 mt-auto">{formattedPrice}</p>
                  
                  <div className="flex gap-2">
                    <button 
                      onClick={() => handleAddToCart(item.productId)}
                      disabled={!item.inStock}
                      className={`flex-1 py-2 rounded-lg font-medium text-sm transition ${item.inStock ? 'bg-gray-900 text-white hover:bg-red-600' : 'bg-gray-200 text-gray-500 cursor-not-allowed'}`}
                    >
                      {item.inStock ? 'Thêm vào giỏ' : 'Hết hàng'}
                    </button>
                    <button 
                      onClick={() => handleRemove(item.productId)}
                      className="w-10 h-10 flex items-center justify-center border border-red-200 text-red-500 hover:bg-red-50 rounded-lg transition bg-white"
                      title="Xoá khỏi danh sách"
                    >
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/></svg>
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
