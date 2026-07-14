import React, { useState, useRef, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { ShoppingCart, Heart, LogOut, User, ClipboardList } from 'lucide-react';

export const UserDropdown: React.FC = () => {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  // Get last name from full name
  const getLastName = () => {
    if (!user?.fullName) return 'User';
    const parts = user.fullName.split(' ');
    return parts[parts.length - 1];
  };

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleLogout = () => {
    logout();
    setIsOpen(false);
    navigate('/');
  };

  const handleNavigation = (path: string) => {
    navigate(path);
    setIsOpen(false);
  };

  return (
    <div className="relative" ref={dropdownRef}>
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 px-4 py-2 rounded-lg bg-gray-100 hover:bg-gray-200 text-gray-700 font-medium transition-colors"
      >
        <span className="text-sm">Hi {getLastName()}</span>
        <svg
          className={`w-4 h-4 transition-transform ${isOpen ? 'rotate-180' : ''}`}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 14l-7 7m0 0l-7-7m7 7V3" />
        </svg>
      </button>

      {isOpen && (
        <div className="absolute right-0 mt-2 w-56 bg-white rounded-lg shadow-lg border border-gray-200 z-50">
          <div className="p-4 border-b border-gray-200">
            <p className="font-semibold text-gray-900">{user?.fullName}</p>
            <p className="text-sm text-gray-600">{user?.email}</p>
          </div>

          <div className="py-2">
            <button
              onClick={() => handleNavigation('/profile')}
              className="w-full px-4 py-2 text-left flex items-center gap-3 hover:bg-gray-50 text-gray-700 font-medium transition-colors"
            >
              <User size={18} />
              <span>Hồ sơ</span>
            </button>

            <button
              onClick={() => handleNavigation('/history')}
              className="w-full px-4 py-2 text-left flex items-center gap-3 hover:bg-gray-50 text-gray-700 font-medium transition-colors"
            >
              <ClipboardList size={18} />
              <span>Lịch sử mua hàng</span>
            </button>

            <button
              onClick={() => handleNavigation('/wishlist')}
              className="w-full px-4 py-2 text-left flex items-center gap-3 hover:bg-gray-50 text-gray-700 font-medium transition-colors"
            >
              <Heart size={18} />
              <span>Danh sách yêu thích</span>
            </button>

            <button
              onClick={() => handleNavigation('/cart')}
              className="w-full px-4 py-2 text-left flex items-center gap-3 hover:bg-gray-50 text-gray-700 font-medium transition-colors"
            >
              <ShoppingCart size={18} />
              <span>Giỏ hàng</span>
            </button>

            <div className="border-t border-gray-200 mt-2 pt-2">
              <button
                onClick={handleLogout}
                className="w-full px-4 py-2 text-left flex items-center gap-3 hover:bg-red-50 text-red-600 font-medium transition-colors"
              >
                <LogOut size={18} />
                <span>Đăng xuất</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
