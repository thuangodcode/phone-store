import axiosClient from './axiosClient';
import type {
  DashboardDto,
  Product,
  CreateProductDto,
  UpdateProductDto,
  Brand,
  Category,
  ApiResponse,
  CreateBrandDto,
  UpdateBrandDto,
  CreateCategoryDto,
  UpdateCategoryDto,
  Order,
  UpdateOrderStatusDto,
  User,
  Voucher,
  CreateVoucherDto,
  UpdateVoucherDto,
} from '../types';

export const adminApi = {
  // Dashboard
  getDashboardStats: async (): Promise<DashboardDto> => {
    const res = await axiosClient.get('/dashboard') as unknown as ApiResponse<DashboardDto>;
    return res.data;
  },

  // Products
  getProducts: async (page = 1, pageSize = 100, includeInactive = false): Promise<{ items: Product[]; totalCount: number }> => {
    const res = await axiosClient.get(`/products?page=${page}&pageSize=${pageSize}&includeInactive=${includeInactive}`) as unknown as ApiResponse<{ items: Product[]; totalCount: number }>;
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

  // Brands
  getBrands: async (): Promise<Brand[]> => {
    const res = await axiosClient.get('/brands') as unknown as ApiResponse<Brand[]>;
    return res.data || [];
  },

  createBrand: async (data: CreateBrandDto): Promise<Brand> => {
    const res = await axiosClient.post('/brands', data) as unknown as ApiResponse<Brand>;
    return res.data;
  },

  updateBrand: async (id: string, data: UpdateBrandDto): Promise<Brand> => {
    const res = await axiosClient.put(`/brands/${id}`, data) as unknown as ApiResponse<Brand>;
    return res.data;
  },

  deleteBrand: async (id: string): Promise<boolean> => {
    const res = await axiosClient.delete(`/brands/${id}`) as unknown as ApiResponse<boolean>;
    return res.data;
  },

  // Categories
  getCategories: async (): Promise<Category[]> => {
    const res = await axiosClient.get('/categories') as unknown as ApiResponse<Category[]>;
    return res.data || [];
  },

  createCategory: async (data: CreateCategoryDto): Promise<Category> => {
    const res = await axiosClient.post('/categories', data) as unknown as ApiResponse<Category>;
    return res.data;
  },

  updateCategory: async (id: string, data: UpdateCategoryDto): Promise<Category> => {
    const res = await axiosClient.put(`/categories/${id}`, data) as unknown as ApiResponse<Category>;
    return res.data;
  },

  deleteCategory: async (id: string): Promise<boolean> => {
    const res = await axiosClient.delete(`/categories/${id}`) as unknown as ApiResponse<boolean>;
    return res.data;
  },

  // Orders
  getOrders: async (): Promise<Order[]> => {
    const res = await axiosClient.get('/orders') as unknown as ApiResponse<Order[]>;
    return res.data || [];
  },

  updateOrderStatus: async (id: string, data: UpdateOrderStatusDto): Promise<Order> => {
    const res = await axiosClient.put(`/orders/${id}/status`, data) as unknown as ApiResponse<Order>;
    return res.data;
  },

  // Users
  getUsers: async (): Promise<User[]> => {
    const res = await axiosClient.get('/users') as unknown as ApiResponse<User[]>;
    return res.data || [];
  },

  deleteUser: async (id: string): Promise<boolean> => {
    const res = await axiosClient.delete(`/users/${id}`) as unknown as ApiResponse<boolean>;
    return res.data;
  },

  toggleUserStatus: async (id: string): Promise<User> => {
    const res = await axiosClient.put(`/users/${id}/toggle-status`) as unknown as ApiResponse<User>;
    return res.data;
  },

  // Vouchers
  getVouchers: async (): Promise<Voucher[]> => {
    const res = await axiosClient.get('/vouchers') as unknown as ApiResponse<Voucher[]>;
    return res.data || [];
  },

  createVoucher: async (data: CreateVoucherDto): Promise<Voucher> => {
    const res = await axiosClient.post('/vouchers', data) as unknown as ApiResponse<Voucher>;
    return res.data;
  },

  updateVoucher: async (id: string, data: UpdateVoucherDto): Promise<Voucher> => {
    const res = await axiosClient.put(`/vouchers/${id}`, data) as unknown as ApiResponse<Voucher>;
    return res.data;
  },

  deleteVoucher: async (id: string): Promise<boolean> => {
    const res = await axiosClient.delete(`/vouchers/${id}`) as unknown as ApiResponse<boolean>;
    return res.data;
  },
};
