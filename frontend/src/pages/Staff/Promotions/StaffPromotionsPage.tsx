import React, { useEffect, useState, useRef } from 'react';
import { articleApi } from '../../../api/articleApi';
import { adminApi } from '../../../api/adminApi';
import { toast } from 'react-toastify';
import type { Product } from '../../../types';
import { Search, ChevronDown, Check, ImageIcon } from 'lucide-react';
import { ConfirmModal } from '../../../components/Layout/ConfirmModal';
import { useAuth } from '../../../contexts/AuthContext';

export const StaffPromotionsPage: React.FC = () => {
  const [articles, setArticles] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  
  const [formData, setFormData] = useState({ title: '', content: '', imageUrl: '', productUrl: '' });
  const [editingId, setEditingId] = useState<string | null>(null);
  const [confirmModalOpen, setConfirmModalOpen] = useState(false);
  const [confirmMessage, setConfirmMessage] = useState('');
  const [confirmAction, setConfirmAction] = useState<(() => Promise<void>) | null>(null);
  const [confirmLoading, setConfirmLoading] = useState(false);
  const { user } = useAuth();

  const editingArticle = articles.find(a => a.id === editingId);
  const displayAuthorName = editingArticle ? editingArticle.authorName : (user?.fullName || 'Admin / Staff');
  const displayDate = editingArticle 
    ? new Date(editingArticle.createdAt).toLocaleString('vi-VN', { hour: '2-digit', minute: '2-digit', day: '2-digit', month: '2-digit', year: 'numeric' })
    : new Date().toLocaleString('vi-VN', { hour: '2-digit', minute: '2-digit', day: '2-digit', month: '2-digit', year: 'numeric' });

  // For product dropdown
  const [products, setProducts] = useState<Product[]>([]);
  const [showProductDropdown, setShowProductDropdown] = useState(false);
  const [productSearch, setProductSearch] = useState('');
  const dropdownRef = useRef<HTMLDivElement>(null);

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

  const fetchProducts = async () => {
    try {
      const res = await adminApi.getProducts(1, 1000);
      setProducts(res.items);
    } catch(e) {}
  };

  useEffect(() => {
    fetchArticles();
    fetchProducts();
  }, []);

  // Handle outside click for dropdown
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setShowProductDropdown(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
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
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleDelete = async (id: string) => {
    setConfirmMessage('Bạn có chắc chắn muốn xoá bài viết này?');
    setConfirmAction(() => async () => {
      try {
        await articleApi.delete(id);
        toast.success('Xoá thành công');
        fetchArticles();
      } catch (error) {
        toast.error('Lỗi khi xoá');
      }
    });
    setConfirmModalOpen(true);
  };

  const filteredProducts = products.filter(p => p.name.toLowerCase().includes(productSearch.toLowerCase()));

  const selectedProduct = products.find(p => formData.productUrl.includes(p.id));

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-6">Quản lý Khuyến mãi & Tin tức</h1>
      
      <div className="bg-white p-8 rounded-xl shadow-sm border border-gray-200 mb-8 max-w-4xl mx-auto">
        <h2 className="text-lg font-bold mb-6 pb-2 border-b">{editingId ? 'Chỉnh sửa bài viết' : 'Đăng bài mới (Chế độ xem trước)'}</h2>
        <form onSubmit={handleSubmit} className="space-y-6">
          
          {/* Title - Article Style */}
          <div>
            <input 
              type="text" 
              required 
              value={formData.title} 
              onChange={e => setFormData({...formData, title: e.target.value})} 
              className="w-full text-3xl font-bold border-0 border-b-2 border-transparent hover:border-gray-200 focus:border-blue-500 focus:ring-0 px-0 py-2 placeholder-gray-300 transition-colors outline-none" 
              placeholder="Nhập tiêu đề bài viết..." 
            />
          </div>

          <div className="flex items-center text-sm text-gray-500 mb-4">
            <span>Đăng bởi: {displayAuthorName}</span>
            <span className="mx-2">•</span>
            <span>{displayDate}</span>
          </div>

          {/* Image - Article Style */}
          <div className="relative group rounded-2xl overflow-hidden border-2 border-dashed border-gray-300 bg-gray-50 flex flex-col items-center justify-center transition-all hover:border-blue-400">
            {formData.imageUrl ? (
              <div className="relative w-full">
                <img src={formData.imageUrl} alt="Preview" className="w-full h-auto max-h-[500px] object-cover" />
                <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                  <input 
                    type="url" 
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
                  value={formData.imageUrl} 
                  onChange={e => setFormData({...formData, imageUrl: e.target.value})} 
                  className="w-full max-w-lg mx-auto px-4 py-3 text-sm rounded-lg border focus:ring-2 focus:ring-blue-500 outline-none shadow-sm" 
                  placeholder="Dán Link Ảnh (URL) vào đây để xem trước..." 
                />
              </div>
            )}
          </div>

          {/* Content - Article Style */}
          <div>
            <textarea 
              required 
              rows={8} 
              value={formData.content} 
              onChange={e => setFormData({...formData, content: e.target.value})} 
              className="w-full text-lg leading-relaxed text-gray-700 border-0 border-l-4 border-transparent hover:border-gray-200 focus:border-blue-500 focus:ring-0 pl-4 py-2 placeholder-gray-300 resize-y transition-colors outline-none"
              placeholder="Nhập nội dung chi tiết bài viết..."
            ></textarea>
          </div>

          {/* Product Dropdown */}
          <div className="border-t pt-6" ref={dropdownRef}>
            <label className="block text-sm font-semibold text-gray-700 mb-2">Sản phẩm đính kèm (Tuỳ chọn)</label>
            <div className="relative">
              <div 
                className="w-full px-4 py-3 rounded-lg border flex items-center justify-between cursor-pointer hover:border-blue-500 transition-colors bg-white shadow-sm"
                onClick={() => setShowProductDropdown(!showProductDropdown)}
              >
                <div className="flex items-center gap-3">
                  {selectedProduct ? (
                    <>
                      <img src={selectedProduct.images[0] || 'https://via.placeholder.com/40'} alt={selectedProduct.name} className="w-8 h-8 object-cover rounded" />
                      <span className="font-medium text-gray-800">{selectedProduct.name}</span>
                    </>
                  ) : formData.productUrl ? (
                    <span className="font-medium text-blue-600">{formData.productUrl}</span>
                  ) : (
                    <span className="text-gray-400">Nhấn vào đây để tìm chọn sản phẩm đính kèm...</span>
                  )}
                </div>
                <ChevronDown className={`w-5 h-5 text-gray-400 transition-transform ${showProductDropdown ? 'rotate-180' : ''}`} />
              </div>
              
              {showProductDropdown && (
                <div className="absolute bottom-full mb-2 left-0 right-0 bg-white border rounded-xl shadow-xl z-20 overflow-hidden">
                  <div className="p-3 border-b bg-gray-50/80">
                    <div className="relative">
                      <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 w-4 h-4" />
                      <input 
                        type="text" 
                        value={productSearch}
                        onChange={e => setProductSearch(e.target.value)}
                        className="w-full pl-9 pr-4 py-2.5 rounded-lg border text-sm focus:ring-2 focus:ring-blue-500 outline-none"
                        placeholder="Gõ tên sản phẩm để tìm nhanh..."
                        autoFocus
                      />
                    </div>
                  </div>
                  <div className="max-h-72 overflow-y-auto p-2">
                    <div 
                      className={`p-3 flex items-center justify-between rounded-lg cursor-pointer hover:bg-gray-100 transition-colors mb-1 ${!formData.productUrl ? 'bg-blue-50/50' : ''}`}
                      onClick={() => {
                        setFormData({...formData, productUrl: ''});
                        setShowProductDropdown(false);
                      }}
                    >
                      <span className="text-sm font-medium text-gray-700">Không đính kèm sản phẩm</span>
                      {!formData.productUrl && <Check className="w-4 h-4 text-blue-600" />}
                    </div>
                    {filteredProducts.map(p => {
                      const isSelected = formData.productUrl.includes(p.id);
                      return (
                        <div 
                          key={p.id}
                          className={`p-3 flex items-center justify-between rounded-lg cursor-pointer hover:bg-gray-50 transition-colors mb-1 ${isSelected ? 'bg-blue-50/50 border border-blue-100' : 'border border-transparent'}`}
                          onClick={() => {
                            setFormData({...formData, productUrl: '/products/' + p.id});
                            setShowProductDropdown(false);
                            setProductSearch('');
                          }}
                        >
                          <div className="flex items-center gap-3">
                            <img src={p.images[0] || 'https://via.placeholder.com/40'} alt={p.name} className="w-12 h-12 object-cover rounded-md border bg-white" />
                            <div>
                              <p className="text-sm font-semibold text-gray-900">{p.name}</p>
                              <p className="text-xs font-medium text-red-600 mt-0.5">{p.salePrice > 0 ? p.salePrice.toLocaleString('vi-VN') : p.price.toLocaleString('vi-VN')} đ</p>
                            </div>
                          </div>
                          {isSelected && <Check className="w-5 h-5 text-blue-600" />}
                        </div>
                      )
                    })}
                    {filteredProducts.length === 0 && (
                      <div className="p-8 text-center text-sm text-gray-500">
                        Không tìm thấy sản phẩm nào
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>
            

          </div>

          <div className="flex gap-3 pt-6 justify-end border-t">
            {editingId && (
              <button 
                type="button" 
                onClick={() => { setEditingId(null); setFormData({ title: '', content: '', imageUrl: '', productUrl: '' }); }} 
                className="bg-gray-100 text-gray-700 px-6 py-2.5 rounded-lg font-medium hover:bg-gray-200 transition-colors"
              >
                Huỷ sửa
              </button>
            )}
            <button 
              type="submit" 
              className="bg-blue-600 text-white px-8 py-2.5 rounded-lg font-medium hover:bg-blue-700 shadow-md shadow-blue-500/20 transition-all hover:-translate-y-0.5"
            >
              {editingId ? 'Lưu thay đổi' : 'Đăng bài viết'}
            </button>
          </div>
        </form>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden max-w-4xl mx-auto">
        <div className="px-6 py-4 border-b bg-gray-50/50 flex justify-between items-center">
          <h2 className="font-bold text-gray-800">Danh sách bài đăng</h2>
          <span className="text-sm text-gray-500">{articles.length} bài viết</span>
        </div>
        {loading ? (
          <div className="p-8 text-center text-gray-500">Đang tải...</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Ngày đăng</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Tiêu đề</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Tác giả</th>
                  <th className="px-6 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">Thao tác</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {articles.map(article => (
                  <tr key={article.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{new Date(article.createdAt).toLocaleDateString('vi-VN')}</td>
                    <td className="px-6 py-4 text-sm font-medium text-gray-900 max-w-xs truncate">{article.title}</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{article.authorName}</td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <button onClick={() => handleEdit(article)} className="text-blue-600 hover:text-blue-900 mr-4 transition-colors">Sửa</button>
                      <button onClick={() => handleDelete(article.id)} className="text-red-600 hover:text-red-900 transition-colors">Xoá</button>
                    </td>
                  </tr>
                ))}
                {articles.length === 0 && (
                  <tr>
                    <td colSpan={4} className="px-6 py-12 text-center text-sm text-gray-500">Chưa có bài viết nào</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      <ConfirmModal
        isOpen={confirmModalOpen}
        title="Xác nhận hành động"
        description={confirmMessage}
        confirmLabel="Có"
        cancelLabel="Không"
        isLoading={confirmLoading}
        onConfirm={async () => {
          if (!confirmAction) return;
          setConfirmLoading(true);
          await confirmAction();
          setConfirmLoading(false);
          setConfirmModalOpen(false);
          setConfirmAction(null);
        }}
        onClose={() => {
          setConfirmModalOpen(false);
          setConfirmAction(null);
        }}
      />
      </div>
    </div>
  );
};

