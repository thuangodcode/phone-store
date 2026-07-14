import React, { useEffect, useState } from 'react';
import axiosClient from '../../api/axiosClient';
import { ProductCard } from '../../components/Product/ProductCard';
import type { Product } from '../../types';

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
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 xl:grid-cols-4 2xl:grid-cols-4 gap-4 sm:gap-5 md:gap-6 lg:gap-8">
            {products.map(product => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>
        )}
        
        {!loading && products.length === 0 && (
          <div className="text-center text-gray-500 py-12">
            No products available at the moment.
          </div>
        )}
      </div>
      <style>{`
        .font-space-grotesk {
          font-family: 'Space Grotesk', sans-serif;
        }
      `}</style>
    </div>
  );
};
