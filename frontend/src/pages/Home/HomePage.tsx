import React, { useEffect, useState, useMemo } from 'react';
import axiosClient from '../../api/axiosClient';
import { adminApi } from '../../api/adminApi';
import { ProductCard } from '../../components/Product/ProductCard';
import type { Product, Banner } from '../../types';
import ThreeDCarousel from '../../components/ui/ThreeDCarousel';
import { useSearchParams } from 'react-router-dom';
import { Filter, SortAsc, SortDesc, X } from 'lucide-react';

export const HomePage: React.FC = () => {
  const [products, setProducts] = useState<Product[]>([]);
  const [activeBanner, setActiveBanner] = useState<Banner | null>(null);
  const [loading, setLoading] = useState(true);
  const [searchParams, setSearchParams] = useSearchParams();
  
  const brandParam = searchParams.get('brand');
  const searchParam = searchParams.get('search');
  
  const [priceFilter, setPriceFilter] = useState<string>('default');

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [productsRes, banner] = await Promise.all([
          axiosClient.get('/products?pageSize=1000'),
          adminApi.getActiveBanner()
        ]);
        setProducts(productsRes.data?.items || []);
        setActiveBanner(banner);
      } catch (error) {
        console.error('Failed to fetch data', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const highestPricedProducts = useMemo(() => {
    return [...products].sort((a, b) => b.price - a.price).slice(0, 8);
  }, [products]);

  const carouselProducts = useMemo(() => {
    return highestPricedProducts.map(p => ({
      id: p.id,
      name: p.name,
      image: p.images?.[0] || 'https://via.placeholder.com/400',
      price: p.salePrice > 0 ? p.salePrice : p.price
    }));
  }, [highestPricedProducts]);

  const filteredProducts = useMemo(() => {
    let result = products.filter(p => {
      let match = true;
      if (brandParam) match = match && p.brandId === brandParam;
      if (searchParam) match = match && p.name.toLowerCase().includes(searchParam.toLowerCase());
      
      const currentPrice = p.salePrice > 0 ? p.salePrice : p.price;
      if (priceFilter === 'under2m') match = match && currentPrice < 2000000;
      if (priceFilter === '2to5m') match = match && currentPrice >= 2000000 && currentPrice < 5000000;
      if (priceFilter === '5to10m') match = match && currentPrice >= 5000000 && currentPrice < 10000000;
      if (priceFilter === 'over10m') match = match && currentPrice >= 10000000;
      
      return match;
    });

    if (priceFilter === 'asc') {
      result.sort((a, b) => (a.salePrice > 0 ? a.salePrice : a.price) - (b.salePrice > 0 ? b.salePrice : b.price));
    } else {
      // Default: sort desc
      result.sort((a, b) => (b.salePrice > 0 ? b.salePrice : b.price) - (a.salePrice > 0 ? a.salePrice : a.price));
    }

    return result;
  }, [products, brandParam, searchParam, priceFilter]);

  const groupedProducts = useMemo(() => {
    return filteredProducts.reduce((acc, product) => {
      const brand = product.brandName || 'Khác';
      if (!acc[brand]) acc[brand] = [];
      acc[brand].push(product);
      return acc;
    }, {} as Record<string, Product[]>);
  }, [filteredProducts]);

  const sortedBrands = useMemo(() => {
    const priorityBrands = ['Apple', 'Samsung', 'Xiaomi', 'OPPO'];
    return Object.keys(groupedProducts).sort((a, b) => {
      const indexA = priorityBrands.findIndex(p => p.toLowerCase() === a.toLowerCase());
      const indexB = priorityBrands.findIndex(p => p.toLowerCase() === b.toLowerCase());
      if (indexA !== -1 && indexB !== -1) return indexA - indexB;
      if (indexA !== -1) return -1;
      if (indexB !== -1) return 1;
      return a.localeCompare(b);
    });
  }, [groupedProducts]);

  const isFiltering = brandParam || searchParam || priceFilter !== 'default';

  const clearFilters = () => {
    setSearchParams({});
    setPriceFilter('default');
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Top Banner & Carousel Section */}
      <div 
        className="relative pt-12 pb-16 overflow-hidden bg-gray-900"
        style={activeBanner?.imageUrl ? {
          backgroundImage: `url(${activeBanner.imageUrl})`,
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          backgroundRepeat: 'no-repeat'
        } : undefined}
      >
        {/* Dark overlay for better text readability */}
        {activeBanner?.imageUrl && (
          <div className="absolute inset-0 bg-black/60 backdrop-blur-[2px]"></div>
        )}
        
        <div className="container mx-auto px-4 relative z-10">
          <div className="flex flex-col items-center">
            <h1 className="text-4xl sm:text-5xl md:text-6xl font-bold text-center mb-4 text-white tracking-tight drop-shadow-md">
              Sản phẩm nổi bật
            </h1>
            <p className="text-center text-gray-200 mb-12 text-lg sm:text-xl max-w-2xl drop-shadow">
              Khám phá những thiết bị cao cấp nhất được tuyển chọn dành riêng cho bạn
            </p>
            <div className="w-full h-[450px] sm:h-[550px] relative z-0 max-w-6xl mx-auto">
              {!loading && carouselProducts.length > 0 ? (
                <ThreeDCarousel products={carouselProducts} />
              ) : (
                <div className="w-full h-full flex items-center justify-center">
                  <div className="animate-pulse flex flex-col items-center">
                    <div className="w-32 h-40 bg-gray-700/50 rounded-xl mb-4"></div>
                    <div className="h-4 bg-gray-700/50 rounded w-24"></div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      <div className="container mx-auto px-4 py-8">
        <div className="border-b pb-4 mb-8 sticky top-[72px] bg-white/95 backdrop-blur-md z-40 shadow-sm rounded-lg px-4 pt-4">
        <div className="flex flex-wrap items-center gap-3">
          <div className="flex items-center text-gray-700 font-medium mr-2">
            <Filter className="w-5 h-5 mr-1" /> Bộ lọc:
          </div>
          
          <button 
            onClick={() => setPriceFilter('default')}
            className={`px-4 py-2 rounded-full text-sm font-medium transition shadow-sm ${priceFilter === 'default' ? 'bg-primary-600 text-white' : 'bg-gray-100 hover:bg-gray-200 text-gray-700'}`}
          >
            Mặc định
          </button>
          
          <button 
            onClick={() => setPriceFilter('asc')}
            className={`px-4 py-2 rounded-full text-sm font-medium flex items-center transition shadow-sm ${priceFilter === 'asc' ? 'bg-primary-600 text-white' : 'bg-gray-100 hover:bg-gray-200 text-gray-700'}`}
          >
            <SortAsc className="w-4 h-4 mr-1" /> Giá tăng dần
          </button>
          
          <button 
            onClick={() => setPriceFilter('desc')}
            className={`px-4 py-2 rounded-full text-sm font-medium flex items-center transition shadow-sm ${priceFilter === 'desc' ? 'bg-primary-600 text-white' : 'bg-gray-100 hover:bg-gray-200 text-gray-700'}`}
          >
            <SortDesc className="w-4 h-4 mr-1" /> Giá giảm dần
          </button>
          
          <div className="w-px h-6 bg-gray-300 mx-1"></div>
          
          <button 
            onClick={() => setPriceFilter('under2m')}
            className={`px-4 py-2 rounded-full text-sm font-medium transition shadow-sm ${priceFilter === 'under2m' ? 'bg-primary-600 text-white' : 'bg-gray-100 hover:bg-gray-200 text-gray-700'}`}
          >
            Dưới 2 triệu
          </button>
          
          <button 
            onClick={() => setPriceFilter('2to5m')}
            className={`px-4 py-2 rounded-full text-sm font-medium transition shadow-sm ${priceFilter === '2to5m' ? 'bg-primary-600 text-white' : 'bg-gray-100 hover:bg-gray-200 text-gray-700'}`}
          >
            Từ 2 - 5 triệu
          </button>
          
          <button 
            onClick={() => setPriceFilter('5to10m')}
            className={`px-4 py-2 rounded-full text-sm font-medium transition shadow-sm ${priceFilter === '5to10m' ? 'bg-primary-600 text-white' : 'bg-gray-100 hover:bg-gray-200 text-gray-700'}`}
          >
            Từ 5 - 10 triệu
          </button>
          
          <button 
            onClick={() => setPriceFilter('over10m')}
            className={`px-4 py-2 rounded-full text-sm font-medium transition shadow-sm ${priceFilter === 'over10m' ? 'bg-primary-600 text-white' : 'bg-gray-100 hover:bg-gray-200 text-gray-700'}`}
          >
            Trên 10 triệu
          </button>

          {isFiltering && (
            <button 
              onClick={clearFilters}
              className="px-4 py-2 rounded-full text-sm font-medium flex items-center bg-red-100 text-red-600 hover:bg-red-200 transition shadow-sm ml-auto"
            >
              <X className="w-4 h-4 mr-1" /> Xóa bộ lọc
            </button>
          )}
        </div>
        
        {searchParam && (
          <div className="mt-4 text-gray-600 text-lg">
            Kết quả tìm kiếm cho: <span className="font-bold text-gray-900">"{searchParam}"</span>
          </div>
        )}
      </div>

      <div className="mt-4">
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
        ) : filteredProducts.length === 0 ? (
          <div className="text-center text-gray-500 py-12 text-lg">
            Không tìm thấy sản phẩm nào phù hợp với điều kiện của bạn.
          </div>
        ) : isFiltering ? (
          // When filtering, just show a single grid
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 xl:grid-cols-4 gap-4 sm:gap-5 md:gap-6 lg:gap-8">
            {filteredProducts.map(product => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>
        ) : (
          // When NOT filtering, group by brands
          <div className="space-y-16">
            {sortedBrands.map(brandName => {
              const brandProducts = groupedProducts[brandName];
              return (
                <div key={brandName} className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
                  <div className="flex items-center justify-between mb-6 border-b border-gray-100 pb-4">
                    <h2 className="text-3xl font-bold text-gray-800 uppercase tracking-tight">Điện thoại {brandName}</h2>
                    <span className="text-sm font-medium text-gray-500 bg-gray-100 px-3 py-1 rounded-full">{brandProducts.length} sản phẩm</span>
                  </div>
                  <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 xl:grid-cols-4 gap-4 sm:gap-5 md:gap-6 lg:gap-8">
                    {brandProducts.map(product => (
                      <ProductCard key={product.id} product={product} />
                    ))}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
      <style>{`
        .font-space-grotesk {
          font-family: 'Space Grotesk', sans-serif;
        }
      `}</style>
    </div>
  );
};
