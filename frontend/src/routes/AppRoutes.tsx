import React from 'react';
import { Routes, Route } from 'react-router-dom';
import { MainLayout } from '../components/Layout/MainLayout';
import { AdminLayout } from '../components/Layout/AdminLayout';
import { ProtectedRoute, AdminRoute } from './ProtectedRoutes';
import { HomePage } from '../pages/Home/HomePage';
import { LoginPage } from '../pages/Auth/LoginPage';
import { RegisterPage } from '../pages/Auth/RegisterPage';
import { ForgotPasswordPage } from '../pages/Auth/ForgotPasswordPage';
import { DashboardPage } from '../pages/Admin/Dashboard/DashboardPage';
import { AdminProductsPage } from '../pages/Admin/Products/AdminProductsPage';
import { AdminBrandsPage } from '../pages/Admin/Brands/AdminBrandsPage';
import { AdminCategoriesPage } from '../pages/Admin/Categories/AdminCategoriesPage';
import { AdminOrdersPage } from '../pages/Admin/Orders/AdminOrdersPage';
import { AdminUsersPage } from '../pages/Admin/Users/AdminUsersPage';
import { AdminVouchersPage } from '../pages/Admin/Vouchers/AdminVouchersPage';

export const AppRoutes: React.FC = () => {
  return (
    <Routes>
      {/* Public Routes */}
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />
      <Route path="/forgot-password" element={<ForgotPasswordPage />} />

      {/* Customer Routes with Main Layout */}
      <Route element={<MainLayout />}>
        <Route path="/" element={<HomePage />} />
        <Route path="/products" element={<div className="p-8 text-center text-xl">Products Page (WIP)</div>} />
        <Route path="/products/:id" element={<div className="p-8 text-center text-xl">Product Detail (WIP)</div>} />
        
        {/* Protected Customer Routes */}
        <Route element={<ProtectedRoute />}>
          <Route path="/cart" element={<div className="p-8 text-center text-xl">Cart Page (WIP)</div>} />
          <Route path="/wishlist" element={<div className="p-8 text-center text-xl">Wishlist Page (WIP)</div>} />
          <Route path="/profile" element={<div className="p-8 text-center text-xl">Profile Page (WIP)</div>} />
          <Route path="/orders" element={<div className="p-8 text-center text-xl">Orders Page (WIP)</div>} />
        </Route>
      </Route>

      {/* Admin Routes with Admin Layout */}
      <Route path="/admin" element={<AdminRoute />}>
        <Route element={<AdminLayout />}>
          <Route index element={<DashboardPage />} />
          <Route path="products" element={<AdminProductsPage />} />
          <Route path="brands" element={<AdminBrandsPage />} />
          <Route path="categories" element={<AdminCategoriesPage />} />
          <Route path="orders" element={<AdminOrdersPage />} />
          <Route path="users" element={<AdminUsersPage />} />
          <Route path="vouchers" element={<AdminVouchersPage />} />
        </Route>
      </Route>
    </Routes>
  );
};
