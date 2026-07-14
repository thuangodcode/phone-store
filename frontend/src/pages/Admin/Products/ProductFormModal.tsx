import React, { useEffect, useState } from 'react';
import { useForm, Controller } from 'react-hook-form';
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

// Currency Input Component for thousand separators
const CurrencyInput = ({ value, onChange, placeholder, className }: { value: number, onChange: (v: number) => void, placeholder?: string, className?: string }) => {
  const [displayValue, setDisplayValue] = useState(value ? new Intl.NumberFormat('vi-VN').format(value) : '');

  useEffect(() => {
    // Only update display if value changes externally
    if (value && parseInt(displayValue.replace(/\./g, ''), 10) !== value) {
      setDisplayValue(new Intl.NumberFormat('vi-VN').format(value));
    } else if (!value && displayValue !== '') {
      setDisplayValue('');
    }
  }, [value]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const rawValue = e.target.value.replace(/\./g, '');
    if (rawValue === '') {
      setDisplayValue('');
      onChange(0);
      return;
    }
    const num = parseInt(rawValue, 10);
    if (!isNaN(num)) {
      setDisplayValue(new Intl.NumberFormat('vi-VN').format(num));
      onChange(num);
    }
  };

  return (
    <div className="relative flex items-center">
      <input
        type="text"
        placeholder={placeholder}
        value={displayValue}
        onChange={handleChange}
        className={className}
      />
      <span className="absolute right-3 text-gray-500 font-medium text-sm">đ</span>
    </div>
  );
};

export const ProductFormModal: React.FC<ProductFormModalProps> = ({ isOpen, onClose, product, onSuccess }) => {
  const { register, handleSubmit, reset, control, formState: { errors } } = useForm<ProductFormValues>();
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

  const globalImagesPreview = imagesInput.split(/\r?\n|,/).map(url => url.trim()).filter(url => url);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 overflow-y-auto pt-20 pb-10 px-4">
      <div className="bg-white rounded-lg shadow-2xl w-full max-w-5xl max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center p-6 border-b sticky top-0 bg-white z-20 shadow-sm">
          <h2 className="text-2xl font-bold text-gray-800">{product ? 'Edit Product' : 'Add New Product'}</h2>
          <button onClick={onClose} className="text-gray-500 hover:text-red-500 transition-colors p-2 rounded-full hover:bg-red-50">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
          </button>
        </div>

        <form onSubmit={handleSubmit(onSubmit)} className="p-8 space-y-8 bg-gray-50/50">
          {/* Basic Info */}
          <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm space-y-6">
            <h3 className="font-bold text-xl text-gray-800 border-b pb-3">Basic Information</h3>
            <div className="grid grid-cols-2 gap-6">
              <div className="col-span-2">
                <label className="block text-sm font-semibold text-gray-700 mb-1">Product Name</label>
                <input {...register('name', { required: true })} className="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:ring-2 focus:ring-blue-500 outline-none transition-all" placeholder="Enter product name..." />
                {errors.name && <span className="text-red-500 text-sm mt-1 block">Product name is required</span>}
              </div>
              
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1">Stock (Kho)</label>
                <input type="number" {...register('stock', { required: true, min: 0 })} className="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:ring-2 focus:ring-blue-500 outline-none transition-all" />
              </div>

              <div className="grid grid-cols-2 gap-4 col-span-2 md:col-span-1">
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1">Regular Price (VND)</label>
                  <Controller
                    name="price"
                    control={control}
                    rules={{ required: true, min: 0 }}
                    render={({ field }) => (
                      <CurrencyInput value={field.value} onChange={field.onChange} className="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:ring-2 focus:ring-blue-500 outline-none pr-8" placeholder="0" />
                    )}
                  />
                </div>
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1">Sale Price (VND)</label>
                  <Controller
                    name="salePrice"
                    control={control}
                    rules={{ min: 0 }}
                    render={({ field }) => (
                      <CurrencyInput value={field.value} onChange={field.onChange} className="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:ring-2 focus:ring-blue-500 outline-none pr-8" placeholder="0" />
                    )}
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1">Brand</label>
                <select {...register('brandId', { required: true })} className="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:ring-2 focus:ring-blue-500 outline-none bg-white">
                  <option value="">Select Brand</option>
                  {brands.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
                </select>
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1">Category</label>
                <select {...register('categoryId', { required: true })} className="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:ring-2 focus:ring-blue-500 outline-none bg-white">
                  <option value="">Select Category</option>
                  {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
              </div>
            </div>
            
            <div className="pt-2">
              <label className="block text-sm font-semibold text-gray-700 mb-2">Image URLs (Global/Default images - 1 URL per line)</label>
              <div className="flex gap-4">
                <textarea 
                  value={imagesInput} 
                  onChange={e => setImagesInput(e.target.value)} 
                  rows={4} 
                  placeholder="https://image1.jpg&#10;https://image2.jpg"
                  className="flex-1 border border-gray-300 rounded-lg px-4 py-3 focus:ring-2 focus:ring-blue-500 outline-none"
                ></textarea>
                <div className="w-48 bg-gray-50 border rounded-lg p-2 flex flex-wrap gap-2 overflow-y-auto max-h-32">
                  {globalImagesPreview.length === 0 ? (
                    <div className="w-full h-full flex items-center justify-center text-gray-400 text-xs text-center">Image Preview</div>
                  ) : (
                    globalImagesPreview.map((url, i) => (
                      <img key={i} src={url} alt="preview" className="w-12 h-12 object-contain bg-white border rounded" />
                    ))
                  )}
                </div>
              </div>
            </div>
          </div>

          {/* Storage Variants */}
          <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm space-y-4">
            <div className="flex justify-between items-center border-b pb-3">
              <h3 className="font-bold text-xl text-gray-800">Storage Variants</h3>
              <button type="button" onClick={handleAddStorage} className="text-sm font-bold bg-blue-50 text-blue-600 border border-blue-200 px-4 py-1.5 rounded-lg hover:bg-blue-100 transition">+ Add Storage</button>
            </div>
            {storageVariants.map((variant, index) => (
              <div key={index} className="flex gap-4 items-end bg-gray-50 p-4 rounded-xl border border-gray-100">
                <div className="flex-1">
                  <span className="text-xs text-gray-500 font-bold uppercase tracking-wider mb-1 block">Storage Size</span>
                  <select 
                    value={variant.storage} 
                    onChange={e => handleUpdateStorage(index, 'storage', e.target.value)} 
                    className="w-full border border-gray-300 px-3 py-2.5 rounded-lg text-sm bg-white outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="">Select Storage</option>
                    <option value="64GB">64GB</option>
                    <option value="128GB">128GB</option>
                    <option value="256GB">256GB</option>
                    <option value="512GB">512GB</option>
                    <option value="1TB">1TB</option>
                  </select>
                </div>
                <div className="flex-1">
                  <span className="text-xs text-gray-500 font-bold uppercase tracking-wider mb-1 block">Regular Price</span>
                  <CurrencyInput 
                    value={variant.price} 
                    onChange={v => handleUpdateStorage(index, 'price', v)} 
                    className="w-full border border-gray-300 px-3 py-2.5 rounded-lg text-sm bg-white outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div className="flex-1">
                  <span className="text-xs text-gray-500 font-bold uppercase tracking-wider mb-1 block">Sale Price</span>
                  <CurrencyInput 
                    value={variant.salePrice} 
                    onChange={v => handleUpdateStorage(index, 'salePrice', v)} 
                    className="w-full border border-gray-300 px-3 py-2.5 rounded-lg text-sm bg-white outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <button type="button" onClick={() => handleRemoveStorage(index)} className="h-[42px] px-3 text-red-500 hover:bg-red-50 rounded-lg border border-transparent hover:border-red-200 transition font-bold">X</button>
              </div>
            ))}
            {storageVariants.length === 0 && <p className="text-center text-gray-400 py-4 text-sm">No storage variants added yet.</p>}
          </div>

          {/* Color Variants */}
          <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm space-y-4">
            <div className="flex justify-between items-center border-b pb-3">
              <h3 className="font-bold text-xl text-gray-800">Color Variants</h3>
              <button type="button" onClick={handleAddColor} className="text-sm font-bold bg-blue-50 text-blue-600 border border-blue-200 px-4 py-1.5 rounded-lg hover:bg-blue-100 transition">+ Add Color</button>
            </div>
            {colorVariants.map((variant, index) => (
              <div key={index} className="flex gap-6 items-start bg-gray-50 p-4 rounded-xl border border-gray-100">
                <div className="w-20 h-20 bg-white border border-gray-200 rounded-lg overflow-hidden flex-shrink-0 flex items-center justify-center">
                  {variant.imageUrl ? (
                    <img src={variant.imageUrl} alt="Color preview" className="w-full h-full object-contain" />
                  ) : (
                    <span className="text-xs text-gray-400 text-center px-2">No Image</span>
                  )}
                </div>
                <div className="flex-1 space-y-3">
                  <div className="flex gap-4 items-end">
                    <div className="flex-1">
                      <span className="text-xs text-gray-500 font-bold uppercase tracking-wider mb-1 block">Color Name</span>
                      <input 
                        placeholder="e.g., Natural Titanium" 
                        value={variant.name} 
                        onChange={e => handleUpdateColor(index, 'name', e.target.value)} 
                        className="w-full border border-gray-300 px-3 py-2 rounded-lg text-sm bg-white outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                    <div className="w-48">
                      <span className="text-xs text-gray-500 font-bold uppercase tracking-wider mb-1 block">Price Modifier (+/-)</span>
                      <CurrencyInput 
                        value={variant.priceModifier} 
                        onChange={v => handleUpdateColor(index, 'priceModifier', v)} 
                        className="w-full border border-gray-300 px-3 py-2 rounded-lg text-sm bg-white outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                    <button type="button" onClick={() => handleRemoveColor(index)} className="h-[38px] px-3 text-red-500 hover:bg-red-50 rounded-lg border border-transparent hover:border-red-200 transition font-bold">X</button>
                  </div>
                  <div>
                    <span className="text-xs text-gray-500 font-bold uppercase tracking-wider mb-1 block">Image URL</span>
                    <input 
                      placeholder="https://..." 
                      value={variant.imageUrl} 
                      onChange={e => handleUpdateColor(index, 'imageUrl', e.target.value)} 
                      className="w-full border border-gray-300 px-3 py-2 rounded-lg text-sm bg-white outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </div>
              </div>
            ))}
            {colorVariants.length === 0 && <p className="text-center text-gray-400 py-4 text-sm">No color variants added yet.</p>}
          </div>

          {product && (
            <div className="flex items-center gap-2 p-4 bg-white rounded-xl border border-gray-200">
              <input type="checkbox" {...register('isActive')} id="isActive" className="h-5 w-5 text-blue-600 rounded cursor-pointer" />
              <label htmlFor="isActive" className="text-sm font-semibold text-gray-700 cursor-pointer">Active product (Visible to customers)</label>
            </div>
          )}

          <div className="flex justify-end pt-4 gap-3 sticky bottom-0 bg-white z-20 py-4 border-t border-gray-200 px-2">
            <button type="button" onClick={onClose} className="px-6 py-2.5 border border-gray-300 rounded-lg text-gray-700 font-semibold hover:bg-gray-50 transition">Cancel</button>
            <button type="submit" disabled={isLoading} className="px-6 py-2.5 bg-blue-600 text-white rounded-lg font-bold hover:bg-blue-700 disabled:opacity-50 shadow-lg shadow-blue-600/30 transition transform active:scale-95">
              {isLoading ? 'Saving...' : 'Save Product Data'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
