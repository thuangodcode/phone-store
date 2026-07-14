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
