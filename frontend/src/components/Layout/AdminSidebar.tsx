import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { 
  LayoutDashboard, 
  Smartphone, 
  Tags, 
  Layers, 
  ShoppingCart, 
  Users, 
  Ticket,
  FileText,
  MessageSquare,
  Image
} from 'lucide-react';

interface AdminSidebarProps {
  isOpen: boolean;
  setIsOpen: (isOpen: boolean) => void;
}

export const AdminSidebar: React.FC<AdminSidebarProps> = ({ isOpen }) => {
  const location = useLocation();
  const { isStaff } = useAuth();

  const prefix = isStaff ? '/staff' : '/admin';

  const links = [
    { name: 'Bảng điều khiển', path: `${prefix}`, icon: <LayoutDashboard size={20} />, adminOnly: false },
    { name: 'Sản phẩm (QTV)', path: `${prefix}/products`, icon: <Smartphone size={20} />, adminOnly: true },
    { name: 'Kho sản phẩm', path: `${prefix}/staff-products`, icon: <Smartphone size={20} />, adminOnly: false, staffOnly: true },
    { name: 'Thương hiệu', path: `${prefix}/brands`, icon: <Tags size={20} />, adminOnly: true },
    { name: 'Danh mục', path: `${prefix}/categories`, icon: <Layers size={20} />, adminOnly: true },
    { name: 'Đơn hàng', path: `${prefix}/orders`, icon: <ShoppingCart size={20} />, adminOnly: false },
    { name: 'Khuyến mãi', path: `${prefix}/promotions`, icon: <FileText size={20} />, adminOnly: false, staffOnly: true },
    { name: 'Ảnh nền (Banners)', path: `${prefix}/banners`, icon: <Image size={20} />, adminOnly: false, staffOnly: true },
    { name: 'Chat trực tuyến', path: `${prefix}/chat`, icon: <MessageSquare size={20} />, adminOnly: false, staffOnly: true },
    { name: 'Người dùng', path: `${prefix}/users`, icon: <Users size={20} />, adminOnly: true },
    { name: 'Mã giảm giá', path: `${prefix}/vouchers`, icon: <Ticket size={20} />, adminOnly: true },
    { name: 'AI Trợ lý', path: `${prefix}/ai`, icon: <span className="text-[20px] leading-none">✨</span>, adminOnly: false },
  ];

  const visibleLinks = links.filter(link => {
    if (isStaff && link.adminOnly) return false;
    if (!isStaff && link.staffOnly) return false;
    return true;
  });

  return (
    <aside 
      className={`bg-gray-900 text-white flex-shrink-0 min-h-screen flex flex-col transition-all duration-300 ${
        isOpen ? 'w-64' : 'w-20'
      }`}
    >
      <div className="p-6 flex justify-center items-center h-20">
        <Link to="/" className="text-xl font-bold text-white tracking-wider flex items-center gap-2 overflow-hidden whitespace-nowrap">
          <Smartphone className="text-primary-500 flex-shrink-0" size={24} />
          {isOpen && (
            <span className="animate-in fade-in zoom-in duration-300">
              {isStaff ? 'Hệ thống NV' : 'Quản trị viên'}
            </span>
          )}
        </Link>
      </div>
      <nav className="flex-1 mt-2">
        <ul className="space-y-2 px-3">
          {visibleLinks.map((link) => {
            const isActive = location.pathname === link.path;
            return (
              <li key={link.name}>
                <Link
                  to={link.path}
                  className={`flex items-center gap-3 py-3 rounded-lg transition-colors relative group ${
                    isOpen ? 'px-4' : 'justify-center px-2'
                  } ${
                    isActive ? 'bg-primary-600 text-white' : 'text-gray-400 hover:bg-gray-800 hover:text-white'
                  }`}
                  title={!isOpen ? link.name : undefined}
                >
                  <div className="flex-shrink-0">{link.icon}</div>
                  {isOpen && (
                    <span className="whitespace-nowrap animate-in fade-in duration-300">
                      {link.name}
                    </span>
                  )}
                  
                  {/* Tooltip for collapsed state */}
                  {!isOpen && (
                    <div className="absolute left-full ml-2 px-2 py-1 bg-gray-800 text-white text-xs rounded opacity-0 group-hover:opacity-100 pointer-events-none whitespace-nowrap z-50 transition-opacity">
                      {link.name}
                    </div>
                  )}
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>
      <div className={`p-4 border-t border-gray-800 flex ${isOpen ? 'justify-start' : 'justify-center'}`}>
        <Link to="/" className="text-sm text-gray-400 hover:text-white flex items-center gap-2" title={!isOpen ? "Quay lại Cửa hàng" : undefined}>
          <span className="flex-shrink-0">&larr;</span>
          {isOpen && <span className="whitespace-nowrap">Quay lại Cửa hàng</span>}
        </Link>
      </div>
    </aside>
  );
};
