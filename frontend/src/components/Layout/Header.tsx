import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { ShoppingCart, Heart } from 'lucide-react';
import { UserDropdown } from './UserDropdown';
import { useCart } from '../../contexts/CartContext';

export const Header: React.FC = () => {
  const { isAuthenticated, isAdmin } = useAuth();
  const { cartCount } = useCart();

  return (
    <header className="bg-white shadow-sm sticky top-0 z-50">
      <div className="container mx-auto px-4 py-4 flex items-center justify-between">
        <Link to="/" className="text-2xl font-bold text-primary-600">
          PhoneStore
        </Link>

        <nav className="hidden md:flex space-x-8">
          <Link to="/" className="text-gray-600 hover:text-primary-600 font-medium transition-colors">Trang chủ</Link>
          <Link to="/products" className="text-gray-600 hover:text-primary-600 font-medium transition-colors">Sản phẩm</Link>
          <Link to="/promotions" className="text-gray-600 hover:text-primary-600 font-medium transition-colors">Khuyến mãi</Link>
          <Link to="/maps" className="text-gray-600 hover:text-primary-600 font-medium transition-colors">Bản đồ</Link>
        </nav>

        <div className="flex items-center space-x-6">
          {isAuthenticated && (
            <>
              <Link to="/wishlist" className="text-gray-600 hover:text-primary-600 relative">
                <Heart size={24} />
              </Link>
              <Link to="/cart" className="text-gray-600 hover:text-primary-600 relative">
                <ShoppingCart size={24} />
                <span className="absolute -top-2 -right-2 bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">{cartCount}</span>
              </Link>
            </>
          )}

          {isAuthenticated ? (
            <div className="flex items-center space-x-4">
              {isAdmin && (
                <Link to="/admin" className="text-sm bg-blue-100 px-3 py-1 rounded-md text-blue-700 hover:bg-blue-200 font-medium transition">
                  Quản trị viên
                </Link>
              )}
              <UserDropdown />
            </div>
          ) : (
            <Link to="/login" className="bg-primary-600 text-white px-5 py-2 rounded-lg font-medium hover:bg-primary-700 transition">
              Đăng nhập
            </Link>
          )}
        </div>
      </div>
    </header>
  );
};
