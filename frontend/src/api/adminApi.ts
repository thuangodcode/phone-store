import axiosClient from './axiosClient';
import type { DashboardDto, Product, CreateProductDto, UpdateProductDto, Brand, Category, ApiResponse } from '../types';

// Use an interface mapping API responses containing data property or returning the data directly.
// The backend returns PagedResultDto for products, so we expect a specific structure.

export const adminApi = {
  // Dashboard
  getDashboardStats: async (): Promise<DashboardDto> => {
    const res = await axiosClient.get<ApiResponse<DashboardDto>>('/dashboard/stats');
    return res.data.data;
  },

  // Products
  getProducts: async (page = 1, pageSize = 100): Promise<{ items: Product[]; totalCount: number }> => {
    // Assuming backend endpoint /api/products returns paged result
    const res = await axiosClient.get<ApiResponse<{ items: Product[]; totalCount: number }>>(`/products?pageIndex=${page}&pageSize=${pageSize}`);
    return res.data.data;
  },
  
  createProduct: async (data: CreateProductDto): Promise<Product> => {
    const res = await axiosClient.post<ApiResponse<Product>>('/products', data);
    return res.data.data;
  },
  
  updateProduct: async (id: string, data: UpdateProductDto): Promise<Product> => {
    const res = await axiosClient.put<ApiResponse<Product>>(`/products/${id}`, data);
    return res.data.data;
  },
  
  deleteProduct: async (id: string): Promise<boolean> => {
    const res = await axiosClient.delete<ApiResponse<boolean>>(`/products/${id}`);
    return res.data.data;
  },

  // Brands & Categories for dropdowns
  getBrands: async (): Promise<Brand[]> => {
    const res = await axiosClient.get<ApiResponse<Brand[]>>('/brands');
    return res.data.data;
  },
  
  getCategories: async (): Promise<Category[]> => {
    const res = await axiosClient.get<ApiResponse<Category[]>>('/categories');
    return res.data.data;
  }
};
