import React, { useEffect, useState } from 'react';
import { adminApi } from '../../../api/adminApi';
import type { Voucher } from '../../../types';
import { VoucherFormModal } from './VoucherFormModal';
import { ActionButton, EditIcon, TrashIcon } from '../../../components/AdminActionButtons';
import { toast } from 'react-toastify';

export const AdminVouchersPage: React.FC = () => {
  const [vouchers, setVouchers] = useState<Voucher[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingVoucher, setEditingVoucher] = useState<Voucher | null>(null);

  const fetchVouchers = async () => {
    try {
      setIsLoading(true);
      const data = await adminApi.getVouchers();
      setVouchers(data);
    } catch (error) {
      toast.error('Failed to fetch vouchers');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchVouchers();
  }, []);

  const handleCreate = () => {
    setEditingVoucher(null);
    setIsModalOpen(true);
  };

  const handleEdit = (voucher: Voucher) => {
    setEditingVoucher(voucher);
    setIsModalOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (window.confirm('Are you sure you want to delete this voucher?')) {
      try {
        await adminApi.deleteVoucher(id);
        toast.success('Voucher deleted successfully');
        fetchVouchers();
      } catch (error) {
        toast.error('Failed to delete voucher');
      }
    }
  };

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Manage Vouchers</h1>
        <button onClick={handleCreate} className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md font-medium">
          + Add New Voucher
        </button>
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-200">
                <th className="p-4 font-medium text-gray-600">Code</th>
                <th className="p-4 font-medium text-gray-600">Discount</th>
                <th className="p-4 font-medium text-gray-600">Availability</th>
                <th className="p-4 font-medium text-gray-600">Status</th>
                <th className="p-4 font-medium text-gray-600 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {isLoading ? (
                <tr><td colSpan={5} className="p-8 text-center text-gray-500">Loading vouchers...</td></tr>
              ) : vouchers.length === 0 ? (
                <tr><td colSpan={5} className="p-8 text-center text-gray-500">No vouchers found.</td></tr>
              ) : (
                vouchers.map((voucher) => (
                  <tr key={voucher.id} className="hover:bg-gray-50">
                    <td className="p-4">
                      <div className="font-medium text-gray-900">{voucher.code}</div>
                      <div className="text-sm text-gray-500">{voucher.description || 'No description'}</div>
                    </td>
                    <td className="p-4 text-gray-600">{voucher.discountType === 'Percentage' ? `${voucher.discountValue}%` : `$${voucher.discountValue}`}</td>
                    <td className="p-4 text-gray-600">{voucher.quantity - voucher.used} left / {voucher.quantity} total</td>
                    <td className="p-4">
                      <span className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${voucher.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-700'}`}>
                        {voucher.isActive ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td className="p-4 text-right">
                      <div className="inline-flex items-center justify-end gap-2">
                        <ActionButton label="Edit" onClick={() => handleEdit(voucher)} icon={<EditIcon />} variant="secondary" />
                        <ActionButton label="Delete" onClick={() => handleDelete(voucher.id)} icon={<TrashIcon />} variant="danger" />
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <VoucherFormModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} voucher={editingVoucher} onSuccess={fetchVouchers} />
    </div>
  );
};
