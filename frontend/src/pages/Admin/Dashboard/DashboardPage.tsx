import React, { useEffect, useState } from 'react';
import { adminApi } from '../../../api/adminApi';
import type { DashboardDto } from '../../../types';
import { toast } from 'react-toastify';
import { LoadingSpinner } from '../../../components/ui/LoadingSpinner';
import { NumberCounter } from '../../../components/ui/number-counter';
import {
  PieChart,
  Pie,
  Cell,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer
} from 'recharts';

const PIE_COLORS = ['#f59e0b', '#3b82f6', '#8b5cf6', '#10b981', '#ef4444'];

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
    return <LoadingSpinner fullScreen />;
  }

  if (!stats) {
    return <div className="p-8 text-center text-red-500">Failed to load data.</div>;
  }

  const orderStatusData = [
    { name: 'Pending', value: stats.orders.pendingOrders },
    { name: 'Confirmed', value: stats.orders.confirmedOrders },
    { name: 'Shipping', value: stats.orders.shippingOrders },
    { name: 'Delivered', value: stats.orders.deliveredOrders },
    { name: 'Cancelled', value: stats.orders.cancelledOrders },
  ].filter(item => item.value > 0); // Only show non-zero statuses

  const revenueData = [
    { name: 'Daily', revenue: stats.revenue.dailyRevenue },
    { name: 'Monthly', revenue: stats.revenue.monthlyRevenue },
    { name: 'Total', revenue: stats.revenue.totalRevenue },
  ];

  return (
    <div className="space-y-8 fade-in">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold text-gray-900 tracking-tight">Dashboard Overview</h1>
        <div className="text-sm text-gray-500">
          Last updated: {new Date().toLocaleString('vi-VN')}
        </div>
      </div>

      {/* Top Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 flex flex-col justify-between hover:shadow-md transition-shadow">
          <h3 className="text-sm font-semibold text-gray-500 mb-2 uppercase tracking-wider">Total Revenue</h3>
          <NumberCounter 
            value={stats.revenue.totalRevenue} 
            prefix="$" 
            decimals={0} 
            className="text-3xl font-bold text-primary-600" 
          />
        </div>
        <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 flex flex-col justify-between hover:shadow-md transition-shadow">
          <h3 className="text-sm font-semibold text-gray-500 mb-2 uppercase tracking-wider">Total Orders</h3>
          <NumberCounter 
            value={stats.orders.totalOrders} 
            className="text-3xl font-bold text-gray-900" 
          />
        </div>
        <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 flex flex-col justify-between hover:shadow-md transition-shadow">
          <h3 className="text-sm font-semibold text-gray-500 mb-2 uppercase tracking-wider">Total Customers</h3>
          <NumberCounter 
            value={stats.totalCustomers} 
            className="text-3xl font-bold text-gray-900" 
          />
        </div>
        <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 flex flex-col justify-between hover:shadow-md transition-shadow">
          <h3 className="text-sm font-semibold text-gray-500 mb-2 uppercase tracking-wider">Total Products</h3>
          <NumberCounter 
            value={stats.totalProducts} 
            className="text-3xl font-bold text-gray-900" 
          />
        </div>
      </div>
      
      {/* Charts Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        
        {/* Revenue Bar Chart */}
        <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
          <h3 className="text-lg font-bold text-gray-800 mb-6 border-b pb-4">Revenue Breakdown</h3>
          <div className="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart
                data={revenueData}
                margin={{ top: 20, right: 30, left: 20, bottom: 5 }}
              >
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f3f4f6" />
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill: '#6b7280'}} />
                <YAxis axisLine={false} tickLine={false} tick={{fill: '#6b7280'}} tickFormatter={(val) => `$${val}`} />
                <Tooltip 
                  cursor={{fill: '#f9fafb'}}
                  contentStyle={{borderRadius: '0.75rem', border: 'none', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'}}
                  formatter={(value: number) => [`$${value.toLocaleString()}`, 'Revenue']}
                />
                <Bar dataKey="revenue" fill="#3b82f6" radius={[6, 6, 0, 0]} barSize={50} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Orders Status Pie Chart */}
        <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
          <h3 className="text-lg font-bold text-gray-800 mb-6 border-b pb-4">Orders Status Distribution</h3>
          {orderStatusData.length > 0 ? (
            <div className="h-80">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={orderStatusData}
                    cx="50%"
                    cy="50%"
                    innerRadius={80}
                    outerRadius={120}
                    paddingAngle={5}
                    dataKey="value"
                    labelLine={false}
                  >
                    {orderStatusData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={PIE_COLORS[index % PIE_COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip 
                    contentStyle={{borderRadius: '0.75rem', border: 'none', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'}}
                  />
                  <Legend verticalAlign="bottom" height={36} iconType="circle" />
                </PieChart>
              </ResponsiveContainer>
            </div>
          ) : (
            <div className="h-80 flex items-center justify-center text-gray-400">
              No order data available
            </div>
          )}
        </div>

      </div>

      {/* Detailed Revenue List (Optional, keeping it for quick view) */}
      <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
        <h3 className="text-lg font-bold text-gray-800 mb-4">Summary Numbers</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          <div>
            <h4 className="text-sm font-medium text-gray-500 mb-3 uppercase">Revenue Details</h4>
            <ul className="space-y-3">
              <li className="flex justify-between border-b pb-2 items-center">
                <span className="text-gray-600 font-medium">Daily Revenue</span>
                <span className="font-bold text-lg text-green-600">
                  <NumberCounter value={stats.revenue.dailyRevenue} prefix="$" />
                </span>
              </li>
              <li className="flex justify-between border-b pb-2 items-center">
                <span className="text-gray-600 font-medium">Monthly Revenue</span>
                <span className="font-bold text-lg text-green-600">
                  <NumberCounter value={stats.revenue.monthlyRevenue} prefix="$" />
                </span>
              </li>
            </ul>
          </div>
          <div>
            <h4 className="text-sm font-medium text-gray-500 mb-3 uppercase">Order Highlights</h4>
            <ul className="space-y-3">
              <li className="flex justify-between border-b pb-2 items-center">
                <span className="text-gray-600 font-medium">Pending Orders</span>
                <span className="font-bold text-lg text-orange-500">
                  <NumberCounter value={stats.orders.pendingOrders} />
                </span>
              </li>
              <li className="flex justify-between border-b pb-2 items-center">
                <span className="text-gray-600 font-medium">Delivered Orders</span>
                <span className="font-bold text-lg text-blue-500">
                  <NumberCounter value={stats.orders.deliveredOrders} />
                </span>
              </li>
              <li className="flex justify-between border-b pb-2 items-center">
                <span className="text-gray-600 font-medium">Cancelled Orders</span>
                <span className="font-bold text-lg text-red-500">
                  <NumberCounter value={stats.orders.cancelledOrders} />
                </span>
              </li>
            </ul>
          </div>
        </div>
      </div>

    </div>
  );
};
