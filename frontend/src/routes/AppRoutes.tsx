import React from 'react';
import { Routes, Route } from 'react-router-dom';
import { MainLayout } from '../components/Layout/MainLayout';
import { AdminLayout } from '../components/Layout/AdminLayout';
import { ProtectedRoute, AdminRoute, AdminOrStaffRoute } from './ProtectedRoutes';
import { HomePage } from '../pages/Home/HomePage';
import { ProductDetailPage } from '../pages/Home/ProductDetailPage';
import { CartPage } from '../pages/Cart/CartPage';
import { CheckoutPage } from '../pages/Checkout/CheckoutPage';
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
import { StaffProductsPage } from '../pages/Staff/Products/StaffProductsPage';
import { ProfilePage } from '../pages/Profile/ProfilePage';
import { CustomerOrdersPage } from '../pages/Profile/CustomerOrdersPage';

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
        <Route path="/products/:id" element={<ProductDetailPage />} />
        
        {/* Protected Customer Routes */}
        <Route element={<ProtectedRoute />}>
          <Route path="/cart" element={<CartPage />} />
          <Route path="/checkout" element={<CheckoutPage />} />
          <Route path="/wishlist" element={<div className="p-8 text-center text-xl">Wishlist Page (WIP)</div>} />
          <Route path="/profile" element={<ProfilePage />} />
          <Route path="/history" element={<CustomerOrdersPage />} />
        </Route>
      </Route>

      {/* Admin/Staff Routes with Admin Layout */}
      <Route path="/admin" element={<AdminOrStaffRoute />}>
        <Route element={<AdminLayout />}>
          <Route index element={<DashboardPage />} />
          <Route path="orders" element={<AdminOrdersPage />} />
          <Route path="staff-products" element={<StaffProductsPage />} />
          {/* Admin Only Routes */}
          <Route element={<AdminRoute />}>
            <Route path="products" element={<AdminProductsPage />} />
            <Route path="brands" element={<AdminBrandsPage />} />
            <Route path="categories" element={<AdminCategoriesPage />} />
            <Route path="users" element={<AdminUsersPage />} />
            <Route path="vouchers" element={<AdminVouchersPage />} />
          </Route>
        </Route>
      </Route>
    </Routes>
  );
};
