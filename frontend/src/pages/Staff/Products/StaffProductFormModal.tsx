import React, { useEffect, useState } from 'react';
import type { Product, UpdateProductDto } from '../../../types';
import { adminApi } from '../../../api/adminApi';
import { toast } from 'react-toastify';

interface StaffProductFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  product: Product;
  onSuccess: () => void;
}

export const StaffProductFormModal: React.FC<StaffProductFormModalProps> = ({ isOpen, onClose, product, onSuccess }) => {
  const [description, setDescription] = useState('');
  const [promotions, setPromotions] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (isOpen && product) {
      setDescription(product.description || '');
      setPromotions(product.promotions || []);
    }
  }, [product, isOpen]);

  if (!isOpen) return null;

  const handleAddPromotion = () => {
    setPromotions([...promotions, '']);
  };

  const handleUpdatePromotion = (index: number, value: string) => {
    const newPromotions = [...promotions];
    newPromotions[index] = value;
    setPromotions(newPromotions);
  };

  const handleRemovePromotion = (index: number) => {
    setPromotions(promotions.filter((_, i) => i !== index));
  };

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setIsLoading(true);
      
      const payload: UpdateProductDto = {
        name: product.name,
        description: description,
        price: product.price,
        salePrice: product.salePrice,
        brandId: product.brandId || '',
        categoryId: product.categoryId || '',
        images: product.images || [],
        specifications: product.specifications || {},
        stock: product.stock,
        isActive: product.isActive ?? true,
        storageVariants: product.storageVariants || [],
        colorVariants: product.colorVariants || [],
        promotions: promotions.filter(p => p.trim() !== '')
      };

      await adminApi.updateProduct(product.id, payload);
      toast.success("Product info updated successfully");
      onSuccess();
      onClose();
    } catch (error: any) {
      toast.error(error?.message || "Operation failed");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 overflow-y-auto pt-20 pb-10 px-4">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center p-6 border-b sticky top-0 bg-white z-10">
          <h2 className="text-xl font-bold">Cập nhật thông tin: {product.name}</h2>
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
          </button>
        </div>

        <form onSubmit={onSubmit} className="p-6 space-y-6">
          <div>
            <label className="block text-sm font-medium mb-1">Mô tả sản phẩm</label>
            <textarea 
              value={description}
              onChange={e => setDescription(e.target.value)}
              rows={6} 
              className="w-full border rounded-md px-3 py-2"
            ></textarea>
          </div>

          <div className="space-y-4 border-b pb-6">
            <div className="flex justify-between items-center">
              <label className="block text-sm font-medium">Khuyến mãi đi kèm</label>
              <button type="button" onClick={handleAddPromotion} className="text-sm bg-gray-100 px-3 py-1 rounded hover:bg-gray-200">+ Thêm khuyến mãi</button>
            </div>
            {promotions.map((promo, index) => (
              <div key={index} className="flex gap-2">
                <input 
                  value={promo} 
                  onChange={e => handleUpdatePromotion(index, e.target.value)} 
                  className="flex-1 border px-3 py-2 rounded-md"
                  placeholder="Nhập nội dung khuyến mãi..."
                />
                <button type="button" onClick={() => handleRemovePromotion(index)} className="text-red-500 font-bold px-3 hover:bg-red-50 rounded-md">Xoá</button>
              </div>
            ))}
          </div>

          <div className="flex justify-end pt-4 gap-2 sticky bottom-0 bg-white z-10 py-4">
            <button type="button" onClick={onClose} className="px-4 py-2 border rounded-md text-gray-700 hover:bg-gray-50">Huỷ bỏ</button>
            <button type="submit" disabled={isLoading} className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 shadow-md">
              {isLoading ? 'Đang lưu...' : 'Lưu thông tin'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
