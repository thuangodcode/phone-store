import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import axiosClient from '../../api/axiosClient';
import { toast } from 'react-toastify';

const LockIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="h-6 w-6 text-amber-500">
    <rect width="18" height="11" x="3" y="11" rx="2" ry="2" />
    <path d="M7 11V7a5 5 0 0 1 10 0v4" />
  </svg>
);

export const ForgotPasswordPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isSent, setIsSent] = useState(false);
  const navigate = useNavigate();

  const handleForgotPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) return toast.error('Vui lòng nhập địa chỉ email của bạn');

    try {
      setIsLoading(true);
      
      // Set a timeout for the request (60s to handle server cold starts)
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 60000);

      await axiosClient.post('/auth/forgot-password', { email }, {
        signal: controller.signal
      });

      clearTimeout(timeoutId);
      setIsSent(true);
      toast.success('Đã gửi liên kết đặt lại mật khẩu đến email của bạn.');
    } catch (err: any) {
      if (err?.code === 'ERR_CANCELED' || err === 'canceled') {
        toast.error('Yêu cầu quá hạn. Máy chủ có thể đang khởi động, vui lòng thử lại sau vài giây.');
      } else {
        const message = err?.response?.data?.message || err?.message || err?.toString?.() || 'Gửi liên kết đặt lại thất bại';
        toast.error(message);
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="relative w-full min-h-screen bg-zinc-50/50 flex items-center justify-center font-sans overflow-hidden text-zinc-900 p-4">
      {/* Background Ambient Glow */}
      <div className="absolute top-[-20%] left-[-10%] w-[500px] h-[500px] rounded-full bg-amber-500/5 blur-[120px] pointer-events-none" />
      <div className="absolute bottom-[-20%] right-[-10%] w-[500px] h-[500px] rounded-full bg-rose-500/5 blur-[120px] pointer-events-none" />

      <div className="relative w-full max-w-md p-8 space-y-6 bg-white/80 backdrop-blur-xl border border-zinc-200/80 rounded-3xl shadow-2xl z-0">
        {/* Back to Home Button */}
        <div className="flex self-start pb-2">
          <button
            onClick={() => navigate('/')}
            className="flex items-center gap-2 px-4 py-2 text-xs font-semibold uppercase tracking-wider text-zinc-600 bg-white/80 backdrop-blur-md rounded-full border border-zinc-200 hover:text-zinc-900 hover:border-zinc-300 hover:bg-white transition-all duration-300 shadow-sm"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <path d="M19 12H5M12 19l-7-7 7-7" />
            </svg>
            Trang chủ
          </button>
        </div>
        <div className="text-center space-y-3">
          <div className="inline-flex p-3 bg-zinc-100/80 border border-zinc-200 rounded-2xl shadow-inner">
            <LockIcon />
          </div>
          <div>
            <h1 className="text-2xl font-bold tracking-tight text-zinc-900">Quên mật khẩu</h1>
            <p className="text-sm text-zinc-500 mt-1 max-w-xs mx-auto">
              Nhập email của bạn và chúng tôi sẽ gửi liên kết để đặt lại mật khẩu mới.
            </p>
          </div>
        </div>

        {!isSent ? (
          <form className="space-y-4" onSubmit={handleForgotPassword}>
            <div className="space-y-1.5 text-left">
              <label htmlFor="email" className="text-xs font-semibold uppercase tracking-wider text-zinc-505">
                Email
              </label>
              <input
                type="email"
                id="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="name@example.com"
                className="flex h-11 w-full rounded-xl border border-zinc-200 bg-white px-4 py-3 text-sm text-zinc-900 placeholder:text-zinc-400 focus:outline-none focus:border-zinc-400 focus:ring-4 focus:ring-zinc-500/5 transition-all duration-300 shadow-inner"
              />
            </div>
            
            <button
              type="submit"
              disabled={isLoading}
              className="relative group flex items-center justify-center rounded-xl bg-zinc-900 hover:bg-black text-white font-semibold text-sm transition-all duration-300 shadow-md shadow-zinc-900/10 hover:scale-[1.01] active:scale-[0.99] h-11 w-full disabled:opacity-50 mt-2 cursor-pointer"
            >
              {isLoading ? (
                <span className="flex items-center gap-2">
                  <svg className="animate-spin h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Đang gửi liên kết...
                </span>
              ) : 'Gửi liên kết đặt lại'}
            </button>
          </form>
        ) : (
          <div className="bg-emerald-50 text-emerald-800 p-5 rounded-2xl text-sm text-center border border-emerald-200 leading-relaxed shadow-md">
            Hướng dẫn đặt lại mật khẩu đã được gửi thành công đến <strong>{email}</strong>. Vui lòng kiểm tra hộp thư đến của bạn.
          </div>
        )}

        <div className="text-center pt-2">
          <Link to="/login" className="text-sm font-semibold text-zinc-900 underline underline-offset-4 hover:text-zinc-700 transition-colors">
            Quay lại Đăng nhập
          </Link>
        </div>
      </div>
    </div>
  );
};
