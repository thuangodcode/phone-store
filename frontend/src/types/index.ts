export interface User {
  id: string;
  fullName: string;
  email: string;
  phone: string;
  role: string;
  avatar: string;
  address: string;
}

export interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  salePrice: number;
  brandName: string;
  categoryName: string;
  images: string[];
  stock: number;
  sold: number;
  averageRating: number;
  totalReviews: number;
  specifications: Record<string, string>;
  createdAt: string;
}

export interface CreateProductDto {
  name: string;
  description: string;
  price: number;
  salePrice: number;
  brandId: string;
  categoryId: string;
  images: string[];
  stock: number;
  specifications: Record<string, string>;
}

export interface UpdateProductDto extends CreateProductDto {}

export interface Brand {
  id: string;
  name: string;
  logo: string;
}

export interface Category {
  id: string;
  name: string;
  description: string;
}

export interface DashboardDto {
  revenue: {
    totalRevenue: number;
    monthlyRevenue: number;
    dailyRevenue: number;
  };
  orders: {
    totalOrders: number;
    pendingOrders: number;
    confirmedOrders: number;
    shippingOrders: number;
    deliveredOrders: number;
    cancelledOrders: number;
  };
  totalCustomers: number;
  totalProducts: number;
}

export interface AuthResponse {
  token: string;
  user: User;
}

export interface ApiResponse<T = any> {
  success: boolean;
  message: string;
  data: T;
  errors?: string[];
}
