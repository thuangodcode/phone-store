import React from 'react';
import { Routes, Route } from 'react-router-dom';
import { MainLayout } from '../components/Layout/MainLayout';
import { AdminLayout } from '../components/Layout/AdminLayout';
import { ProtectedRoute, AdminRoute, StaffRoute } from './ProtectedRoutes';
import { HomePage } from '../pages/Home/HomePage';
import { ProductDetailPage } from '../pages/Home/ProductDetailPage';
import { CartPage } from '../pages/Cart/CartPage';
import { CheckoutPage } from '../pages/Checkout/CheckoutPage';
import { PaymentSuccessPage } from '../pages/Checkout/PaymentSuccessPage';
import { LoginPage } from '../pages/Auth/LoginPage';
import { RegisterPage } from '../pages/Auth/RegisterPage';
import { MapsPage } from '../pages/Home/MapsPage';
import { PromotionsPage } from '../pages/Home/PromotionsPage';
import { ForgotPasswordPage } from '../pages/Auth/ForgotPasswordPage';
import { DashboardPage } from '../pages/Admin/Dashboard/DashboardPage';
import { AdminProductsPage } from '../pages/Admin/Products/AdminProductsPage';
import { AdminBrandsPage } from '../pages/Admin/Brands/AdminBrandsPage';
import { AdminCategoriesPage } from '../pages/Admin/Categories/AdminCategoriesPage';
import { AdminOrdersPage } from '../pages/Admin/Orders/AdminOrdersPage';
import { AdminUsersPage } from '../pages/Admin/Users/AdminUsersPage';
import { AdminVouchersPage } from '../pages/Admin/Vouchers/AdminVouchersPage';
import { StaffProductsPage } from '../pages/Staff/Products/StaffProductsPage';
import { StaffPromotionsPage } from '../pages/Staff/Promotions/StaffPromotionsPage';
import { StaffBannersPage } from '../pages/Staff/Banners/StaffBannersPage';
import { StaffChatPage } from '../pages/Staff/Chat/StaffChat';
import { ProfilePage } from '../pages/Profile/ProfilePage';
import { CustomerOrdersPage } from '../pages/Profile/CustomerOrdersPage';
import { WishlistPage } from '../pages/Profile/WishlistPage';
import { AIAssistantPage } from '../pages/Admin/AI/AIAssistantPage';
import { AdminAITracesPage } from '../pages/Admin/AI/AdminAITracesPage';

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
        <Route path="/products" element={<div className="p-8 text-center text-xl">Đang phát triển</div>} />
        <Route path="/products/:id" element={<ProductDetailPage />} />
        <Route path="/maps" element={<MapsPage />} />
        <Route path="/promotions" element={<PromotionsPage />} />
        
        {/* Protected Customer Routes */}
        <Route element={<ProtectedRoute />}>
          <Route path="/cart" element={<CartPage />} />
          <Route path="/checkout" element={<CheckoutPage />} />
          <Route path="/payment-success" element={<PaymentSuccessPage />} />
          <Route path="/wishlist" element={<WishlistPage />} />
          <Route path="/profile" element={<ProfilePage />} />
          <Route path="/history" element={<CustomerOrdersPage />} />
        </Route>
      </Route>

      {/* Admin Routes with Admin Layout */}
      <Route path="/admin" element={<AdminRoute />}>
        <Route element={<AdminLayout />}>
          <Route index element={<DashboardPage />} />
          <Route path="orders" element={<AdminOrdersPage />} />
          <Route path="products" element={<AdminProductsPage />} />
          <Route path="brands" element={<AdminBrandsPage />} />
          <Route path="categories" element={<AdminCategoriesPage />} />
          <Route path="users" element={<AdminUsersPage />} />
          <Route path="vouchers" element={<AdminVouchersPage />} />
          <Route path="ai" element={<AIAssistantPage />} />
          <Route path="ai-traces" element={<AdminAITracesPage />} />
        </Route>
      </Route>

      {/* Staff Routes with Admin Layout */}
      <Route path="/staff" element={<StaffRoute />}>
        <Route element={<AdminLayout />}>
          <Route index element={<DashboardPage />} />
          <Route path="orders" element={<AdminOrdersPage />} />
          <Route path="staff-products" element={<StaffProductsPage />} />
          <Route path="promotions" element={<StaffPromotionsPage />} />
          <Route path="banners" element={<StaffBannersPage />} />
          <Route path="chat" element={<StaffChatPage />} />
          <Route path="ai" element={<AIAssistantPage />} />
        </Route>
      </Route>
    </Routes>
  );
};
