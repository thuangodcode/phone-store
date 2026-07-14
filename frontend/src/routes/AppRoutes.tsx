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
          <Route path="brands" element={<div className="p-4">Manage Brands (WIP)</div>} />
          <Route path="categories" element={<div className="p-4">Manage Categories (WIP)</div>} />
          <Route path="orders" element={<div className="p-4">Manage Orders (WIP)</div>} />
          <Route path="users" element={<div className="p-4">Manage Users (WIP)</div>} />
          <Route path="vouchers" element={<div className="p-4">Manage Vouchers (WIP)</div>} />
        </Route>
      </Route>
    </Routes>
  );
};
