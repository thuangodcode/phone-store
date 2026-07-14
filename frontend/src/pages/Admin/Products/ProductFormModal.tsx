import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import type { Product, CreateProductDto, UpdateProductDto, Brand, Category, ProductStorageVariantDto, ProductColorVariantDto } from '../../../types';
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
  const [imagesInput, setImagesInput] = useState('');

  // Variants state
  const [storageVariants, setStorageVariants] = useState<ProductStorageVariantDto[]>([]);
  const [colorVariants, setColorVariants] = useState<ProductColorVariantDto[]>([]);

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
      setStorageVariants(product.storageVariants || []);
      setColorVariants(product.colorVariants || []);
    } else {
      reset({
        name: '', description: '', price: 0, salePrice: 0, brandId: '', categoryId: '', stock: 0, images: [], specifications: {}, isActive: true
      });
      setImagesInput('');
      setStorageVariants([]);
      setColorVariants([]);
    }
  }, [product, isOpen, reset, brands, categories]);

  if (!isOpen) return null;

  const handleAddStorage = () => {
    setStorageVariants([...storageVariants, { storage: '', price: 0, salePrice: 0 }]);
  };

  const handleUpdateStorage = (index: number, field: keyof ProductStorageVariantDto, value: string | number) => {
    const newVariants = [...storageVariants];
    newVariants[index] = { ...newVariants[index], [field]: value };
    setStorageVariants(newVariants);
  };

  const handleRemoveStorage = (index: number) => {
    setStorageVariants(storageVariants.filter((_, i) => i !== index));
  };

  const handleAddColor = () => {
    setColorVariants([...colorVariants, { name: '', imageUrl: '', priceModifier: 0 }]);
  };

  const handleUpdateColor = (index: number, field: keyof ProductColorVariantDto, value: string | number) => {
    const newVariants = [...colorVariants];
    newVariants[index] = { ...newVariants[index], [field]: value };
    setColorVariants(newVariants);
  };

  const handleRemoveColor = (index: number) => {
    setColorVariants(colorVariants.filter((_, i) => i !== index));
  };

  const onSubmit = async (data: ProductFormValues) => {
    try {
      setIsLoading(true);
      const images = imagesInput.split(/\r?\n|,/).map(url => url.trim()).filter(url => url);
      const specs = data.specifications || {};

      const payload = {
        name: data.name,
        description: data.description,
        price: data.price,
        salePrice: data.salePrice,
        brandId: data.brandId,
        categoryId: data.categoryId,
        images,
        specifications: specs,
        stock: data.stock,
        storageVariants,
        colorVariants,
        promotions: product?.promotions || [], // Admin doesn't edit promos here, keeps old
      };

      if (product) {
        await adminApi.updateProduct(product.id, { ...payload, isActive: data.isActive ?? true } as UpdateProductDto);
        toast.success("Product updated successfully");
      } else {
        await adminApi.createProduct(payload as CreateProductDto);
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
      <div className="bg-white rounded-lg shadow-xl w-full max-w-3xl max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center p-6 border-b sticky top-0 bg-white z-10">
          <h2 className="text-xl font-bold">{product ? 'Edit Product' : 'Add New Product'}</h2>
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
          </button>
        </div>

        <form onSubmit={handleSubmit(onSubmit)} className="p-6 space-y-6">
          {/* Basic Info */}
          <div className="space-y-4 border-b pb-6">
            <h3 className="font-semibold text-lg">Thông tin cơ bản</h3>
            <div className="grid grid-cols-2 gap-4">
              <div className="col-span-2">
                <label className="block text-sm font-medium mb-1">Product Name</label>
                <input {...register('name', { required: true })} className="w-full border rounded-md px-3 py-2" />
                {errors.name && <span className="text-red-500 text-sm">Required</span>}
              </div>
              
              <div>
                <label className="block text-sm font-medium mb-1">Stock (Kho)</label>
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
              <label className="block text-sm font-medium mb-1">Image URLs (Global/Default images)</label>
              <textarea 
                value={imagesInput} 
                onChange={e => setImagesInput(e.target.value)} 
                rows={3} 
                placeholder="https://image1.jpg"
                className="w-full border rounded-md px-3 py-2"
              ></textarea>
            </div>
          </div>

          {/* Storage Variants */}
          <div className="space-y-4 border-b pb-6">
            <div className="flex justify-between items-center">
              <h3 className="font-semibold text-lg">Phiên bản dung lượng (Storage Variants)</h3>
              <button type="button" onClick={handleAddStorage} className="text-sm bg-gray-100 px-3 py-1 rounded hover:bg-gray-200">+ Thêm</button>
            </div>
            {storageVariants.map((variant, index) => (
              <div key={index} className="flex gap-2 items-center bg-gray-50 p-2 rounded">
                <input 
                  placeholder="Dung lượng (vd: 256GB)" 
                  value={variant.storage} 
                  onChange={e => handleUpdateStorage(index, 'storage', e.target.value)} 
                  className="flex-1 border px-2 py-1 rounded text-sm"
                />
                <input 
                  type="number"
                  placeholder="Giá gốc" 
                  value={variant.price} 
                  onChange={e => handleUpdateStorage(index, 'price', Number(e.target.value))} 
                  className="w-24 border px-2 py-1 rounded text-sm"
                />
                <input 
                  type="number"
                  placeholder="Giá KM" 
                  value={variant.salePrice} 
                  onChange={e => handleUpdateStorage(index, 'salePrice', Number(e.target.value))} 
                  className="w-24 border px-2 py-1 rounded text-sm"
                />
                <button type="button" onClick={() => handleRemoveStorage(index)} className="text-red-500 font-bold px-2">X</button>
              </div>
            ))}
          </div>

          {/* Color Variants */}
          <div className="space-y-4 border-b pb-6">
            <div className="flex justify-between items-center">
              <h3 className="font-semibold text-lg">Phiên bản màu sắc (Color Variants)</h3>
              <button type="button" onClick={handleAddColor} className="text-sm bg-gray-100 px-3 py-1 rounded hover:bg-gray-200">+ Thêm</button>
            </div>
            {colorVariants.map((variant, index) => (
              <div key={index} className="flex flex-col gap-2 bg-gray-50 p-3 rounded">
                <div className="flex gap-2">
                  <input 
                    placeholder="Tên màu (vd: Titan Tự Nhiên)" 
                    value={variant.name} 
                    onChange={e => handleUpdateColor(index, 'name', e.target.value)} 
                    className="flex-1 border px-2 py-1 rounded text-sm"
                  />
                  <input 
                    type="number"
                    placeholder="Giá chênh lệch (+/-)" 
                    value={variant.priceModifier} 
                    onChange={e => handleUpdateColor(index, 'priceModifier', Number(e.target.value))} 
                    className="w-32 border px-2 py-1 rounded text-sm"
                  />
                  <button type="button" onClick={() => handleRemoveColor(index)} className="text-red-500 font-bold px-2">X</button>
                </div>
                <input 
                  placeholder="Hình ảnh riêng của màu này (URL)" 
                  value={variant.imageUrl} 
                  onChange={e => handleUpdateColor(index, 'imageUrl', e.target.value)} 
                  className="w-full border px-2 py-1 rounded text-sm"
                />
              </div>
            ))}
          </div>

          {product && (
            <div className="flex items-center gap-2">
              <input type="checkbox" {...register('isActive')} id="isActive" className="h-4 w-4 text-blue-600 rounded" />
              <label htmlFor="isActive" className="text-sm text-gray-700">Active product</label>
            </div>
          )}

          <div className="flex justify-end pt-4 border-t gap-2 sticky bottom-0 bg-white z-10 py-4">
            <button type="button" onClick={onClose} className="px-4 py-2 border rounded-md text-gray-700 hover:bg-gray-50">Cancel</button>
            <button type="submit" disabled={isLoading} className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 shadow-md">
              {isLoading ? 'Saving...' : 'Save Product'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
