import React, { useEffect, useState } from 'react';
import { adminApi } from '../../../api/adminApi';
import type { Brand } from '../../../types';
import { BrandFormModal } from './BrandFormModal';
import { ActionButton, EditIcon, TrashIcon } from '../../../components/AdminActionButtons';
import { toast } from 'react-toastify';

export const AdminBrandsPage: React.FC = () => {
  const [brands, setBrands] = useState<Brand[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingBrand, setEditingBrand] = useState<Brand | null>(null);

  const fetchBrands = async () => {
    try {
      setIsLoading(true);
      const data = await adminApi.getBrands();
      setBrands(data);
    } catch (error) {
      toast.error('Failed to fetch brands');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchBrands();
  }, []);

  const handleCreate = () => {
    setEditingBrand(null);
    setIsModalOpen(true);
  };

  const handleEdit = (brand: Brand) => {
    setEditingBrand(brand);
    setIsModalOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (window.confirm('Are you sure you want to delete this brand?')) {
      try {
        await adminApi.deleteBrand(id);
        toast.success('Brand deleted successfully');
        fetchBrands();
      } catch (error) {
        toast.error('Failed to delete brand');
      }
    }
  };

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Manage Brands</h1>
        <button onClick={handleCreate} className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md font-medium">
          + Add New Brand
        </button>
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-200">
                <th className="p-4 font-medium text-gray-600">Brand</th>
                <th className="p-4 font-medium text-gray-600">Status</th>
                <th className="p-4 font-medium text-gray-600">Created</th>
                <th className="p-4 font-medium text-gray-600 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {isLoading ? (
                <tr><td colSpan={4} className="p-8 text-center text-gray-500">Loading brands...</td></tr>
              ) : brands.length === 0 ? (
                <tr><td colSpan={4} className="p-8 text-center text-gray-500">No brands found.</td></tr>
              ) : (
                brands.map((brand) => (
                  <tr key={brand.id} className="hover:bg-gray-50">
                    <td className="p-4">
                      <div className="flex items-center gap-3">
                        <img src={brand.logo || 'https://placehold.co/40x40'} alt={brand.name} className="w-10 h-10 rounded object-cover" />
                        <span className="font-medium text-gray-900">{brand.name}</span>
                      </div>
                    </td>
                    <td className="p-4">
                      <span className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${brand.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-700'}`}>
                        {brand.isActive ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td className="p-4 text-gray-600">{brand.createdAt ? new Date(brand.createdAt).toLocaleDateString() : '—'}</td>
                    <td className="p-4 text-right">
                      <div className="inline-flex items-center justify-end gap-2">
                        <ActionButton label="Edit" onClick={() => handleEdit(brand)} icon={<EditIcon />} variant="secondary" />
                        <ActionButton label="Delete" onClick={() => handleDelete(brand.id)} icon={<TrashIcon />} variant="danger" />
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <BrandFormModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} brand={editingBrand} onSuccess={fetchBrands} />
    </div>
  );
};
