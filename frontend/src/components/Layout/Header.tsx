import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { ShoppingCart, Heart, User, LogOut } from 'lucide-react';

export const Header: React.FC = () => {
  const { user, isAuthenticated, logout, isAdmin } = useAuth();

  return (
    <header className="bg-white shadow-sm sticky top-0 z-50">
      <div className="container mx-auto px-4 py-4 flex items-center justify-between">
        <Link to="/" className="text-2xl font-bold text-primary-600">
          PhoneStore
        </Link>

        <nav className="hidden md:flex space-x-8">
          <Link to="/" className="text-gray-600 hover:text-primary-600 font-medium">Home</Link>
          <Link to="/products" className="text-gray-600 hover:text-primary-600 font-medium">Products</Link>
        </nav>

        <div className="flex items-center space-x-6">
          <Link to="/wishlist" className="text-gray-600 hover:text-primary-600 relative">
            <Heart size={24} />
          </Link>
          <Link to="/cart" className="text-gray-600 hover:text-primary-600 relative">
            <ShoppingCart size={24} />
            <span className="absolute -top-2 -right-2 bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">0</span>
          </Link>

          {isAuthenticated ? (
            <div className="flex items-center space-x-4">
              {isAdmin && (
                <Link to="/admin" className="text-sm bg-gray-100 px-3 py-1 rounded-md text-gray-700 hover:bg-gray-200">
                  Admin
                </Link>
              )}
              <Link to="/profile" className="text-gray-600 hover:text-primary-600">
                <User size={24} />
              </Link>
              <button onClick={logout} className="text-gray-600 hover:text-red-500">
                <LogOut size={24} />
              </button>
            </div>
          ) : (
            <Link to="/login" className="bg-primary-600 text-white px-5 py-2 rounded-lg font-medium hover:bg-primary-700 transition">
              Login
            </Link>
          )}
        </div>
      </div>
    </header>
  );
};
