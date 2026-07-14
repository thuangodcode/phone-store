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
  Ticket 
} from 'lucide-react';

export const AdminSidebar: React.FC = () => {
  const location = useLocation();
  const { isStaff } = useAuth();

  const links = [
    { name: 'Dashboard', path: '/admin', icon: <LayoutDashboard size={20} />, adminOnly: true },
    { name: 'Products', path: '/admin/products', icon: <Smartphone size={20} />, adminOnly: true },
    { name: 'Products (Staff)', path: '/admin/staff-products', icon: <Smartphone size={20} />, adminOnly: false, staffOnly: true },
    { name: 'Brands', path: '/admin/brands', icon: <Tags size={20} />, adminOnly: true },
    { name: 'Categories', path: '/admin/categories', icon: <Layers size={20} />, adminOnly: true },
    { name: 'Orders', path: '/admin/orders', icon: <ShoppingCart size={20} />, adminOnly: false },
    { name: 'Users', path: '/admin/users', icon: <Users size={20} />, adminOnly: true },
    { name: 'Vouchers', path: '/admin/vouchers', icon: <Ticket size={20} />, adminOnly: true },
  ];

  const visibleLinks = links.filter(link => {
    if (isStaff && link.adminOnly) return false;
    if (!isStaff && link.staffOnly) return false;
    return true;
  });

  return (
    <aside className="w-64 bg-gray-900 text-white flex-shrink-0 min-h-screen flex flex-col">
      <div className="p-6">
        <Link to="/" className="text-2xl font-bold text-white tracking-wider flex items-center gap-2">
          <Smartphone className="text-primary-500" />
          {isStaff ? 'Staff Panel' : 'Admin Panel'}
        </Link>
      </div>
      <nav className="flex-1 mt-6">
        <ul className="space-y-2 px-4">
          {visibleLinks.map((link) => {
            const isActive = location.pathname === link.path;
            return (
              <li key={link.name}>
                <Link
                  to={link.path}
                  className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                    isActive ? 'bg-primary-600 text-white' : 'text-gray-400 hover:bg-gray-800 hover:text-white'
                  }`}
                >
                  {link.icon}
                  {link.name}
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>
      <div className="p-4 border-t border-gray-800">
        <Link to="/" className="text-sm text-gray-400 hover:text-white flex items-center gap-2">
          &larr; Back to Store
        </Link>
      </div>
    </aside>
  );
};
