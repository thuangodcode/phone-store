import React, { useEffect, useState } from 'react';
import { adminApi } from '../../../api/adminApi';
import type { Product, Brand, Category } from '../../../types';
import { ProductFormModal } from './ProductFormModal';
import { ActionButton, EditIcon, TrashIcon } from '../../../components/AdminActionButtons';
import { toast } from 'react-toastify';

export const AdminProductsPage: React.FC = () => {
  const [products, setProducts] = useState<Product[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  
  const [brands, setBrands] = useState<Brand[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [toggleLoadingId, setToggleLoadingId] = useState<string | null>(null);

  // Filters & Pagination
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [search, setSearch] = useState('');
  const [brandIdFilter, setBrandIdFilter] = useState('');
  const [categoryIdFilter, setCategoryIdFilter] = useState('');

  const fetchFiltersData = async () => {
    try {
      const [brandsData, categoriesData] = await Promise.all([
        adminApi.getBrands(),
        adminApi.getCategories()
      ]);
      setBrands(brandsData);
      setCategories(categoriesData);
    } catch (error) {
      console.error('Failed to fetch filters data', error);
    }
  };

  const fetchProducts = async () => {
    try {
      setIsLoading(true);
      const res = await adminApi.getProducts(page, pageSize, true, search, brandIdFilter, categoryIdFilter);
      setProducts(res.items);
      setTotalCount(res.totalCount);
    } catch (err) {
      toast.error("Lỗi khi tải danh sách sản phẩm");
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchFiltersData();
  }, []);

  useEffect(() => {
    fetchProducts();
  }, [page, pageSize, brandIdFilter, categoryIdFilter]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    setPage(1);
    fetchProducts();
  };

  const handleToggleStatus = async (product: Product) => {
    const currentStatus = product.isActive ?? true;
    if (!window.confirm(`Bạn có chắc muốn ${currentStatus ? 'ẩn' : 'hiển thị'} sản phẩm này?`)) {
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

      toast.success(`Đã ${currentStatus ? 'ẩn' : 'hiển thị'} sản phẩm thành công`);
      fetchProducts();
    } catch (err) {
      toast.error("Lỗi khi cập nhật trạng thái sản phẩm");
    } finally {
      setToggleLoadingId(null);
    }
  };

  const handleCreate = () => {
    setEditingProduct(null);
    setIsModalOpen(true);
  };

  const handleEdit = (product: Product) => {
    setEditingProduct(product);
    setIsModalOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa sản phẩm này không?')) {
      try {
        await adminApi.deleteProduct(id);
        toast.success("Xóa sản phẩm thành công");
        fetchProducts();
      } catch (err) {
        toast.error("Lỗi khi xóa sản phẩm");
      }
    }
  };

  const totalPages = Math.ceil(totalCount / pageSize) || 1;

  return (
    <div className="p-6">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-6 gap-4">
        <h1 className="text-2xl font-bold text-gray-800">Quản lý Sản phẩm</h1>
        <button 
          onClick={handleCreate}
          className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-medium transition-colors shadow-sm"
        >
          + Thêm Sản phẩm
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-col lg:flex-row flex-wrap gap-4 mb-6">
        <form onSubmit={handleSearch} className="flex gap-2 w-full lg:w-auto">
          <input
            type="text"
            placeholder="Tìm tên sản phẩm..."
            className="border rounded px-3 py-2 w-full lg:w-64 bg-white"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          <button type="submit" className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700">Tìm</button>
        </form>

        <select 
          className="border rounded px-3 py-2 bg-white"
          value={categoryIdFilter}
          onChange={(e) => { setCategoryIdFilter(e.target.value); setPage(1); }}
        >
          <option value="">Tất cả Danh mục</option>
          {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
        </select>

        <select 
          className="border rounded px-3 py-2 bg-white"
          value={brandIdFilter}
          onChange={(e) => { setBrandIdFilter(e.target.value); setPage(1); }}
        >
          <option value="">Tất cả Thương hiệu</option>
          {brands.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
        </select>

        <select 
          className="border rounded px-3 py-2 bg-white"
          value={pageSize}
          onChange={(e) => { setPageSize(Number(e.target.value)); setPage(1); }}
        >
          <option value={10}>10 dòng / trang</option>
          <option value={20}>20 dòng / trang</option>
          <option value={50}>50 dòng / trang</option>
        </select>
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[800px]">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-200">
                <th className="p-4 font-medium text-gray-600">Sản phẩm</th>
                <th className="p-4 font-medium text-gray-600">Giá</th>
                <th className="p-4 font-medium text-gray-600">Thương hiệu</th>
                <th className="p-4 font-medium text-gray-600">Danh mục</th>
                <th className="p-4 font-medium text-gray-600">Trạng thái</th>
                <th className="p-4 font-medium text-gray-600">Tồn kho</th>
                <th className="p-4 font-medium text-gray-600 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {isLoading ? (
                <tr><td colSpan={7} className="p-8 text-center text-gray-500">Đang tải dữ liệu...</td></tr>
              ) : products.length === 0 ? (
                <tr><td colSpan={7} className="p-8 text-center text-gray-500">Không tìm thấy sản phẩm nào.</td></tr>
              ) : (
                products.map(product => {
                  const isActive = product.isActive ?? true;
                  return (
                    <tr key={product.id} className="hover:bg-gray-50">
                      <td className="p-4">
                        <div className="flex items-center gap-3">
                          <img src={product.images?.[0] || 'https://via.placeholder.com/40'} alt={product.name} className="w-10 h-10 rounded object-cover border" />
                          <span className="font-medium text-gray-900">{product.name}</span>
                        </div>
                      </td>
                      <td className="p-4 text-gray-600 font-medium text-red-600">{product.price.toLocaleString('vi-VN')}đ</td>
                      <td className="p-4 text-gray-600">{product.brandName}</td>
                      <td className="p-4 text-gray-600">{product.categoryName}</td>
                      <td className="p-4">
                        <button
                          type="button"
                          onClick={() => handleToggleStatus(product)}
                          disabled={toggleLoadingId === product.id}
                          title={isActive ? "Nhấn để Ẩn" : "Nhấn để Hiện"}
                          className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors duration-200 ease-in-out ${isActive ? 'bg-green-500' : 'bg-gray-300'} ${toggleLoadingId === product.id ? 'opacity-60 cursor-not-allowed' : 'cursor-pointer'}`}
                        >
                          <span className={`inline-block h-4 w-4 transform rounded-full bg-white shadow transition-transform duration-200 ease-in-out ${isActive ? 'translate-x-6' : 'translate-x-1'}`} />
                        </button>
                      </td>
                      <td className="p-4 text-gray-600">{product.stock}</td>
                      <td className="p-4 text-right">
                        <div className="inline-flex items-center justify-end gap-2">
                          <ActionButton label="Sửa" onClick={() => handleEdit(product)} icon={<EditIcon />} variant="secondary" />
                          <ActionButton label="Xóa" onClick={() => handleDelete(product.id)} icon={<TrashIcon />} variant="danger" />
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Controls */}
        {!isLoading && totalCount > 0 && (
          <div className="p-4 border-t border-gray-200 flex items-center justify-between bg-gray-50">
            <span className="text-sm text-gray-600">
              Hiển thị {((page - 1) * pageSize) + 1} đến {Math.min(page * pageSize, totalCount)} trong số {totalCount} kết quả
            </span>
            <div className="flex gap-1">
              <button 
                disabled={page === 1}
                onClick={() => setPage(p => p - 1)}
                className="px-3 py-1 border rounded bg-white hover:bg-gray-100 disabled:opacity-50 transition-colors"
              >
                Trước
              </button>
              <button 
                disabled={page === totalPages}
                onClick={() => setPage(p => p + 1)}
                className="px-3 py-1 border rounded bg-white hover:bg-gray-100 disabled:opacity-50 transition-colors"
              >
                Sau
              </button>
            </div>
          </div>
        )}
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
