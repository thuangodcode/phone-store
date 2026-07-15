import React, { useEffect, useState } from 'react';
import { adminApi } from '../../../api/adminApi';
import { toast } from 'react-toastify';
import { ImageIcon, Power } from 'lucide-react';
import type { Banner } from '../../../types';

export const StaffBannersPage: React.FC = () => {
  const [banners, setBanners] = useState<Banner[]>([]);
  const [loading, setLoading] = useState(true);
  
  const [formData, setFormData] = useState({ title: '', imageUrl: '', isActive: true });
  const [editingId, setEditingId] = useState<string | null>(null);

  const fetchBanners = async () => {
    setLoading(true);
    try {
      const data = await adminApi.getBanners();
      setBanners(data || []);
    } catch (error) {
      toast.error('Lỗi khi tải danh sách Ảnh nền');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBanners();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (editingId) {
        await adminApi.updateBanner(editingId, formData);
        toast.success('Cập nhật thành công');
      } else {
        await adminApi.createBanner(formData);
        toast.success('Thêm ảnh nền thành công');
      }
      setFormData({ title: '', imageUrl: '', isActive: true });
      setEditingId(null);
      fetchBanners();
    } catch (error) {
      toast.error('Có lỗi xảy ra');
    }
  };

  const handleEdit = (banner: Banner) => {
    setEditingId(banner.id);
    setFormData({ title: banner.title, imageUrl: banner.imageUrl, isActive: banner.isActive });
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm('Bạn có chắc chắn muốn xoá ảnh nền này?')) return;
    try {
      await adminApi.deleteBanner(id);
      toast.success('Xoá thành công');
      fetchBanners();
    } catch (error) {
      toast.error('Lỗi khi xoá');
    }
  };

  const handleToggleStatus = async (id: string) => {
    try {
      await adminApi.toggleBannerStatus(id);
      toast.success('Đã thay đổi trạng thái');
      fetchBanners();
    } catch (error) {
      toast.error('Lỗi khi đổi trạng thái');
    }
  };

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-6">Quản lý Ảnh nền (Banners)</h1>
      
      <div className="bg-white p-8 rounded-xl shadow-sm border border-gray-200 mb-8 max-w-4xl mx-auto">
        <h2 className="text-lg font-bold mb-6 pb-2 border-b">{editingId ? 'Chỉnh sửa Ảnh nền' : 'Thêm Ảnh nền mới'}</h2>
        <form onSubmit={handleSubmit} className="space-y-6">
          
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">Tiêu đề (Ghi chú)</label>
            <input 
              type="text" 
              required 
              value={formData.title} 
              onChange={e => setFormData({...formData, title: e.target.value})} 
              className="w-full px-4 py-3 rounded-lg border focus:ring-2 focus:ring-blue-500 outline-none" 
              placeholder="VD: Ảnh nền Tết 2026..." 
            />
          </div>

          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">Hình ảnh</label>
            <div className="relative group rounded-2xl overflow-hidden border-2 border-dashed border-gray-300 bg-gray-50 flex flex-col items-center justify-center min-h-[300px] transition-all hover:border-blue-400">
              {formData.imageUrl ? (
                <div className="relative w-full h-full">
                  <img src={formData.imageUrl} alt="Preview" className="w-full h-full object-cover" />
                  <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                    <input 
                      type="url" 
                      required
                      value={formData.imageUrl} 
                      onChange={e => setFormData({...formData, imageUrl: e.target.value})} 
                      className="w-3/4 px-4 py-3 rounded-lg bg-white/95 focus:ring-2 focus:ring-blue-500 outline-none shadow-lg text-sm" 
                      placeholder="Sửa Link Ảnh (URL)..." 
                    />
                  </div>
                </div>
              ) : (
                <div className="p-16 text-center w-full">
                  <ImageIcon className="mx-auto h-16 w-16 text-gray-400 mb-4" />
                  <input 
                    type="url" 
                    required
                    value={formData.imageUrl} 
                    onChange={e => setFormData({...formData, imageUrl: e.target.value})} 
                    className="w-full max-w-lg mx-auto px-4 py-3 text-sm rounded-lg border focus:ring-2 focus:ring-blue-500 outline-none shadow-sm" 
                    placeholder="Dán Link Ảnh (URL) vào đây để xem trước..." 
                  />
                  <p className="mt-4 text-xs text-gray-500">Kích thước khuyến nghị: 1920x600 px</p>
                </div>
              )}
            </div>
          </div>
          
          {!editingId && (
            <label className="flex items-center gap-2 cursor-pointer">
              <input 
                type="checkbox" 
                checked={formData.isActive}
                onChange={e => setFormData({...formData, isActive: e.target.checked})}
                className="w-4 h-4 text-blue-600 rounded border-gray-300 focus:ring-blue-500"
              />
              <span className="text-sm font-medium text-gray-700">Kích hoạt làm Ảnh nền chính thức ngay lập tức</span>
            </label>
          )}

          <div className="flex gap-3 pt-6 justify-end border-t">
            {editingId && (
              <button 
                type="button" 
                onClick={() => { setEditingId(null); setFormData({ title: '', imageUrl: '', isActive: true }); }} 
                className="bg-gray-100 text-gray-700 px-6 py-2.5 rounded-lg font-medium hover:bg-gray-200 transition-colors"
              >
                Huỷ
              </button>
            )}
            <button 
              type="submit" 
              className="bg-blue-600 text-white px-8 py-2.5 rounded-lg font-medium hover:bg-blue-700 shadow-md transition-all hover:-translate-y-0.5"
            >
              {editingId ? 'Lưu thay đổi' : 'Tạo mới'}
            </button>
          </div>
        </form>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden max-w-4xl mx-auto">
        <div className="px-6 py-4 border-b bg-gray-50/50 flex justify-between items-center">
          <h2 className="font-bold text-gray-800">Danh sách Ảnh nền</h2>
          <span className="text-sm text-gray-500">{banners.length} ảnh</span>
        </div>
        {loading ? (
          <div className="p-8 text-center text-gray-500">Đang tải...</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Hình ảnh</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Tiêu đề</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Trạng thái</th>
                  <th className="px-6 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">Thao tác</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {banners.map(banner => (
                  <tr key={banner.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <img src={banner.imageUrl} alt={banner.title} className="h-16 w-32 object-cover rounded shadow-sm border" />
                    </td>
                    <td className="px-6 py-4 text-sm font-medium text-gray-900">{banner.title}</td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`px-3 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${
                        banner.isActive ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
                      }`}>
                        {banner.isActive ? 'Đang Hiển Thị' : 'Tắt'}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium space-x-3">
                      <button 
                        onClick={() => handleToggleStatus(banner.id)} 
                        className={`${banner.isActive ? 'text-gray-500 hover:text-gray-700' : 'text-green-600 hover:text-green-900'} transition-colors`}
                        title={banner.isActive ? "Tắt hiển thị" : "Bật hiển thị"}
                      >
                        <Power className="w-5 h-5 inline" />
                      </button>
                      <button onClick={() => handleEdit(banner)} className="text-blue-600 hover:text-blue-900 transition-colors">Sửa</button>
                      <button onClick={() => handleDelete(banner.id)} className="text-red-600 hover:text-red-900 transition-colors">Xoá</button>
                    </td>
                  </tr>
                ))}
                {banners.length === 0 && (
                  <tr>
                    <td colSpan={4} className="px-6 py-12 text-center text-sm text-gray-500">Chưa có ảnh nền nào</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};
