import React from 'react';
import { Outlet } from 'react-router-dom';
import { AdminSidebar } from './AdminSidebar';
import { useAuth } from '../../contexts/AuthContext';
import { LogOut } from 'lucide-react';

export const AdminLayout: React.FC = () => {
  const { user, logout } = useAuth();

  return (
    <div className="min-h-screen flex bg-gray-100 font-sans">
      <AdminSidebar />
      <div className="flex-1 flex flex-col min-w-0">
        <header className="bg-white shadow-sm h-16 flex items-center justify-end px-8 z-10">
          <div className="flex items-center gap-4">
            <span className="text-sm font-medium text-gray-700">Admin: {user?.fullName}</span>
            <button onClick={logout} className="text-gray-500 hover:text-red-500 transition">
              <LogOut size={20} />
            </button>
          </div>
        </header>
        <main className="flex-1 p-8 overflow-auto">
          <Outlet />
        </main>
      </div>
    </div>
  );
};
