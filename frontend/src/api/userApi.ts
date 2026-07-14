import axiosClient from './axiosClient';
import type { UpdateProfileDto, ChangePasswordDto, User, ApiResponse } from '../types';

export const userApi = {
  updateProfile: (data: UpdateProfileDto) => 
    axiosClient.put<any, ApiResponse<User>>('/users/profile', data),
    
  changePassword: (data: ChangePasswordDto) => 
    axiosClient.put<any, ApiResponse>('/auth/change-password', data),
};
