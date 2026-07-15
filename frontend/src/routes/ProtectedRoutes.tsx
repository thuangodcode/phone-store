import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

export const ProtectedRoute: React.FC = () => {
  const { isAuthenticated, isInitialized } = useAuth();

  if (!isInitialized) {
    return null;
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return <Outlet />;
};

export const AdminRoute: React.FC = () => {
  const { isAuthenticated, isAdmin, isInitialized } = useAuth();

  if (!isInitialized) {
    return null;
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  
  if (!isAdmin) {
    return <Navigate to="/" replace />;
  }

  return <Outlet />;
};

export const StaffRoute: React.FC = () => {
  const { isAuthenticated, isStaff, isInitialized } = useAuth();

  if (!isInitialized) {
    return null;
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  
  if (!isStaff) {
    return <Navigate to="/" replace />;
  }

  return <Outlet />;
};

export const AdminOrStaffRoute: React.FC = () => {
  const { isAuthenticated, isAdminOrStaff, isInitialized } = useAuth();

  if (!isInitialized) {
    return null;
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  
  if (!isAdminOrStaff) {
    return <Navigate to="/" replace />;
  }

  return <Outlet />;
};
