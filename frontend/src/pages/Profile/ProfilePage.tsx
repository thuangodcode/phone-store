import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { toast } from 'react-toastify';
import { useAuth } from '../../contexts/AuthContext';
import { userApi } from '../../api/userApi';
import type { UpdateProfileDto, ChangePasswordDto } from '../../types';
import { User as UserIcon, Lock, Camera, Eye, EyeOff } from 'lucide-react';

export const ProfilePage: React.FC = () => {
  const { user, login, token } = useAuth();
  const [activeTab, setActiveTab] = useState<'profile' | 'security'>('profile');
  const [showCurrentPassword, setShowCurrentPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  // Profile Form
  const {
    register: registerProfile,
    handleSubmit: handleProfileSubmit,
    watch: watchProfile,
    formState: { errors: profileErrors, isSubmitting: isProfileSubmitting }
  } = useForm<UpdateProfileDto>({
    defaultValues: {
      fullName: user?.fullName || '',
      phone: user?.phone || '',
      address: user?.address || '',
      avatar: user?.avatar || ''
    }
  });

  // Password Form
  const {
    register: registerPassword,
    handleSubmit: handlePasswordSubmit,
    watch: watchPassword,
    reset: resetPassword,
    formState: { errors: passwordErrors, isSubmitting: isPasswordSubmitting }
  } = useForm<ChangePasswordDto>({
    defaultValues: {
      currentPassword: '',
      newPassword: '',
      confirmNewPassword: ''
    }
  });

  const onProfileSubmit = async (data: UpdateProfileDto) => {
    try {
      const response = await userApi.updateProfile(data);
      if (response.success && token && user) {
        // Update user in context
        const updatedUser = { ...user, ...data };
        login(updatedUser, token);
        toast.success('Cập nhật hồ sơ thành công!');
      }
    } catch (error: any) {
      toast.error(error.message || 'Cập nhật hồ sơ thất bại!');
    }
  };

  const onPasswordSubmit = async (data: ChangePasswordDto) => {
    try {
      const response = await userApi.changePassword(data);
      if (response.success) {
        toast.success('Đổi mật khẩu thành công!');
        resetPassword();
      }
    } catch (error: any) {
      toast.error(error.message || 'Đổi mật khẩu thất bại! Vui lòng kiểm tra lại mật khẩu cũ.');
    }
  };

  return (
    <div className="max-w-4xl mx-auto p-4 sm:p-6 lg:p-8 mt-8">
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <div className="flex flex-col md:flex-row h-full min-h-[600px]">
          
          {/* Sidebar Tabs */}
          <div className="w-full md:w-64 bg-gray-50 border-b md:border-b-0 md:border-r border-gray-100 p-6">
            <h2 className="text-2xl font-bold text-gray-800 mb-8">Cài đặt</h2>
            <nav className="space-y-2">
              <button
                onClick={() => setActiveTab('profile')}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 font-medium ${
                  activeTab === 'profile'
                    ? 'bg-blue-600 text-white shadow-md shadow-blue-200'
                    : 'text-gray-600 hover:bg-gray-200 hover:text-gray-900'
                }`}
              >
                <UserIcon size={20} />
                Hồ sơ cá nhân
              </button>
              <button
                onClick={() => setActiveTab('security')}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 font-medium ${
                  activeTab === 'security'
                    ? 'bg-blue-600 text-white shadow-md shadow-blue-200'
                    : 'text-gray-600 hover:bg-gray-200 hover:text-gray-900'
                }`}
              >
                <Lock size={20} />
                Bảo mật
              </button>
            </nav>
          </div>

          {/* Main Content */}
          <div className="flex-1 p-6 md:p-10">
            {activeTab === 'profile' && (
              <div className="animate-fade-in">
                <h3 className="text-xl font-bold text-gray-800 mb-6">Thông tin cá nhân</h3>
                <form onSubmit={handleProfileSubmit(onProfileSubmit)} className="space-y-6">
                  
                  <div className="flex items-center gap-6 pb-6 border-b border-gray-100">
                    <div className="relative group">
                      <div className="w-24 h-24 rounded-full bg-gray-200 overflow-hidden border-4 border-white shadow-lg">
                        {user?.avatar || watchProfile('avatar') ? (
                          <img src={user?.avatar || watchProfile('avatar')} alt="Avatar" className="w-full h-full object-cover" />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center text-gray-400 bg-gray-100">
                            <UserIcon size={40} />
                          </div>
                        )}
                      </div>
                      {/* Avatar is just a URL field right now, but we can make it look like it's editable */}
                      <div className="absolute inset-0 bg-black/40 rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer">
                        <Camera size={24} className="text-white" />
                      </div>
                    </div>
                    <div className="flex-1">
                      <label className="block text-sm font-medium text-gray-700 mb-1">Ảnh đại diện (URL)</label>
                      <input
                        type="text"
                        {...registerProfile('avatar')}
                        className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all outline-none"
                        placeholder="https://example.com/avatar.jpg"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Họ và tên</label>
                      <input
                        type="text"
                        {...registerProfile('fullName', { required: 'Vui lòng nhập họ tên' })}
                        className={`w-full px-4 py-2.5 rounded-xl border ${profileErrors.fullName ? 'border-red-500' : 'border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-200'} transition-all outline-none`}
                        placeholder="Nguyễn Văn A"
                      />
                      {profileErrors.fullName && <p className="text-red-500 text-sm mt-1">{profileErrors.fullName.message}</p>}
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Số điện thoại</label>
                      <input
                        type="text"
                        {...registerProfile('phone')}
                        className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all outline-none"
                        placeholder="0123456789"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Địa chỉ</label>
                    <textarea
                      {...registerProfile('address')}
                      rows={3}
                      className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all outline-none resize-none"
                      placeholder="Nhập địa chỉ của bạn"
                    />
                  </div>

                  <div className="pt-4">
                    <button
                      type="submit"
                      disabled={isProfileSubmitting}
                      className="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-xl shadow-lg shadow-blue-200 hover:shadow-xl hover:shadow-blue-300 transition-all disabled:opacity-70 disabled:cursor-not-allowed"
                    >
                      {isProfileSubmitting ? 'Đang lưu...' : 'Lưu thay đổi'}
                    </button>
                  </div>
                </form>
              </div>
            )}

            {activeTab === 'security' && (
              <div className="animate-fade-in">
                <h3 className="text-xl font-bold text-gray-800 mb-6">Đổi mật khẩu</h3>
                <form onSubmit={handlePasswordSubmit(onPasswordSubmit)} className="space-y-6 max-w-md">
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Mật khẩu hiện tại</label>
                    <div className="relative">
                      <input
                        type={showCurrentPassword ? 'text' : 'password'}
                        {...registerPassword('currentPassword', { required: 'Vui lòng nhập mật khẩu hiện tại' })}
                        className={`w-full px-4 py-2.5 pr-12 rounded-xl border ${passwordErrors.currentPassword ? 'border-red-500' : 'border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-200'} transition-all outline-none`}
                        placeholder="••••••••"
                      />
                      <button
                        type="button"
                        onClick={() => setShowCurrentPassword(!showCurrentPassword)}
                        className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                      >
                        {showCurrentPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                      </button>
                    </div>
                    {passwordErrors.currentPassword && <p className="text-red-500 text-sm mt-1">{passwordErrors.currentPassword.message}</p>}
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Mật khẩu mới</label>
                    <div className="relative">
                      <input
                        type={showNewPassword ? 'text' : 'password'}
                        {...registerPassword('newPassword', { 
                          required: 'Vui lòng nhập mật khẩu mới',
                          minLength: { value: 6, message: 'Mật khẩu phải có ít nhất 6 ký tự' }
                        })}
                        className={`w-full px-4 py-2.5 pr-12 rounded-xl border ${passwordErrors.newPassword ? 'border-red-500' : 'border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-200'} transition-all outline-none`}
                        placeholder="••••••••"
                      />
                      <button
                        type="button"
                        onClick={() => setShowNewPassword(!showNewPassword)}
                        className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                      >
                        {showNewPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                      </button>
                    </div>
                    {passwordErrors.newPassword && <p className="text-red-500 text-sm mt-1">{passwordErrors.newPassword.message}</p>}
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Xác nhận mật khẩu mới</label>
                    <div className="relative">
                      <input
                        type={showConfirmPassword ? 'text' : 'password'}
                        {...registerPassword('confirmNewPassword', { 
                          required: 'Vui lòng xác nhận mật khẩu mới',
                          validate: val => val === watchPassword('newPassword') || 'Mật khẩu xác nhận không khớp'
                        })}
                        className={`w-full px-4 py-2.5 pr-12 rounded-xl border ${passwordErrors.confirmNewPassword ? 'border-red-500' : 'border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-200'} transition-all outline-none`}
                        placeholder="••••••••"
                      />
                      <button
                        type="button"
                        onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                        className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                      >
                        {showConfirmPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                      </button>
                    </div>
                    {passwordErrors.confirmNewPassword && <p className="text-red-500 text-sm mt-1">{passwordErrors.confirmNewPassword.message}</p>}
                  </div>

                  <div className="pt-4">
                    <button
                      type="submit"
                      disabled={isPasswordSubmitting}
                      className="px-6 py-2.5 bg-gray-900 hover:bg-black text-white font-medium rounded-xl shadow-lg shadow-gray-200 hover:shadow-xl transition-all disabled:opacity-70 disabled:cursor-not-allowed"
                    >
                      {isPasswordSubmitting ? 'Đang lưu...' : 'Cập nhật mật khẩu'}
                    </button>
                  </div>
                </form>
              </div>
            )}
            
          </div>
        </div>
      </div>
    </div>
  );
};
