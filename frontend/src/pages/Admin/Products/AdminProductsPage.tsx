import React, { useEffect, useState } from 'react';
import { adminApi } from '../../../api/adminApi';
import type { Product } from '../../../types';
import { ProductFormModal } from './ProductFormModal';
import { ActionButton, EditIcon, TrashIcon } from '../../../components/AdminActionButtons';
import { toast } from 'react-toastify';

export const AdminProductsPage: React.FC = () => {
  const [products, setProducts] = useState<Product[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [toggleLoadingId, setToggleLoadingId] = useState<string | null>(null);

  const fetchProducts = async () => {
    try {
      setIsLoading(true);
      const res = await adminApi.getProducts(1, 50, true); // includeInactive=true to see all products
      setProducts(res.items);
    } catch (err) {
      toast.error("Failed to fetch products");
    } finally {
      setIsLoading(false);
    }
  };

  const handleToggleStatus = async (product: Product) => {
    const currentStatus = product.isActive ?? true;
    if (!window.confirm(`Are you sure you want to ${currentStatus ? 'deactivate' : 'activate'} this product?`)) {
      return;
    }

    try {
      setToggleLoadingId(product.id);

      await adminApi.updateProduct(product.id, {
        name: product.name,
        description: product.description,
        price: product.price,
        salePrice: product.salePrice,
        brandId: product.brandId ?? '',
        categoryId: product.categoryId ?? '',
        images: product.images ?? [],
        specifications: product.specifications ?? {},
        stock: product.stock,
        isActive: !currentStatus,
      });

      toast.success(`Product ${currentStatus ? 'deactivated' : 'activated'} successfully`);
      fetchProducts();
    } catch (err) {
      toast.error("Failed to update product status");
    } finally {
      setToggleLoadingId(null);
    }
  };


  useEffect(() => {
    fetchProducts();
  }, []);

  const handleCreate = () => {
    setEditingProduct(null);
    setIsModalOpen(true);
  };

  const handleEdit = (product: Product) => {
    setEditingProduct(product);
    setIsModalOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (window.confirm('Are you sure you want to delete this product?')) {
      try {
        await adminApi.deleteProduct(id);
        toast.success("Product deleted successfully");
        fetchProducts();
      } catch (err) {
        toast.error("Failed to delete product");
      }
    }
  };

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Manage Products</h1>
        <button 
          onClick={handleCreate}
          className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md font-medium"
        >
          + Add New Product
        </button>
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-200">
                <th className="p-4 font-medium text-gray-600">Product</th>
                <th className="p-4 font-medium text-gray-600">Price</th>
                <th className="p-4 font-medium text-gray-600">Brand</th>
                <th className="p-4 font-medium text-gray-600">Category</th>
                <th className="p-4 font-medium text-gray-600">Status</th>
                <th className="p-4 font-medium text-gray-600">Stock</th>
                <th className="p-4 font-medium text-gray-600 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {isLoading ? (
                <tr><td colSpan={7} className="p-8 text-center text-gray-500">Loading products...</td></tr>
              ) : products.length === 0 ? (
                <tr><td colSpan={7} className="p-8 text-center text-gray-500">No products found.</td></tr>
              ) : (
                products.map(product => {
                  const isActive = product.isActive ?? true;
                  return (
                    <tr key={product.id} className="hover:bg-gray-50">
                      <td className="p-4">
                        <div className="flex items-center gap-3">
                          <img src={product.images?.[0] || 'https://via.placeholder.com/40'} alt={product.name} className="w-10 h-10 rounded object-cover" />
                          <span className="font-medium text-gray-900">{product.name}</span>
                        </div>
                      </td>
                      <td className="p-4 text-gray-600">${product.price.toLocaleString()}</td>
                      <td className="p-4 text-gray-600">{product.brandName}</td>
                      <td className="p-4 text-gray-600">{product.categoryName}</td>
                      <td className="p-4">
                        <button
                          type="button"
                          onClick={() => handleToggleStatus(product)}
                          disabled={toggleLoadingId === product.id}
                          className={`relative inline-flex h-8 w-14 items-center rounded-full transition-colors duration-200 ease-in-out ${isActive ? 'bg-green-500' : 'bg-black'} ${toggleLoadingId === product.id ? 'opacity-60 cursor-not-allowed' : 'cursor-pointer'}`}
                        >
                          <span className={`ml-1 inline-block h-6 w-6 transform rounded-full bg-white shadow transition-transform duration-200 ease-in-out ${isActive ? 'translate-x-6' : 'translate-x-0'}`} />
                        </button>
                      </td>
                      <td className="p-4 text-gray-600">{product.stock}</td>
                      <td className="p-4 text-right">
                        <div className="inline-flex items-center justify-end gap-2">
                          <ActionButton label="Edit" onClick={() => handleEdit(product)} icon={<EditIcon />} variant="secondary" />
                          <ActionButton label="Delete" onClick={() => handleDelete(product.id)} icon={<TrashIcon />} variant="danger" />
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      <ProductFormModal 
        isOpen={isModalOpen} 
        onClose={() => setIsModalOpen(false)} 
        product={editingProduct} 
        onSuccess={fetchProducts} 
      />
    </div>
  );
};
