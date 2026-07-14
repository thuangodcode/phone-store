import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { adminApi } from '../../../api/adminApi';
import type { Category, CreateCategoryDto } from '../../../types';
import { toast } from 'react-toastify';

interface CategoryFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  category: Category | null;
  onSuccess: () => void;
}

type CategoryFormValues = CreateCategoryDto & { isActive?: boolean };

export const CategoryFormModal: React.FC<CategoryFormModalProps> = ({ isOpen, onClose, category, onSuccess }) => {
  const { register, handleSubmit, reset, formState: { errors } } = useForm<CategoryFormValues>();
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (category) {
      reset({ name: category.name, description: category.description || '', isActive: category.isActive ?? true });
    } else {
      reset({ name: '', description: '', isActive: true });
    }
  }, [category, isOpen, reset]);

  if (!isOpen) return null;

  const onSubmit = async (data: CategoryFormValues) => {
    try {
      setIsLoading(true);
      if (category) {
        await adminApi.updateCategory(category.id, { name: data.name, description: data.description, isActive: data.isActive ?? true });
        toast.success('Cập nhật danh mục thành công');
      } else {
        await adminApi.createCategory({ name: data.name, description: data.description });
        toast.success('Thêm danh mục thành công');
      }
      onSuccess();
      onClose();
    } catch (error: any) {
      toast.error(error?.message || 'Có lỗi xảy ra');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 overflow-y-auto px-4 py-10">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-lg">
        <div className="flex justify-between items-center p-6 border-b">
          <h2 className="text-xl font-bold">{category ? 'Chỉnh sửa Danh mục' : 'Thêm Danh mục Mới'}</h2>
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
          </button>
        </div>

        <form onSubmit={handleSubmit(onSubmit)} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">Tên danh mục *</label>
            <input {...register('name', { required: true })} className="w-full border rounded-md px-3 py-2" />
            {errors.name && <span className="text-red-500 text-sm">Bắt buộc nhập</span>}
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Mô tả</label>
            <textarea {...register('description')} rows={4} className="w-full border rounded-md px-3 py-2"></textarea>
          </div>

          {category && (
            <label className="flex items-center gap-2 text-sm">
              <input type="checkbox" {...register('isActive')} />
              Đang hoạt động
            </label>
          )}

          <div className="flex justify-end pt-4 border-t gap-2">
            <button type="button" onClick={onClose} className="px-4 py-2 border rounded-md text-gray-700 hover:bg-gray-50">Hủy</button>
            <button type="submit" disabled={isLoading} className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50">
              {isLoading ? 'Đang lưu...' : 'Lưu Danh mục'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
