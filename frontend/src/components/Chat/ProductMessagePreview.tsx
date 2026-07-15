import React, { useEffect, useState } from 'react';
import axiosClient from '../../api/axiosClient';

interface ProductMessagePreviewProps {
  productId: string;
}

export const ProductMessagePreview: React.FC<ProductMessagePreviewProps> = ({ productId }) => {
  const [product, setProduct] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchProduct = async () => {
      try {
        const res: any = await axiosClient.get(`/products/${productId}`);
        setProduct(res.data);
      } catch (error) {
        console.error("Error fetching product preview:", error);
      } finally {
        setLoading(false);
      }
    };
    fetchProduct();
  }, [productId]);

  if (loading) {
    return (
      <div className="mt-2 p-3 bg-white border border-gray-200 rounded-lg text-black text-xs font-sans animate-pulse flex items-center gap-3">
        <div className="w-12 h-12 bg-gray-200 rounded"></div>
        <div className="flex-1">
          <div className="h-3 bg-gray-200 rounded w-3/4 mb-2"></div>
          <div className="h-3 bg-gray-200 rounded w-1/2"></div>
        </div>
      </div>
    );
  }

  if (!product) {
    return (
      <div className="mt-2 p-3 bg-white border border-gray-200 rounded-lg text-black text-xs font-sans">
        Sản phẩm không tồn tại hoặc đã bị xóa.
      </div>
    );
  }

  return (
    <a 
      href={`/products/${productId}`} 
      target="_blank" 
      rel="noreferrer" 
      className="mt-2 p-2 bg-white border border-gray-200 hover:border-blue-400 hover:shadow-md transition-all rounded-lg text-black text-xs font-sans flex items-center gap-3 block decoration-transparent group"
    >
      <img 
        src={product.images?.[0] || 'https://via.placeholder.com/48'} 
        alt={product.name} 
        className="w-12 h-12 object-cover rounded"
      />
      <div className="flex-1 overflow-hidden">
        <div className="font-bold line-clamp-1 group-hover:text-blue-600 transition-colors">{product.name}</div>
        <div className="text-blue-600 mt-1 font-medium">{product.price?.toLocaleString('vi-VN')} đ</div>
      </div>
    </a>
  );
};
