import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { adminApi } from '../../../api/adminApi';
import type { CreateVoucherDto, Voucher } from '../../../types';
import { toast } from 'react-toastify';

interface VoucherFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  voucher: Voucher | null;
  onSuccess: () => void;
}

type VoucherFormValues = CreateVoucherDto & { isActive?: boolean };

const toInputValue = (value?: string) => {
  if (!value) return '';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '';
  const localDate = new Date(date.getTime() - date.getTimezoneOffset() * 60000);
  return localDate.toISOString().slice(0, 16);
};

export const VoucherFormModal: React.FC<VoucherFormModalProps> = ({ isOpen, onClose, voucher, onSuccess }) => {
  const { register, handleSubmit, reset, formState: { errors } } = useForm<VoucherFormValues>();
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (voucher) {
      reset({
        code: voucher.code,
        description: voucher.description,
        discountType: voucher.discountType,
        discountValue: voucher.discountValue,
        minOrderAmount: voucher.minOrderAmount,
        maxDiscount: voucher.maxDiscount,
        quantity: voucher.quantity,
        startDate: toInputValue(voucher.startDate),
        endDate: toInputValue(voucher.endDate),
        isActive: voucher.isActive ?? true,
      });
    } else {
      reset({
        code: '',
        description: '',
        discountType: 'Percentage',
        discountValue: 0,
        minOrderAmount: 0,
        maxDiscount: 0,
        quantity: 1,
        startDate: '',
        endDate: '',
        isActive: true,
      });
    }
  }, [voucher, isOpen, reset]);

  if (!isOpen) return null;

  const onSubmit = async (data: VoucherFormValues) => {
    try {
      setIsLoading(true);
      const payload = {
        code: data.code,
        description: data.description,
        discountType: data.discountType,
        discountValue: Number(data.discountValue),
        minOrderAmount: Number(data.minOrderAmount),
        maxDiscount: Number(data.maxDiscount),
        quantity: Number(data.quantity),
        startDate: new Date(data.startDate).toISOString(),
        endDate: new Date(data.endDate).toISOString(),
      };

      if (voucher) {
        await adminApi.updateVoucher(voucher.id, { ...payload, isActive: data.isActive ?? true });
        toast.success('Voucher updated successfully');
      } else {
        await adminApi.createVoucher(payload);
        toast.success('Voucher created successfully');
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
      <div className="bg-white rounded-lg shadow-xl w-full max-w-2xl">
        <div className="flex justify-between items-center p-6 border-b">
          <h2 className="text-xl font-bold">{voucher ? 'Edit Voucher' : 'Add New Voucher'}</h2>
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
          </button>
        </div>

        <form onSubmit={handleSubmit(onSubmit)} className="p-6 grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium mb-1">Code</label>
            <input {...register('code', { required: true })} className="w-full border rounded-md px-3 py-2" disabled={Boolean(voucher)} />
            {errors.code && <span className="text-red-500 text-sm">Required</span>}
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Discount Type</label>
            <select {...register('discountType')} className="w-full border rounded-md px-3 py-2">
              <option value="Percentage">Percentage</option>
              <option value="Fixed">Fixed</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Discount Value</label>
            <input type="number" step="0.01" {...register('discountValue', { required: true, min: 0 })} className="w-full border rounded-md px-3 py-2" />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Minimum Order Amount</label>
            <input type="number" step="0.01" {...register('minOrderAmount', { required: true, min: 0 })} className="w-full border rounded-md px-3 py-2" />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Max Discount</label>
            <input type="number" step="0.01" {...register('maxDiscount', { required: true, min: 0 })} className="w-full border rounded-md px-3 py-2" />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Quantity</label>
            <input type="number" {...register('quantity', { required: true, min: 1 })} className="w-full border rounded-md px-3 py-2" />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Start Date</label>
            <input type="datetime-local" {...register('startDate', { required: true })} className="w-full border rounded-md px-3 py-2" />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">End Date</label>
            <input type="datetime-local" {...register('endDate', { required: true })} className="w-full border rounded-md px-3 py-2" />
          </div>

          <div className="col-span-2">
            <label className="block text-sm font-medium mb-1">Description</label>
            <textarea {...register('description')} rows={3} className="w-full border rounded-md px-3 py-2"></textarea>
          </div>

          {voucher && (
            <label className="col-span-2 flex items-center gap-2 text-sm">
              <input type="checkbox" {...register('isActive')} />
              Active
            </label>
          )}

          <div className="col-span-2 flex justify-end pt-4 border-t gap-2">
            <button type="button" onClick={onClose} className="px-4 py-2 border rounded-md text-gray-700 hover:bg-gray-50">Cancel</button>
            <button type="submit" disabled={isLoading} className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50">
              {isLoading ? 'Saving...' : 'Save Voucher'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
