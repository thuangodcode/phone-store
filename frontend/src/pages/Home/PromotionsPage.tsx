import React, { useEffect, useState } from 'react';
import { articleApi } from '../../api/articleApi';

export const PromotionsPage: React.FC = () => {
  const [articles, setArticles] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchArticles = async () => {
      try {
        const data = await articleApi.getAll();
        setArticles(data || []);
      } catch (error) {
        console.error('Error fetching articles', error);
      } finally {
        setLoading(false);
      }
    };
    fetchArticles();
  }, []);

  if (loading) return <div className="text-center py-20">Đang tải tin khuyến mãi...</div>;

  return (
    <div className="container mx-auto px-4 py-8 max-w-6xl font-sans">
      <h1 className="text-3xl font-bold mb-8 text-red-600 border-l-4 border-red-600 pl-4">Khuyến mãi & Tin tức</h1>
      
      {articles.length === 0 ? (
        <div className="text-center py-10 text-gray-500">Chưa có bài đăng nào.</div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {articles.map((article: any) => (
            <div key={article.id} className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden hover:shadow-lg transition flex flex-col">
              <div className="h-48 overflow-hidden relative group">
                <img src={article.imageUrl || 'https://via.placeholder.com/400x200'} alt={article.title} className="w-full h-full object-cover group-hover:scale-105 transition duration-500" />
                <div className="absolute top-2 left-2 bg-red-600 text-white text-xs font-bold px-2 py-1 rounded">HOT</div>
              </div>
              <div className="p-5 flex-1 flex flex-col">
                <p className="text-xs text-gray-500 mb-2">{new Date(article.createdAt).toLocaleDateString('vi-VN')} • Đăng bởi: {article.authorName}</p>
                <h3 className="font-bold text-lg mb-3 line-clamp-2">{article.title}</h3>
                <p className="text-gray-600 text-sm line-clamp-3 mb-4 flex-1 whitespace-pre-wrap">{article.content}</p>
                
                {article.productUrl && (
                  <a href={article.productUrl} target="_blank" rel="noreferrer" className="mt-auto block text-center w-full bg-blue-50 text-blue-600 hover:bg-blue-600 hover:text-white font-medium py-2 rounded-lg transition">
                    Xem sản phẩm
                  </a>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
