import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { toast } from 'react-toastify';
import type { Product } from '../../types';
import { cartApi } from '../../api/cartApi';
import { wishlistApi } from '../../api/wishlistApi';
import { useAuth } from '../../contexts/AuthContext';
import { useCart } from '../../contexts/CartContext';

interface ProductCardProps {
  product: Product;
}

const HeartIcon: React.FC<React.SVGProps<SVGSVGElement>> = (props) => (
  <svg width="1em" height="1em" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" {...props}>
    <path d="M20.8401 4.60999C20.3294 4.099 19.7229 3.69364 19.0554 3.41708C18.3879 3.14052 17.6725 2.99817 16.9501 2.99817C16.2277 2.99817 15.5122 3.14052 14.8447 3.41708C14.1772 3.69364 13.5707 4.099 13.0601 4.60999L12.0001 5.66999L10.9401 4.60999C9.90843 3.5783 8.50915 2.9987 7.05008 2.9987C5.59102 2.9987 4.19174 3.5783 3.16008 4.60999C2.12843 5.64166 1.54883 7.04094 1.54883 8.49999C1.54883 9.95905 2.12843 11.3583 3.16008 12.39L12.0001 21.23L20.8401 12.39C21.8717 11.3583 22.4513 9.95905 22.4513 8.49999C22.4513 7.04094 21.8717 5.64166 20.8401 4.60999Z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
  </svg>
);

const StarIcon: React.FC<React.SVGProps<SVGSVGElement>> = (props) => (
  <svg width="1em" height="1em" viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg" {...props}>
    <path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z" />
  </svg>
);

export const ProductCard: React.FC<ProductCardProps> = ({ product }) => {
  const navigate = useNavigate();
  const { isAuthenticated } = useAuth();
  const { fetchCart } = useCart();
  const [isWishlisted, setIsWishlisted] = React.useState(false);

  // Ideally, you'd check if the product is in the user's wishlist globally,
  // but for immediate feedback we use local state initially.
  
  const handleWishlist = async (e: React.MouseEvent) => {
    e.preventDefault();
    if (!isAuthenticated) {
      toast.info('Vui lòng đăng nhập để thêm vào danh sách yêu thích');
      navigate('/login');
      return;
    }
    
    try {
      if (isWishlisted) {
        await wishlistApi.removeFromWishlist(product.id);
        setIsWishlisted(false);
        toast.success('Đã xoá khỏi danh sách yêu thích');
      } else {
        await wishlistApi.addToWishlist(product.id);
        setIsWishlisted(true);
        toast.success('Đã thêm vào danh sách yêu thích');
      }
    } catch (error) {
      toast.error('Có lỗi xảy ra');
    }
  };
  
  const isSale = product.salePrice > 0 && product.salePrice < product.price;
  const displayPrice = isSale ? product.salePrice : product.price;
  const discountPercent = isSale ? Math.round((1 - product.salePrice / product.price) * 100) : 0;
  
  const formattedPrice = new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(displayPrice);
  const formattedOldPrice = new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(product.price);

  const handleAddToCart = async (e: React.MouseEvent) => {
    e.preventDefault(); // Prevent link navigation
    if (!isAuthenticated) {
      toast.info('Vui lòng đăng nhập để thêm vào giỏ hàng');
      navigate('/login');
      return;
    }
    
    try {
      await cartApi.addToCart(product.id, 1);
      await fetchCart();
      toast.success('Đã thêm sản phẩm vào giỏ hàng');
    } catch (error) {
      toast.error('Có lỗi xảy ra khi thêm vào giỏ hàng');
    }
  };

  return (
    <div className="relative group overflow-hidden rounded-2xl sm:rounded-3xl bg-white border border-gray-200 shadow-lg shadow-gray-200/50 transition-all duration-300 hover:shadow-xl hover:shadow-gray-300/50 hover:-translate-y-1 hover:border-blue-300 w-full font-space-grotesk flex flex-col h-full">
      <Link to={`/products/${product.id}`} className="block relative p-3 sm:p-4 flex-1">
          {/* Card Image Section */}
          <div className="relative h-48 sm:h-56 bg-gray-50 rounded-xl sm:rounded-2xl flex items-center justify-center p-4 overflow-hidden">
            <img 
              src={product.images[0] || 'https://via.placeholder.com/350'} 
              alt={product.name} 
              className="w-full h-full object-contain mix-blend-multiply group-hover:scale-110 transition-transform duration-500 ease-in-out" 
            />

            {/* Overlays */}
            {isSale && (
                <div className="absolute top-2 left-2 sm:top-3 sm:left-3 bg-red-500/90 text-white text-xs sm:text-sm font-bold px-2.5 py-1 sm:px-3 sm:py-1.5 rounded-full flex items-center space-x-1 sm:space-x-2 backdrop-blur-md border border-red-400 shadow-sm">
                    <span>-{discountPercent}%</span>
                </div>
            )}

            <button 
              className={`absolute top-2 right-2 sm:top-3 sm:right-3 p-1.5 sm:p-2.5 rounded-full transition-colors backdrop-blur-md border border-gray-200 shadow-sm z-10 ${isWishlisted ? 'bg-red-500 text-white border-red-500' : 'bg-white/70 text-gray-600 hover:text-red-500 hover:bg-white'}`}
              onClick={handleWishlist}
            >
              <HeartIcon className="w-4 h-4 sm:w-5 sm:h-5" />
            </button>
          </div>

          {/* Card Content Section */}
          <div className="mt-4 sm:mt-5 px-1 pb-1">
            <div className="flex justify-between items-start gap-2">
                <h3 className="text-base sm:text-lg font-bold text-gray-900 truncate" title={product.name}>{product.name}</h3>
                <div className="flex items-center gap-1 bg-amber-50 text-amber-500 px-1.5 py-0.5 rounded-md text-xs font-bold border border-amber-100 shrink-0">
                  <StarIcon className="w-3 h-3" />
                  {product.averageRating > 0 ? product.averageRating.toFixed(1) : '5.0'}
                </div>
            </div>

            <p className="text-xs sm:text-sm text-gray-500 mt-1 font-medium">{product.brandName}</p>

            <div className="mt-3 sm:mt-4 flex flex-col justify-end min-h-[44px]">
              {isSale ? (
                <div className="flex items-baseline gap-2">
                  <p className="text-sm sm:text-lg font-bold text-blue-600">{formattedPrice}</p>
                  <p className="text-xs sm:text-sm text-gray-400 line-through">{formattedOldPrice}</p>
                </div>
              ) : (
                <p className="text-sm sm:text-lg font-bold text-blue-600">{formattedPrice}</p>
              )}
            </div>
          </div>
      </Link>
      
      <div className="px-4 pb-4 sm:px-5 sm:pb-5">
        <button 
          onClick={handleAddToCart}
          className="w-full py-2.5 bg-gray-900 hover:bg-blue-600 text-white text-sm font-semibold rounded-xl transition-colors shadow-md group-hover:shadow-lg"
        >
          Thêm vào giỏ
        </button>
      </div>
    </div>
  );
};
