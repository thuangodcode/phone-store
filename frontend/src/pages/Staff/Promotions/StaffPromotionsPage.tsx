import React, { useEffect, useState } from 'react';
import { articleApi } from '../../../api/articleApi';
import { toast } from 'react-toastify';

export const StaffPromotionsPage: React.FC = () => {
  const [articles, setArticles] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  
  const [formData, setFormData] = useState({ title: '', content: '', imageUrl: '', productUrl: '' });
  const [editingId, setEditingId] = useState<string | null>(null);

  const fetchArticles = async () => {
    setLoading(true);
    try {
      const data = await articleApi.getAll();
      setArticles(data || []);
    } catch (error) {
      toast.error('Lỗi khi tải bài viết');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchArticles();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (editingId) {
        await articleApi.update(editingId, formData);
        toast.success('Cập nhật thành công');
      } else {
        await articleApi.create(formData);
        toast.success('Đăng bài thành công');
      }
      setFormData({ title: '', content: '', imageUrl: '', productUrl: '' });
      setEditingId(null);
      fetchArticles();
    } catch (error) {
      toast.error('Có lỗi xảy ra');
    }
  };

  const handleEdit = (article: any) => {
    setEditingId(article.id);
    setFormData({ title: article.title, content: article.content, imageUrl: article.imageUrl, productUrl: article.productUrl });
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm('Bạn có chắc chắn muốn xoá bài viết này?')) return;
    try {
      await articleApi.delete(id);
      toast.success('Xoá thành công');
      fetchArticles();
    } catch (error) {
      toast.error('Lỗi khi xoá');
    }
  };

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-6">Quản lý Khuyến mãi & Tin tức</h1>
      
      <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200 mb-8">
        <h2 className="text-lg font-bold mb-4">{editingId ? 'Sửa bài viết' : 'Đăng bài mới'}</h2>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Tiêu đề</label>
              <input type="text" required value={formData.title} onChange={e => setFormData({...formData, title: e.target.value})} className="w-full px-4 py-2 rounded-lg border focus:ring-2 focus:ring-blue-500 outline-none" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Link Ảnh (URL)</label>
              <input type="url" value={formData.imageUrl} onChange={e => setFormData({...formData, imageUrl: e.target.value})} className="w-full px-4 py-2 rounded-lg border focus:ring-2 focus:ring-blue-500 outline-none" />
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-gray-700 mb-1">Link sản phẩm đính kèm (Tuỳ chọn)</label>
              <input type="url" value={formData.productUrl} onChange={e => setFormData({...formData, productUrl: e.target.value})} className="w-full px-4 py-2 rounded-lg border focus:ring-2 focus:ring-blue-500 outline-none" placeholder="https://..." />
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-gray-700 mb-1">Nội dung bài viết</label>
              <textarea required rows={5} value={formData.content} onChange={e => setFormData({...formData, content: e.target.value})} className="w-full px-4 py-2 rounded-lg border focus:ring-2 focus:ring-blue-500 outline-none"></textarea>
            </div>
          </div>
          <div className="flex gap-2">
            <button type="submit" className="bg-blue-600 text-white px-6 py-2 rounded-lg font-medium hover:bg-blue-700">{editingId ? 'Lưu thay đổi' : 'Đăng bài'}</button>
            {editingId && <button type="button" onClick={() => { setEditingId(null); setFormData({ title: '', content: '', imageUrl: '', productUrl: '' }); }} className="bg-gray-200 text-gray-700 px-6 py-2 rounded-lg font-medium hover:bg-gray-300">Huỷ</button>}
          </div>
        </form>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-gray-500">Đang tải...</div>
        ) : (
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Ngày đăng</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Tiêu đề</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Tác giả</th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Thao tác</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {articles.map(article => (
                <tr key={article.id}>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{new Date(article.createdAt).toLocaleDateString('vi-VN')}</td>
                  <td className="px-6 py-4 text-sm font-medium text-gray-900">{article.title}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{article.authorName}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <button onClick={() => handleEdit(article)} className="text-blue-600 hover:text-blue-900 mr-4">Sửa</button>
                    <button onClick={() => handleDelete(article.id)} className="text-red-600 hover:text-red-900">Xoá</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};
