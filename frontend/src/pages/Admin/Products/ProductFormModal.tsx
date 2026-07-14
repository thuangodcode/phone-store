import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import type { Product, CreateProductDto, UpdateProductDto, Brand, Category } from '../../../types';
import { adminApi } from '../../../api/adminApi';
import { toast } from 'react-toastify';

interface ProductFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  product: Product | null;
  onSuccess: () => void;
}

type ProductFormValues = CreateProductDto & { isActive?: boolean };

export const ProductFormModal: React.FC<ProductFormModalProps> = ({ isOpen, onClose, product, onSuccess }) => {
  const { register, handleSubmit, reset, formState: { errors } } = useForm<ProductFormValues>();
  const [brands, setBrands] = useState<Brand[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [imagesInput, setImagesInput] = useState(''); // Simple text input for comma-separated URLs

  useEffect(() => {
    const fetchOptions = async () => {
      try {
        const [bRes, cRes] = await Promise.all([
          adminApi.getBrands(),
          adminApi.getCategories()
        ]);
        setBrands(bRes);
        setCategories(cRes);
      } catch (err) {
        toast.error("Failed to load brands/categories");
      }
    };
    if (isOpen) fetchOptions();
  }, [isOpen]);

  useEffect(() => {
    if (product && isOpen) {
      const bId = (product as Product & { brandId?: string }).brandId || brands.find(b => b.name === product.brandName)?.id || '';
      const cId = (product as Product & { categoryId?: string }).categoryId || categories.find(c => c.name === product.categoryName)?.id || '';

      reset({
        name: product.name,
        description: product.description,
        price: product.price,
        salePrice: product.salePrice,
        brandId: bId,
        categoryId: cId,
        stock: product.stock,
        images: product.images,
        specifications: product.specifications || {},
        isActive: product.isActive ?? true
      });
      setImagesInput(product.images ? product.images.join('\n') : '');
    } else {
      reset({
        name: '', description: '', price: 0, salePrice: 0, brandId: '', categoryId: '', stock: 0, images: [], specifications: {}, isActive: true
      });
      setImagesInput('');
    }
  }, [product, isOpen, reset, brands, categories]);

  if (!isOpen) return null;

  const onSubmit = async (data: ProductFormValues) => {
    try {
      setIsLoading(true);
      const images = imagesInput.split(/\r?\n|,/).map(url => url.trim()).filter(url => url);
      const specs = data.specifications || {};

      if (product) {
        const updateData: UpdateProductDto = {
          name: data.name,
          description: data.description,
          price: data.price,
          salePrice: data.salePrice,
          brandId: data.brandId,
          categoryId: data.categoryId,
          images,
          specifications: specs,
          stock: data.stock,
          isActive: data.isActive ?? true
        };
        await adminApi.updateProduct(product.id, updateData);
        toast.success("Product updated successfully");
      } else {
        await adminApi.createProduct({
          name: data.name,
          description: data.description,
          price: data.price,
          salePrice: data.salePrice,
          brandId: data.brandId,
          categoryId: data.categoryId,
          images,
          specifications: specs,
          stock: data.stock
        });
        toast.success("Product created successfully");
      }
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
        <div className="flex justify-between items-center p-6 border-b">
          <h2 className="text-xl font-bold">{product ? 'Edit Product' : 'Add New Product'}</h2>
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
          </button>
        </div>

        <form onSubmit={handleSubmit(onSubmit)} className="p-6 space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1">Product Name</label>
              <input {...register('name', { required: true })} className="w-full border rounded-md px-3 py-2" />
              {errors.name && <span className="text-red-500 text-sm">Required</span>}
            </div>
            
            <div>
              <label className="block text-sm font-medium mb-1">Stock</label>
              <input type="number" {...register('stock', { required: true, min: 0 })} className="w-full border rounded-md px-3 py-2" />
            </div>

            <div>
              <label className="block text-sm font-medium mb-1">Regular Price ($)</label>
              <input type="number" {...register('price', { required: true, min: 0 })} className="w-full border rounded-md px-3 py-2" />
            </div>

            <div>
              <label className="block text-sm font-medium mb-1">Sale Price ($)</label>
              <input type="number" {...register('salePrice', { min: 0 })} className="w-full border rounded-md px-3 py-2" />
            </div>

            <div>
              <label className="block text-sm font-medium mb-1">Brand</label>
              <select {...register('brandId', { required: true })} className="w-full border rounded-md px-3 py-2">
                <option value="">Select Brand</option>
                {brands.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium mb-1">Category</label>
              <select {...register('categoryId', { required: true })} className="w-full border rounded-md px-3 py-2">
                <option value="">Select Category</option>
                {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Description</label>
            <textarea {...register('description', { required: true })} rows={4} className="w-full border rounded-md px-3 py-2"></textarea>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Image URLs (one per line or comma separated)</label>
            <textarea 
              value={imagesInput} 
              onChange={e => setImagesInput(e.target.value)} 
              rows={5} 
              placeholder="https://image1.jpg\nhttps://image2.jpg"
              className="w-full border rounded-md px-3 py-2"
            ></textarea>
            <p className="mt-2 text-xs text-gray-500">Use multiple lines or commas to enter image URLs for carousel/gallery.</p>
          </div>

          {product && (
            <div className="flex items-center gap-2">
              <input type="checkbox" {...register('isActive')} id="isActive" className="h-4 w-4 text-blue-600 rounded" />
              <label htmlFor="isActive" className="text-sm text-gray-700">Active product</label>
            </div>
          )}

          <div className="flex justify-end pt-4 border-t gap-2">
            <button type="button" onClick={onClose} className="px-4 py-2 border rounded-md text-gray-700 hover:bg-gray-50">Cancel</button>
            <button type="submit" disabled={isLoading} className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50">
              {isLoading ? 'Saving...' : 'Save Product'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
