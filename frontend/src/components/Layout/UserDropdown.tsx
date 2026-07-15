import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { ShoppingCart, Heart, LogOut, User, ClipboardList, ChevronDown } from 'lucide-react';
import { DropdownMenu, DropdownMenuItem, DropdownMenuSeparator } from './DropdownMenu';

export const UserDropdown: React.FC = () => {
  const { user, logout, isAdminOrStaff, isAdmin } = useAuth();
  const navigate = useNavigate();

  // Get last name from full name
  const getLastName = () => {
    if (!user?.fullName) return 'User';
    const parts = user.fullName.split(' ');
    return parts[parts.length - 1];
  };

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  const handleNavigation = (path: string) => {
    navigate(path);
  };

  return (
    <DropdownMenu
      trigger={
        <button className="flex items-center gap-2 px-4 py-2 rounded-lg bg-gray-100 hover:bg-gray-200 text-gray-700 font-medium transition-colors">
          <span className="text-sm">Chào {getLastName()}</span>
          <ChevronDown size={16} />
        </button>
      }
    >
      <div className="px-3 py-3">
        <p className="font-semibold text-gray-900">{user?.fullName}</p>
        <p className="text-sm text-gray-600">{user?.email}</p>
      </div>
      <DropdownMenuSeparator />
      <div className="flex flex-col space-y-1">
        <DropdownMenuItem onClick={() => handleNavigation('/profile')}>
          <User className="mr-3 h-5 w-5 text-zinc-500" />
          <span>Hồ sơ cá nhân</span>
        </DropdownMenuItem>
        
        {isAdminOrStaff ? (
          <DropdownMenuItem onClick={() => handleNavigation(isAdmin ? '/admin' : '/staff')}>
            <ClipboardList className="mr-3 h-5 w-5 text-zinc-500" />
            <span>Bảng điều khiển</span>
          </DropdownMenuItem>
        ) : (
          <>
            <DropdownMenuItem onClick={() => handleNavigation('/history')}>
              <ClipboardList className="mr-3 h-5 w-5 text-zinc-500" />
              <span>Lịch sử mua hàng</span>
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => handleNavigation('/wishlist')}>
              <Heart className="mr-3 h-5 w-5 text-zinc-500" />
              <span>Danh sách yêu thích</span>
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => handleNavigation('/cart')}>
              <ShoppingCart className="mr-3 h-5 w-5 text-zinc-500" />
              <span>Giỏ hàng</span>
            </DropdownMenuItem>
          </>
        )}
      </div>
      <DropdownMenuSeparator />
      <div className="flex flex-col space-y-1">
        <DropdownMenuItem onClick={handleLogout} danger={true}>
          <LogOut className="mr-3 h-5 w-5" />
          <span>Đăng xuất</span>
        </DropdownMenuItem>
      </div>
    </DropdownMenu>
  );
};
