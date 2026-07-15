import React, { useState } from 'react';
import { Outlet, useNavigate } from 'react-router-dom';
import { AdminSidebar } from './AdminSidebar';
import { useAuth } from '../../contexts/AuthContext';
import { LogOut, ChevronDown, Home, Menu } from 'lucide-react';
import { DropdownMenu, DropdownMenuItem, DropdownMenuSeparator } from './DropdownMenu';

export const AdminLayout: React.FC = () => {
  const { user, logout, isStaff } = useAuth();
  const navigate = useNavigate();
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  return (
    <div className="min-h-screen flex bg-gray-100 font-sans">
      <AdminSidebar isOpen={isSidebarOpen} setIsOpen={setIsSidebarOpen} />
      <div className="flex-1 flex flex-col min-w-0 transition-all duration-300">
        <header className="bg-white shadow-sm h-16 flex items-center justify-between px-8 z-10">
          <button 
            onClick={() => setIsSidebarOpen(!isSidebarOpen)}
            className="p-2 rounded-lg hover:bg-gray-100 transition-colors text-gray-600"
          >
            <Menu size={24} />
          </button>
          
          <div className="flex items-center gap-4">
            <DropdownMenu
              trigger={
                <button className="flex items-center gap-2 px-4 py-2 rounded-lg bg-gray-100 hover:bg-gray-200 text-gray-700 font-medium transition-colors">
                  <span className="text-sm">{isStaff ? 'Nhân viên' : 'Admin'}: {user?.fullName}</span>
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
                <DropdownMenuItem onClick={() => navigate('/')}>
                  <Home className="mr-3 h-5 w-5 text-zinc-500" />
                  <span>Quay lại cửa hàng</span>
                </DropdownMenuItem>
              </div>
              <DropdownMenuSeparator />
              <div className="flex flex-col space-y-1">
                <DropdownMenuItem onClick={handleLogout} danger={true}>
                  <LogOut className="mr-3 h-5 w-5" />
                  <span>Đăng xuất</span>
                </DropdownMenuItem>
              </div>
            </DropdownMenu>
          </div>
        </header>
        <main className="flex-1 p-8 overflow-auto">
          <Outlet />
        </main>
      </div>
    </div>
  );
};
