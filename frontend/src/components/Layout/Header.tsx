import React, { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { ShoppingCart, Heart, Search, ChevronDown } from 'lucide-react';
import { UserDropdown } from './UserDropdown';
import { useCart } from '../../contexts/CartContext';
import { adminApi } from '../../api/adminApi';
import type { Brand } from '../../types';

export const Header: React.FC = () => {
  const { isAuthenticated, isAdmin, isAdminOrStaff } = useAuth();
  const { cartCount } = useCart();
  const navigate = useNavigate();

  const [brands, setBrands] = useState<Brand[]>([]);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    const fetchBrands = async () => {
      try {
        const data = await adminApi.getBrands();
        setBrands(data || []);
      } catch (e) {}
    };
    fetchBrands();
  }, []);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    if (searchQuery.trim()) {
      navigate(`/?search=${encodeURIComponent(searchQuery.trim())}`);
    } else {
      navigate(`/`);
    }
  };

  return (
    <header className="bg-white shadow-sm sticky top-0 z-50">
      <div className="container mx-auto px-4 py-4 flex items-center justify-between">
        <Link to="/" className="text-2xl font-bold text-primary-600 mr-4">
          PhoneStore
        </Link>

        {/* Search Bar - added to middle */}
        <div className="flex-1 max-w-lg hidden md:block px-6">
          <form onSubmit={handleSearch} className="relative">
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Tìm kiếm điện thoại..."
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-full focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent transition-all"
            />
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
          </form>
        </div>

        <nav className="hidden lg:flex items-center space-x-6 mr-6">
          <Link to="/" className="text-gray-600 hover:text-primary-600 font-medium transition-colors">Trang chủ</Link>
          
          {/* Products Dropdown */}
          <div className="relative group">
            <button className="flex items-center text-gray-600 hover:text-primary-600 font-medium transition-colors py-2">
              Sản phẩm
              <ChevronDown className="ml-1 w-4 h-4 transition-transform group-hover:rotate-180" />
            </button>
            <div className="absolute top-full left-0 pt-2 w-48 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200">
              <div className="bg-white border rounded-lg shadow-xl overflow-hidden py-1">
                <Link to="/" className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 hover:text-primary-600">Tất cả sản phẩm</Link>
                {brands.map(brand => (
                  <Link 
                    key={brand.id} 
                    to={`/?brand=${brand.id}`} 
                    className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 hover:text-primary-600"
                  >
                    {brand.name}
                  </Link>
                ))}
              </div>
            </div>
          </div>
          
          <Link to="/promotions" className="text-gray-600 hover:text-primary-600 font-medium transition-colors">Khuyến mãi</Link>
          <Link to="/maps" className="text-gray-600 hover:text-primary-600 font-medium transition-colors">Bản đồ</Link>
        </nav>

        <div className="flex items-center space-x-6">
          {isAuthenticated && !isAdminOrStaff && (
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
              {isAdminOrStaff && (
                <Link to={isAdmin ? "/admin" : "/staff"} className="text-sm bg-blue-100 px-3 py-1 rounded-md text-blue-700 hover:bg-blue-200 font-medium transition">
                  {isAdmin ? "Quản trị viên" : "Nhân viên"}
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
