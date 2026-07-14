import React, { useEffect, useState } from 'react';
import axiosClient from '../../api/axiosClient';
import { Product } from '../../types';

export const HomePage: React.FC = () => {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchProducts = async () => {
      try {
        const response = await axiosClient.get('/products?pageSize=8');
        // The API returns ApiResponse<PagedResultDto<ProductDto>>
        setProducts(response.data?.items || []);
      } catch (error) {
        console.error('Failed to fetch products', error);
      } finally {
        setLoading(false);
      }
    };

    fetchProducts();
  }, []);

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-4xl font-bold text-center mb-8">Welcome to PhoneStore</h1>
      <p className="text-center text-gray-600 max-w-2xl mx-auto">
        Discover the latest smartphones with cutting-edge technology. 
        Browse our collection of premium devices from top brands around the world.
      </p>

      <div className="mt-12">
        <h2 className="text-2xl font-bold mb-6 text-gray-800">Featured Products</h2>
        
        {loading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {[1, 2, 3, 4].map(i => (
              <div key={i} className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                <div className="h-48 bg-gray-200 animate-pulse"></div>
                <div className="p-4">
                  <div className="h-4 bg-gray-200 rounded w-3/4 mb-2 animate-pulse"></div>
                  <div className="h-4 bg-gray-200 rounded w-1/4 animate-pulse"></div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {products.map(product => (
              <div key={product.id} className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden hover:shadow-lg transition duration-300 group">
                <div className="h-56 p-4 flex items-center justify-center bg-white relative">
                  {product.salePrice > 0 && product.salePrice < product.price && (
                    <span className="absolute top-2 left-2 bg-red-500 text-white text-xs font-bold px-2 py-1 rounded-md z-10">
                      -{Math.round((1 - product.salePrice / product.price) * 100)}%
                    </span>
                  )}
                  <img 
                    src={product.images[0] || 'https://via.placeholder.com/350'} 
                    alt={product.name} 
                    className="max-h-full object-contain group-hover:scale-105 transition duration-300"
                  />
                </div>
                <div className="p-4 border-t border-gray-50">
                  <div className="text-xs text-gray-500 mb-1 font-medium">{product.brandName}</div>
                  <h3 className="font-semibold text-gray-800 text-lg truncate mb-2" title={product.name}>
                    {product.name}
                  </h3>
                  <div className="flex items-center gap-2">
                    <span className="text-primary-600 font-bold text-lg">
                      {new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(product.salePrice > 0 ? product.salePrice : product.price)}
                    </span>
                    {product.salePrice > 0 && product.salePrice < product.price && (
                      <span className="text-gray-400 text-sm line-through">
                        {new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(product.price)}
                      </span>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
        
        {!loading && products.length === 0 && (
          <div className="text-center text-gray-500 py-12">
            No products available at the moment.
          </div>
        )}
      </div>
    </div>
  );
};
