import React, { useEffect, useState } from 'react';
import { adminApi } from '../../../api/adminApi';
import type { Product } from '../../../types';
import { StaffProductFormModal } from './StaffProductFormModal';
import { ActionButton, EditIcon } from '../../../components/AdminActionButtons';
import { toast } from 'react-toastify';

export const StaffProductsPage: React.FC = () => {
  const [products, setProducts] = useState<Product[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);

  const fetchProducts = async () => {
    try {
      setIsLoading(true);
      const res = await adminApi.getProducts(1, 50, true);
      setProducts(res.items);
    } catch (err) {
      toast.error("Failed to fetch products");
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchProducts();
  }, []);

  const handleEdit = (product: Product) => {
    setEditingProduct(product);
    setIsModalOpen(true);
  };

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Manage Products Info (Staff)</h1>
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-200">
                <th className="p-4 font-medium text-gray-600">Product</th>
                <th className="p-4 font-medium text-gray-600">Brand</th>
                <th className="p-4 font-medium text-gray-600">Category</th>
                <th className="p-4 font-medium text-gray-600 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {isLoading ? (
                <tr><td colSpan={4} className="p-8 text-center text-gray-500">Loading products...</td></tr>
              ) : products.length === 0 ? (
                <tr><td colSpan={4} className="p-8 text-center text-gray-500">No products found.</td></tr>
              ) : (
                products.map(product => (
                  <tr key={product.id} className="hover:bg-gray-50">
                    <td className="p-4">
                      <div className="flex items-center gap-3">
                        <img src={product.images?.[0] || 'https://via.placeholder.com/40'} alt={product.name} className="w-10 h-10 rounded object-cover" />
                        <span className="font-medium text-gray-900">{product.name}</span>
                      </div>
                    </td>
                    <td className="p-4 text-gray-600">{product.brandName}</td>
                    <td className="p-4 text-gray-600">{product.categoryName}</td>
                    <td className="p-4 text-right">
                      <ActionButton label="Edit Info" onClick={() => handleEdit(product)} icon={<EditIcon />} variant="secondary" />
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {editingProduct && (
        <StaffProductFormModal 
          isOpen={isModalOpen} 
          onClose={() => setIsModalOpen(false)} 
          product={editingProduct} 
          onSuccess={fetchProducts} 
        />
      )}
    </div>
  );
};
