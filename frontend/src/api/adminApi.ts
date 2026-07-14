import axiosClient from './axiosClient';
import type { DashboardDto, Product, CreateProductDto, UpdateProductDto, Brand, Category, ApiResponse } from '../types';

// Use an interface mapping API responses containing data property or returning the data directly.
// The backend returns PagedResultDto for products, so we expect a specific structure.

export const adminApi = {
  // Dashboard
  getDashboardStats: async (): Promise<DashboardDto> => {
    const res = await axiosClient.get('/dashboard') as unknown as ApiResponse<DashboardDto>;
    return res.data;
  },

  // Products
  getProducts: async (page = 1, pageSize = 100): Promise<{ items: Product[]; totalCount: number }> => {
    const res = await axiosClient.get(`/products?pageIndex=${page}&pageSize=${pageSize}`) as unknown as ApiResponse<{ items: Product[]; totalCount: number }>;
    return res.data;
  },
  
  createProduct: async (data: CreateProductDto): Promise<Product> => {
    const res = await axiosClient.post('/products', data) as unknown as ApiResponse<Product>;
    return res.data;
  },
  
  updateProduct: async (id: string, data: UpdateProductDto): Promise<Product> => {
    const res = await axiosClient.put(`/products/${id}`, data) as unknown as ApiResponse<Product>;
    return res.data;
  },
  
  deleteProduct: async (id: string): Promise<boolean> => {
    const res = await axiosClient.delete(`/products/${id}`) as unknown as ApiResponse<boolean>;
    return res.data;
  },

  // Brands & Categories for dropdowns
  getBrands: async (): Promise<Brand[]> => {
    const res = await axiosClient.get('/brands') as unknown as ApiResponse<Brand[]>;
    return res.data || [];
  },
  
  getCategories: async (): Promise<Category[]> => {
    const res = await axiosClient.get('/categories') as unknown as ApiResponse<Category[]>;
    return res.data || [];
  }
};
