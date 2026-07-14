import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import axiosClient from '../../api/axiosClient';
import { cartApi } from '../../api/cartApi';
import { useAuth } from '../../contexts/AuthContext';
import { toast } from 'react-toastify';
import type { Product } from '../../types';

export const ProductDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { isAuthenticated } = useAuth();
  
  const [product, setProduct] = useState<Product | null>(null);
  const [loading, setLoading] = useState(true);
  
  // Static state for UI purposes
  const [selectedStorage, setSelectedStorage] = useState('256GB');
  const [selectedColor, setSelectedColor] = useState('Titan Tự Nhiên');

  useEffect(() => {
    const fetchProduct = async () => {
      try {
        const res: any = await axiosClient.get(`/products/${id}`);
        setProduct(res.data);
      } catch (error) {
        toast.error('Không thể tải thông tin sản phẩm');
      } finally {
        setLoading(false);
      }
    };
    if (id) fetchProduct();
  }, [id]);

  const handleAddToCart = async () => {
    if (!isAuthenticated) {
      toast.info('Vui lòng đăng nhập để mua hàng');
      navigate('/login');
      return;
    }
    try {
      await cartApi.addToCart(product!.id, 1);
      toast.success('Đã thêm sản phẩm vào giỏ hàng');
    } catch (error) {
      toast.error('Lỗi khi thêm vào giỏ hàng');
    }
  };

  const handleBuyNow = async () => {
    if (!isAuthenticated) {
      toast.info('Vui lòng đăng nhập để mua hàng');
      navigate('/login');
      return;
    }
    try {
      await cartApi.addToCart(product!.id, 1);
      navigate('/checkout');
    } catch (error) {
      toast.error('Lỗi khi thao tác');
    }
  };

  if (loading) return <div className="text-center py-20">Đang tải...</div>;
  if (!product) return <div className="text-center py-20 text-red-500">Sản phẩm không tồn tại.</div>;

  const isSale = product.salePrice > 0 && product.salePrice < product.price;
  const displayPrice = isSale ? product.salePrice : product.price;
  
  const formattedPrice = new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(displayPrice);
  const formattedOldPrice = new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(product.price);

  return (
    <div className="container mx-auto px-4 py-8 max-w-6xl font-sans">
      {/* Header Info */}
      <div className="mb-4 border-b pb-4">
        <h1 className="text-2xl font-bold text-gray-900">{product.name}</h1>
        <div className="flex items-center gap-4 mt-2 text-sm text-gray-600">
          <span className="flex items-center text-yellow-500">
            {'★'.repeat(Math.round(product.averageRating > 0 ? product.averageRating : 5))}
            {'☆'.repeat(5 - Math.round(product.averageRating > 0 ? product.averageRating : 5))}
            <span className="text-blue-600 ml-2">({product.totalReviews} đánh giá)</span>
          </span>
          <span>Thương hiệu: <span className="font-semibold text-blue-600">{product.brandName}</span></span>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-12 gap-8">
        {/* Left Column: Images */}
        <div className="md:col-span-5">
          <div className="bg-white rounded-xl border border-gray-200 p-4 shadow-sm mb-4">
            <img 
              src={product.images[0] || 'https://via.placeholder.com/500'} 
              alt={product.name} 
              className="w-full h-[400px] object-contain rounded-lg"
            />
          </div>
          <div className="flex gap-2 overflow-x-auto">
            {product.images.map((img, idx) => (
              <div key={idx} className="w-20 h-20 border-2 rounded-lg cursor-pointer hover:border-red-500 overflow-hidden flex-shrink-0 border-transparent">
                <img src={img} alt="thumbnail" className="w-full h-full object-cover" />
              </div>
            ))}
          </div>
        </div>

        {/* Right Column: Details & Actions */}
        <div className="md:col-span-7 space-y-6">
          {/* Price Box */}
          <div className="bg-red-50 rounded-xl p-4 border border-red-100 flex items-end gap-4">
            <span className="text-3xl font-bold text-red-600">{formattedPrice}</span>
            {isSale && <span className="text-lg text-gray-500 line-through mb-1">{formattedOldPrice}</span>}
          </div>

          {/* Fake Variants (Storage) */}
          <div>
            <p className="font-semibold mb-2">Chọn phiên bản (Mô phỏng):</p>
            <div className="grid grid-cols-3 gap-2">
              {['256GB', '512GB', '1TB'].map(storage => (
                <button 
                  key={storage}
                  onClick={() => setSelectedStorage(storage)}
                  className={`border py-2 px-1 rounded-lg text-sm font-medium transition-colors ${selectedStorage === storage ? 'border-red-500 text-red-600 bg-red-50' : 'border-gray-300 hover:border-red-300'}`}
                >
                  {storage}
                  <div className="text-xs text-gray-500">{formattedPrice}</div>
                </button>
              ))}
            </div>
          </div>

          {/* Fake Colors */}
          <div>
            <p className="font-semibold mb-2">Chọn màu sắc (Mô phỏng):</p>
            <div className="grid grid-cols-3 gap-2">
              {['Titan Tự Nhiên', 'Titan Trắng', 'Titan Đen'].map(color => (
                <button 
                  key={color}
                  onClick={() => setSelectedColor(color)}
                  className={`border py-2 px-1 rounded-lg text-sm font-medium transition-colors ${selectedColor === color ? 'border-red-500 text-red-600 bg-red-50' : 'border-gray-300 hover:border-red-300'}`}
                >
                  <div className="truncate">{color}</div>
                  <div className="text-xs text-gray-500">{formattedPrice}</div>
                </button>
              ))}
            </div>
          </div>

          {/* Promos */}
          <div className="border border-red-200 rounded-xl overflow-hidden mt-6">
            <div className="bg-red-100 px-4 py-2 text-red-700 font-bold flex items-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M5 2a1 1 0 011 1v1h1a1 1 0 010 2H6v1a1 1 0 01-2 0V6H3a1 1 0 010-2h1V3a1 1 0 011-1zm0 10a1 1 0 011 1v1h1a1 1 0 110 2H6v1a1 1 0 11-2 0v-1H3a1 1 0 110-2h1v-1a1 1 0 011-1zM12 2a1 1 0 01.967.744L14.146 7.2 17.5 9.134a1 1 0 010 1.732l-3.354 1.935-1.18 4.455a1 1 0 01-1.933 0L9.854 12.8 6.5 10.866a1 1 0 010-1.732l3.354-1.935 1.18-4.455A1 1 0 0112 2z" clipRule="evenodd" />
              </svg>
              Khuyến mãi đi kèm
            </div>
            <div className="p-4 bg-white text-sm space-y-3">
              <p>1. Tặng Voucher 500,000đ khi thu cũ đổi mới.</p>
              <p>2. Giảm 50% khi mua kèm phụ kiện (Ốp lưng, cáp sạc).</p>
              <p>3. Trả góp 0% lãi suất qua thẻ tín dụng.</p>
              <p className="text-gray-500 italic">*Khuyến mãi chỉ mang tính chất minh họa.</p>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="grid grid-cols-2 gap-4 mt-6">
            <button 
              onClick={handleBuyNow}
              className="col-span-2 bg-gradient-to-b from-red-500 to-red-600 hover:from-red-600 hover:to-red-700 text-white rounded-xl py-3 font-bold text-lg shadow-lg flex flex-col items-center"
            >
              <span>MUA NGAY</span>
              <span className="text-xs font-normal">Giao tận nơi hoặc nhận tại cửa hàng</span>
            </button>
            <button 
              onClick={handleAddToCart}
              className="border-2 border-red-500 text-red-600 hover:bg-red-50 rounded-xl py-3 font-bold text-sm shadow-sm flex flex-col items-center justify-center"
            >
              <span>THÊM VÀO GIỎ</span>
              <span className="text-xs font-normal">Thêm để mua sau</span>
            </button>
            <button 
              className="border-2 border-blue-500 text-blue-600 hover:bg-blue-50 rounded-xl py-3 font-bold text-sm shadow-sm flex flex-col items-center justify-center"
            >
              <span>MUA TRẢ GÓP 0%</span>
              <span className="text-xs font-normal">Qua thẻ tín dụng</span>
            </button>
          </div>

          {/* Product Description */}
          {product.description && (
             <div className="mt-8 border-t pt-6">
                <h2 className="text-xl font-bold mb-4">Mô tả sản phẩm</h2>
                <p className="text-gray-700 whitespace-pre-wrap leading-relaxed">{product.description}</p>
             </div>
          )}
        </div>
      </div>
    </div>
  );
};
