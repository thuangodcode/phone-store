import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { adminApi } from '../../../api/adminApi';
import type { Brand, CreateBrandDto } from '../../../types';
import { toast } from 'react-toastify';

interface BrandFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  brand: Brand | null;
  onSuccess: () => void;
}

type BrandFormValues = CreateBrandDto & { isActive?: boolean };

export const BrandFormModal: React.FC<BrandFormModalProps> = ({ isOpen, onClose, brand, onSuccess }) => {
  const { register, handleSubmit, reset, formState: { errors } } = useForm<BrandFormValues>();
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (brand) {
      reset({ name: brand.name, logo: brand.logo || '', isActive: brand.isActive ?? true });
    } else {
      reset({ name: '', logo: '', isActive: true });
    }
  }, [brand, isOpen, reset]);

  if (!isOpen) return null;

  const onSubmit = async (data: BrandFormValues) => {
    try {
      setIsLoading(true);
      if (brand) {
        await adminApi.updateBrand(brand.id, { name: data.name, logo: data.logo, isActive: data.isActive ?? true });
        toast.success('Brand updated successfully');
      } else {
        await adminApi.createBrand({ name: data.name, logo: data.logo });
        toast.success('Brand created successfully');
      }
      onSuccess();
      onClose();
    } catch (error: any) {
      toast.error(error?.message || 'Operation failed');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 overflow-y-auto px-4 py-10">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-lg">
        <div className="flex justify-between items-center p-6 border-b">
          <h2 className="text-xl font-bold">{brand ? 'Edit Brand' : 'Add New Brand'}</h2>
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
          </button>
        </div>

        <form onSubmit={handleSubmit(onSubmit)} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">Brand Name</label>
            <input {...register('name', { required: true })} className="w-full border rounded-md px-3 py-2" />
            {errors.name && <span className="text-red-500 text-sm">Required</span>}
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Logo URL</label>
            <input {...register('logo')} className="w-full border rounded-md px-3 py-2" placeholder="https://..." />
          </div>

          {brand && (
            <label className="flex items-center gap-2 text-sm">
              <input type="checkbox" {...register('isActive')} />
              Active
            </label>
          )}

          <div className="flex justify-end pt-4 border-t gap-2">
            <button type="button" onClick={onClose} className="px-4 py-2 border rounded-md text-gray-700 hover:bg-gray-50">Cancel</button>
            <button type="submit" disabled={isLoading} className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50">
              {isLoading ? 'Saving...' : 'Save Brand'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
