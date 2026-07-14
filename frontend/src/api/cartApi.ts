import axiosClient from './axiosClient';
import type { ApiResponse } from '../types';

export const cartApi = {
  getCart: async () => {
    const res = await axiosClient.get('/cart') as unknown as ApiResponse<any>;
    return res.data;
  },

  addToCart: async (productId: string, quantity: number = 1, storage?: string, color?: string) => {
    const res = await axiosClient.post('/cart', { productId, quantity, storage, color }) as unknown as ApiResponse<any>;
    return res.data;
  },

  updateCartItem: async (productId: string, quantity: number, storage?: string, color?: string) => {
    const res = await axiosClient.put(`/cart/${productId}`, { quantity, storage, color }) as unknown as ApiResponse<any>;
    return res.data;
  },

  removeFromCart: async (productId: string) => {
    const res = await axiosClient.delete(`/cart/${productId}`) as unknown as ApiResponse<any>;
    return res.data;
  },

  clearCart: async () => {
    const res = await axiosClient.delete('/cart') as unknown as ApiResponse<any>;
    return res.success;
  }
};
