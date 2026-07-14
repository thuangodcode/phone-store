import axiosClient from './axiosClient';
import type { ApiResponse } from '../types';

export const wishlistApi = {
  getWishlist: async () => {
    const res = await axiosClient.get('/wishlist') as unknown as ApiResponse<any>;
    return res.data;
  },
  addToWishlist: async (productId: string) => {
    const res = await axiosClient.post(`/wishlist/${productId}`) as unknown as ApiResponse<any>;
    return res.data;
  },
  removeFromWishlist: async (productId: string) => {
    const res = await axiosClient.delete(`/wishlist/${productId}`) as unknown as ApiResponse<any>;
    return res.data;
  }
};
