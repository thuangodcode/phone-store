import React, { useEffect, useState, useRef } from 'react';
import * as signalR from '@microsoft/signalr';
import axiosClient from '../../api/axiosClient';
import { useAuth } from '../../contexts/AuthContext';
import { toast } from 'react-toastify';
import { User, Send, Star, Trash2, MessageSquare, Edit2, X, Check } from 'lucide-react';

interface ReviewDto {
  id: string;
  userId: string;
  userName: string;
  userAvatar?: string;
  userRole?: string;
  productId: string;
  orderId: string;
  rating: number;
  comment: string;
  createdAt: string;
  replies: any[];
}

interface ProductCommentsProps {
  productId: string;
}

export const ProductComments: React.FC<ProductCommentsProps> = ({ productId }) => {
  const [comments, setComments] = useState<ReviewDto[]>([]);
  const [newComment, setNewComment] = useState('');
  const [rating, setRating] = useState(5);
  const [loading, setLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [replyingTo, setReplyingTo] = useState<string | null>(null);
  const [replyContent, setReplyContent] = useState('');
  
  const [editingReviewId, setEditingReviewId] = useState<string | null>(null);
  const [editRating, setEditRating] = useState(5);
  const [editContent, setEditContent] = useState('');

  const [editingReplyId, setEditingReplyId] = useState<{reviewId: string, replyId: string} | null>(null);
  const [editReplyContent, setEditReplyContent] = useState('');

  const { isAuthenticated, isAdminOrStaff, user } = useAuth();
  
  const connectionRef = useRef<signalR.HubConnection | null>(null);

  useEffect(() => {
    let isMounted = true;
    
    const fetchComments = async () => {
      try {
        const res: any = await axiosClient.get(`/reviews/product/${productId}`);
        if (isMounted) {
          setComments(res.data || []);
        }
      } catch (error) {
        console.error('Failed to fetch comments', error);
      } finally {
        if (isMounted) setLoading(false);
      }
    };

    const setupSignalR = async () => {
      // Get base URL for hubs (strip /api if present)
      let baseURL = import.meta.env.VITE_API_URL || 'https://phone-store-api-4bah.onrender.com/api';
      if (baseURL.endsWith('/api')) {
        baseURL = baseURL.substring(0, baseURL.length - 4);
      }
      
      const connection = new signalR.HubConnectionBuilder()
        .withUrl(`${baseURL}/reviewHub`)
        .withAutomaticReconnect()
        .build();
        
      connectionRef.current = connection;

      connection.on('ReceiveReview', (review: ReviewDto) => {
        if (isMounted) {
          setComments(prev => {
            // Check if review already exists (e.g. from our own post or update)
            const exists = prev.some(c => c.id === review.id);
            if (exists) {
              return prev.map(c => c.id === review.id ? review : c);
            }
            // Add new review at the top
            return [review, ...prev];
          });
        }
      });

      try {
        await connection.start();
        await connection.invoke('JoinProductGroup', productId);
      } catch (error) {
        console.error('SignalR Connection Error: ', error);
      }
    };

    fetchComments();
    setupSignalR();

    return () => {
      isMounted = false;
      if (connectionRef.current) {
        connectionRef.current.invoke('LeaveProductGroup', productId).catch(console.error);
        connectionRef.current.stop();
      }
    };
  }, [productId]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newComment.trim()) return;
    
    if (!isAuthenticated) {
      toast.info('Vui lòng đăng nhập để bình luận!');
      return;
    }

    setIsSubmitting(true);
    try {
      await axiosClient.post('/reviews', {
        productId,
        orderId: "000000000000000000000000", // valid dummy ObjectId to bypass MongoDB validation
        rating,
        comment: newComment.trim()
      });
      setNewComment('');
      setRating(5);
      toast.success('Gửi bình luận thành công');
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Lỗi khi gửi bình luận');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteComment = async (id: string, isAdminDelete: boolean = false) => {
    if (!window.confirm('Bạn có chắc chắn muốn xóa bình luận này?')) return;
    try {
      const endpoint = isAdminDelete ? `/reviews/admin/${id}` : `/reviews/${id}`;
      await axiosClient.delete(endpoint);
      setComments(prev => prev.filter(c => c.id !== id));
      toast.success('Đã xóa bình luận');
    } catch (error: any) {
      toast.error('Lỗi khi xóa bình luận');
    }
  };

  const handleUpdateComment = async (id: string) => {
    if (!editContent.trim()) return;
    try {
      await axiosClient.put(`/reviews/${id}`, {
        rating: editRating,
        comment: editContent.trim()
      });
      setComments(prev => prev.map(c => c.id === id ? { ...c, rating: editRating, comment: editContent.trim() } : c));
      setEditingReviewId(null);
      toast.success('Đã cập nhật bình luận');
    } catch (error: any) {
      toast.error('Lỗi khi cập nhật bình luận');
    }
  };

  const handleReplySubmit = async (id: string) => {
    if (!replyContent.trim()) return;
    try {
      await axiosClient.post(`/reviews/${id}/reply`, `"${replyContent.trim()}"`, {
        headers: { 'Content-Type': 'application/json' }
      });
      setReplyContent('');
      setReplyingTo(null);
      toast.success('Đã trả lời bình luận');
    } catch (error: any) {
      toast.error('Lỗi khi gửi trả lời');
    }
  };

  const handleUpdateReply = async (reviewId: string, replyId: string) => {
    if (!editReplyContent.trim()) return;
    try {
      await axiosClient.put(`/reviews/${reviewId}/reply/${replyId}`, `"${editReplyContent.trim()}"`, {
        headers: { 'Content-Type': 'application/json' }
      });
      setComments(prev => prev.map(c => {
        if (c.id === reviewId) {
          return {
            ...c,
            replies: c.replies.map(r => r.id === replyId ? { ...r, comment: editReplyContent.trim() } : r)
          };
        }
        return c;
      }));
      setEditingReplyId(null);
      toast.success('Đã cập nhật câu trả lời');
    } catch (error: any) {
      toast.error('Lỗi khi cập nhật câu trả lời');
    }
  };

  const handleDeleteReply = async (reviewId: string, replyId: string) => {
    if (!window.confirm('Bạn có chắc chắn muốn xóa câu trả lời này?')) return;
    try {
      await axiosClient.delete(`/reviews/${reviewId}/reply/${replyId}`);
      setComments(prev => prev.map(c => {
        if (c.id === reviewId) {
          return {
            ...c,
            replies: c.replies.filter(r => r.id !== replyId)
          };
        }
        return c;
      }));
      toast.success('Đã xóa câu trả lời');
    } catch (error: any) {
      toast.error('Lỗi khi xóa câu trả lời');
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('vi-VN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    }).format(date);
  };

  return (
    <div className="mt-8 bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
      <h2 className="text-xl font-bold mb-6">Bình luận & Đánh giá</h2>
      
      {/* Comment Form */}
      <form onSubmit={handleSubmit} className="mb-8 bg-gray-50 p-4 rounded-xl">
        {isAuthenticated ? (
          <div className="space-y-4">
            <div className="flex items-center gap-2">
              <span className="text-sm font-medium text-gray-700">Đánh giá của bạn:</span>
              <div className="flex">
                {[1, 2, 3, 4, 5].map(star => (
                  <Star 
                    key={star} 
                    size={20} 
                    className={`cursor-pointer transition-colors ${star <= rating ? 'fill-yellow-400 text-yellow-400' : 'text-gray-300'}`}
                    onClick={() => setRating(star)}
                  />
                ))}
              </div>
            </div>
            <div className="relative">
              <textarea 
                value={newComment}
                onChange={(e) => setNewComment(e.target.value)}
                placeholder="Chia sẻ cảm nghĩ của bạn về sản phẩm này..."
                className="w-full bg-white border border-gray-200 rounded-xl p-3 pr-12 focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none resize-none h-24 transition-shadow"
                disabled={isSubmitting}
              />
              <button 
                type="submit" 
                disabled={!newComment.trim() || isSubmitting}
                className="absolute bottom-3 right-3 p-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <Send size={18} />
              </button>
            </div>
          </div>
        ) : (
          <div className="text-center py-6 text-gray-500">
            Vui lòng <a href="/login" className="text-primary-600 font-semibold hover:underline">đăng nhập</a> để tham gia bình luận.
          </div>
        )}
      </form>

      {/* Comments List */}
      <div>
        {loading ? (
          <div className="space-y-4 animate-pulse">
            {[1, 2].map(i => (
              <div key={i} className="flex gap-4">
                <div className="w-10 h-10 bg-gray-200 rounded-full"></div>
                <div className="flex-1 space-y-2">
                  <div className="h-4 bg-gray-200 rounded w-1/4"></div>
                  <div className="h-4 bg-gray-200 rounded w-3/4"></div>
                </div>
              </div>
            ))}
          </div>
        ) : comments.length > 0 ? (
          <div className="space-y-6">
            {comments.map(comment => (
              <div key={comment.id} className="flex gap-4">
                <div className="w-10 h-10 bg-gradient-to-tr from-primary-500 to-purple-500 rounded-full flex items-center justify-center text-white flex-shrink-0 font-bold shadow-sm overflow-hidden">
                  {comment.userAvatar ? (
                    <img src={comment.userAvatar} alt="avatar" className="w-full h-full object-cover" />
                  ) : (
                    comment.userName ? comment.userName.charAt(0).toUpperCase() : <User size={20} />
                  )}
                </div>
                <div className="flex-1">
                  <div className="bg-gray-50 p-4 rounded-2xl rounded-tl-none border border-gray-100">
                    <div className="flex justify-between items-start mb-2">
                      <h4 className="font-semibold text-gray-900 flex items-center gap-2">
                        {comment.userName || 'Người dùng'}
                        {(comment.userRole === 'Admin' || comment.userRole === 'Staff') && (
                           <span className="bg-red-500 text-white text-[10px] px-2 py-0.5 rounded-full font-bold">QTV</span>
                        )}
                      </h4>
                      <span className="text-xs text-gray-500">{formatDate(comment.createdAt)}</span>
                    </div>
                    <div className="flex mb-2">
                      {[...Array(5)].map((_, i) => (
                        <Star key={i} size={14} className={i < comment.rating ? 'fill-yellow-400 text-yellow-400' : 'text-gray-300'} />
                      ))}
                    </div>
                    <p className="text-gray-700 whitespace-pre-wrap">{comment.comment}</p>
                    
                    {/* Controls */}
                    {isAuthenticated && editingReviewId !== comment.id && (
                      <div className="mt-3 flex gap-4 text-sm">
                        <button 
                          onClick={() => setReplyingTo(replyingTo === comment.id ? null : comment.id)}
                          className="flex items-center text-blue-600 hover:text-blue-800 transition"
                        >
                          <MessageSquare size={14} className="mr-1" /> Trả lời
                        </button>
                        {user?.id === comment.userId && (
                          <button 
                            onClick={() => {
                              setEditingReviewId(comment.id);
                              setEditRating(comment.rating);
                              setEditContent(comment.comment);
                            }}
                            className="flex items-center text-gray-600 hover:text-gray-800 transition"
                          >
                            <Edit2 size={14} className="mr-1" /> Sửa
                          </button>
                        )}
                        {(isAdminOrStaff || user?.id === comment.userId) && (
                          <button 
                            onClick={() => handleDeleteComment(comment.id, isAdminOrStaff && user?.id !== comment.userId)}
                            className="flex items-center text-red-600 hover:text-red-800 transition"
                          >
                            <Trash2 size={14} className="mr-1" /> Xóa
                          </button>
                        )}
                      </div>
                    )}
                    
                    {/* Edit Input Box */}
                    {editingReviewId === comment.id && (
                      <div className="mt-3 bg-white p-3 border border-gray-200 rounded-lg shadow-sm">
                        <div className="flex mb-2">
                          {[...Array(5)].map((_, i) => (
                            <Star 
                              key={i} 
                              size={16} 
                              className={`cursor-pointer transition-colors ${i < editRating ? 'fill-yellow-400 text-yellow-400' : 'text-gray-300'}`}
                              onClick={() => setEditRating(i + 1)}
                            />
                          ))}
                        </div>
                        <div className="flex gap-2">
                          <input 
                            type="text" 
                            value={editContent}
                            onChange={e => setEditContent(e.target.value)}
                            className="flex-1 bg-white border border-gray-200 rounded-lg px-3 py-2 text-sm outline-none focus:border-blue-500"
                          />
                          <button 
                            onClick={() => handleUpdateComment(comment.id)}
                            disabled={!editContent.trim()}
                            className="bg-green-600 text-white px-3 py-2 rounded-lg text-sm hover:bg-green-700 disabled:opacity-50 flex items-center"
                          >
                            <Check size={16} className="mr-1"/> Lưu
                          </button>
                          <button 
                            onClick={() => setEditingReviewId(null)}
                            className="bg-gray-200 text-gray-700 px-3 py-2 rounded-lg text-sm hover:bg-gray-300 flex items-center"
                          >
                            <X size={16} className="mr-1"/> Hủy
                          </button>
                        </div>
                      </div>
                    )}

                    {/* Reply Input Box */}
                    {replyingTo === comment.id && (
                      <div className="mt-3 flex gap-2">
                        <input 
                          type="text" 
                          value={replyContent}
                          onChange={e => setReplyContent(e.target.value)}
                          placeholder="Nhập câu trả lời của bạn..."
                          className="flex-1 bg-white border border-gray-200 rounded-lg px-3 py-2 text-sm outline-none focus:border-blue-500"
                        />
                        <button 
                          onClick={() => handleReplySubmit(comment.id)}
                          disabled={!replyContent.trim()}
                          className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700 disabled:opacity-50"
                        >
                          Gửi
                        </button>
                      </div>
                    )}
                  </div>
                  {/* Replies (if any) */}
                  {comment.replies && comment.replies.length > 0 && (
                    <div className="mt-3 ml-4 space-y-3 border-l-2 border-gray-100 pl-4">
                      {comment.replies.map((reply: any, idx) => (
                        <div key={idx} className="flex gap-3">
                          <div className="w-8 h-8 bg-gray-200 rounded-full flex items-center justify-center text-gray-600 flex-shrink-0 text-sm font-bold overflow-hidden">
                            {reply.userAvatar ? (
                              <img src={reply.userAvatar} alt="avatar" className="w-full h-full object-cover" />
                            ) : (
                              reply.userName ? reply.userName.charAt(0).toUpperCase() : <User size={14} />
                            )}
                          </div>
                          <div className="flex-1 bg-white p-3 rounded-xl border border-gray-100 text-sm">
                            <div className="flex justify-between mb-1">
                              <span className="font-semibold flex items-center gap-2">
                                {reply.userName}
                                {(reply.userRole === 'Admin' || reply.userRole === 'Staff') && (
                                   <span className="bg-red-500 text-white text-[10px] px-2 py-0.5 rounded-full font-bold">QTV</span>
                                )}
                              </span>
                              <span className="text-xs text-gray-400">{formatDate(reply.createdAt)}</span>
                            </div>
                            
                            {editingReplyId?.replyId === reply.id ? (
                              <div className="mt-2 flex gap-2">
                                <input 
                                  type="text" 
                                  value={editReplyContent}
                                  onChange={e => setEditReplyContent(e.target.value)}
                                  className="flex-1 bg-white border border-gray-200 rounded-lg px-2 py-1 outline-none focus:border-blue-500"
                                />
                                <button 
                                  onClick={() => handleUpdateReply(comment.id, reply.id)}
                                  disabled={!editReplyContent.trim()}
                                  className="bg-green-600 text-white px-2 py-1 rounded-lg hover:bg-green-700 disabled:opacity-50"
                                >
                                  Lưu
                                </button>
                                <button 
                                  onClick={() => setEditingReplyId(null)}
                                  className="bg-gray-200 text-gray-700 px-2 py-1 rounded-lg hover:bg-gray-300"
                                >
                                  Hủy
                                </button>
                              </div>
                            ) : (
                              <p className="text-gray-600">{reply.comment}</p>
                            )}

                            {isAuthenticated && editingReplyId?.replyId !== reply.id && (
                              <div className="mt-2 flex gap-3 text-xs">
                                {user?.id === reply.userId && (
                                  <button 
                                    onClick={() => {
                                      setEditingReplyId({ reviewId: comment.id, replyId: reply.id });
                                      setEditReplyContent(reply.comment);
                                    }}
                                    className="flex items-center text-gray-500 hover:text-gray-700 transition"
                                  >
                                    <Edit2 size={12} className="mr-1" /> Sửa
                                  </button>
                                )}
                                {(isAdminOrStaff || user?.id === reply.userId) && (
                                  <button 
                                    onClick={() => handleDeleteReply(comment.id, reply.id)}
                                    className="flex items-center text-red-500 hover:text-red-700 transition"
                                  >
                                    <Trash2 size={12} className="mr-1" /> Xóa
                                  </button>
                                )}
                              </div>
                            )}
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-gray-500 border border-dashed rounded-xl border-gray-200">
            Chưa có bình luận nào. Hãy là người đầu tiên đánh giá sản phẩm này!
          </div>
        )}
      </div>
    </div>
  );
};
