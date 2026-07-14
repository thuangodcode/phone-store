import React, { useEffect, useState } from 'react';
import { adminApi } from '../../../api/adminApi';
import type { DashboardDto } from '../../../types';
import { toast } from 'react-toastify';

export const DashboardPage: React.FC = () => {
  const [stats, setStats] = useState<DashboardDto | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const data = await adminApi.getDashboardStats();
        setStats(data);
      } catch (error) {
        console.error("Failed to fetch dashboard stats", error);
        toast.error("Failed to load dashboard statistics");
      } finally {
        setIsLoading(false);
      }
    };

    fetchStats();
  }, []);

  if (isLoading) {
    return <div className="p-8 text-center">Loading dashboard...</div>;
  }

  if (!stats) {
    return <div className="p-8 text-center text-red-500">Failed to load data.</div>;
  }

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Dashboard Overview</h1>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <h3 className="text-sm font-medium text-gray-500 mb-1">Total Revenue</h3>
          <p className="text-2xl font-bold">${stats.revenue.totalRevenue.toLocaleString()}</p>
        </div>
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <h3 className="text-sm font-medium text-gray-500 mb-1">Total Orders</h3>
          <p className="text-2xl font-bold">{stats.orders.totalOrders}</p>
        </div>
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <h3 className="text-sm font-medium text-gray-500 mb-1">Total Customers</h3>
          <p className="text-2xl font-bold">{stats.totalCustomers}</p>
        </div>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <h3 className="text-lg font-bold mb-4">Revenue Breakdown</h3>
          <ul className="space-y-3">
            <li className="flex justify-between border-b pb-2">
              <span className="text-gray-600">Daily Revenue</span>
              <span className="font-semibold">${stats.revenue.dailyRevenue.toLocaleString()}</span>
            </li>
            <li className="flex justify-between border-b pb-2">
              <span className="text-gray-600">Monthly Revenue</span>
              <span className="font-semibold">${stats.revenue.monthlyRevenue.toLocaleString()}</span>
            </li>
          </ul>
        </div>
        
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <h3 className="text-lg font-bold mb-4">Orders Status</h3>
          <ul className="space-y-3">
            <li className="flex justify-between border-b pb-2">
              <span className="text-gray-600">Pending</span>
              <span className="font-semibold text-orange-500">{stats.orders.pendingOrders}</span>
            </li>
            <li className="flex justify-between border-b pb-2">
              <span className="text-gray-600">Delivered</span>
              <span className="font-semibold text-green-500">{stats.orders.deliveredOrders}</span>
            </li>
            <li className="flex justify-between border-b pb-2">
              <span className="text-gray-600">Cancelled</span>
              <span className="font-semibold text-red-500">{stats.orders.cancelledOrders}</span>
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
};
