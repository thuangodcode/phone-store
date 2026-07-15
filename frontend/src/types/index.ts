export interface User {
  id: string;
  fullName: string;
  email: string;
  phone: string;
  role: string;
  avatar: string;
  address: string;
  isActive: boolean;
  createdAt: string;
}

export interface UpdateProfileDto {
  fullName: string;
  phone: string;
  address: string;
  avatar: string;
}

export interface ChangePasswordDto {
  currentPassword: string;
  newPassword: string;
  confirmNewPassword: string;
}

export interface ProductStorageVariantDto {
  storage: string;
  price: number;
  salePrice: number;
}

export interface ProductColorVariantDto {
  name: string;
  imageUrl: string;
  priceModifier: number;
}

export interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  salePrice: number;
  brandId?: string;
  categoryId?: string;
  brandName: string;
  categoryName: string;
  images: string[];
  stock: number;
  sold: number;
  averageRating: number;
  totalReviews: number;
  specifications: Record<string, string>;
  storageVariants: ProductStorageVariantDto[];
  colorVariants: ProductColorVariantDto[];
  promotions: string[];
  isActive?: boolean;
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
  storageVariants?: ProductStorageVariantDto[];
  colorVariants?: ProductColorVariantDto[];
  promotions?: string[];
}

export interface UpdateProductDto extends CreateProductDto {
  isActive: boolean;
}

export interface Brand {
  id: string;
  name: string;
  logo: string;
  isActive: boolean;
  createdAt: string;
}

export interface CreateBrandDto {
  name: string;
  logo: string;
}

export interface UpdateBrandDto {
  name: string;
  logo: string;
  isActive: boolean;
}

export interface Category {
  id: string;
  name: string;
  description: string;
  isActive: boolean;
  createdAt: string;
}

export interface CreateCategoryDto {
  name: string;
  description: string;
}

export interface UpdateCategoryDto {
  name: string;
  description: string;
  isActive: boolean;
}

export interface OrderItem {
  productId: string;
  productName: string;
  productImage: string;
  quantity: number;
  price: number;
  storage?: string;
  color?: string;
}

export interface OrderAuditLog {
  id: string;
  orderId: string;
  staffId: string;
  staffName: string;
  action: string;
  details: string;
  timestamp: string;
  oldValue?: string;
  newValue?: string;
}

export interface Order {
  id: string;
  userId: string;
  userName: string;
  items: OrderItem[];
  totalAmount: number;
  discountAmount: number;
  finalAmount: number;
  voucherCode?: string;
  shippingAddress: string;
  phone: string;
  receiverName: string;
  status: string;
  paymentStatus: string;
  orderCode: number;
  paymentMethod: string;
  note: string;
  staffId?: string;
  staffName?: string;
  auditLogs: OrderAuditLog[];
  createdAt: string;
  updatedAt: string;
}

export interface ChatSession {
  id: string;
  customerId: string;
  customerName: string;
  staffId?: string;
  staffName?: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface ChatMessage {
  id: string;
  sessionId: string;
  senderId: string;
  senderName: string;
  senderRole: string;
  content: string;
  timestamp: string;
}

export interface UpdateOrderStatusDto {
  status: string;
}

export interface Voucher {
  id: string;
  code: string;
  description: string;
  discountType: string;
  discountValue: number;
  minOrderAmount: number;
  maxDiscount: number;
  quantity: number;
  used: number;
  startDate: string;
  endDate: string;
  isActive: boolean;
  createdAt: string;
}

export interface CreateVoucherDto {
  code: string;
  description: string;
  discountType: string;
  discountValue: number;
  minOrderAmount: number;
  maxDiscount: number;
  quantity: number;
  startDate: string;
  endDate: string;
}

export interface UpdateVoucherDto extends CreateVoucherDto {
  isActive: boolean;
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

export interface Banner {
  id: string;
  title: string;
  imageUrl: string;
  isActive: boolean;
  createdAt: string;
}

export interface CreateBannerDto {
  title: string;
  imageUrl: string;
  isActive: boolean;
}

export interface UpdateBannerDto extends CreateBannerDto {}
