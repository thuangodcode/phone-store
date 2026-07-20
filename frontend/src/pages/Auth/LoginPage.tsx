import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import axiosClient from '../../api/axiosClient';
import { toast } from 'react-toastify';



const EyeIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="h-4 w-4 text-zinc-500 dark:text-zinc-400">
    <path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z" />
    <circle cx="12" cy="12" r="3" />
  </svg>
);

const EyeOffIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="h-4 w-4 text-zinc-500 dark:text-zinc-400">
    <path d="M9.88 9.88a3 3 0 1 0 4.24 4.24" />
    <path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68" />
    <path d="M6.61 6.61A13.526 13.526 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61" />
    <line x1="2" x2="22" y1="2" y2="22" />
  </svg>
);

const AppleIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" className="h-6 w-6">
    <path fill="currentColor" d="M18.71 19.5C17.88 20.74 17 21.95 15.66 21.97C14.32 22 13.89 21.18 12.37 21.18C10.84 21.18 10.37 21.95 9.09997 22C7.78997 22.05 6.79997 20.68 5.95997 19.47C4.24997 17 2.93997 12.45 4.69997 9.39C5.56997 7.87 7.12997 6.91 8.81997 6.88C10.1 6.86 11.32 7.75 12.11 7.75C12.89 7.75 14.37 6.68 15.92 6.84C16.57 6.87 18.39 7.1 19.56 8.82C19.47 8.88 17.39 10.1 17.41 12.63C17.44 15.65 20.06 16.66 20.09 16.67C20.06 16.74 19.67 18.11 18.71 19.5ZM13 3.5C13.73 2.67 14.94 2.04 15.94 2C16.07 3.17 15.6 4.35 14.9 5.19C14.21 6.04 13.07 6.7 11.95 6.61C11.8 5.46 12.36 4.26 13 3.5Z" />
  </svg>
);

const GoogleIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" className="h-5 w-5">
    <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"></path>
    <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"></path>
    <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z" fill="#FBBC05"></path>
    <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"></path>
    <path d="M1 1h22v22H1z" fill="none"></path>
  </svg>
);

const XIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor" className="h-5 w-5 text-zinc-900 dark:text-white">
    <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
  </svg>
);

export const LoginPage: React.FC = () => {
  const [showPassword, setShowPassword] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) return toast.error('Vui lòng nhập email và mật khẩu');

    try {
      setIsLoading(true);

      // Set a timeout for the request
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 30000); // 30 second timeout

      const res = await axiosClient.post('/auth/login', { email, password }, {
        signal: controller.signal
      });

      clearTimeout(timeoutId);

      if (res.data) {
        login(res.data.user, res.data.token);
        toast.success('Đăng nhập thành công!');
        if (res.data.user.role?.toLowerCase() === 'admin') {
          navigate('/admin');
        } else if (res.data.user.role?.toLowerCase() === 'staff') {
          navigate('/staff');
        } else {
          navigate('/');
        }
      }
    } catch (err: any) {
      if (err?.name === 'AbortError') {
        toast.error('Yêu cầu quá hạn. Vui lòng thử lại.');
      } else {
        toast.error(err?.response?.data?.message || err?.message || 'Đăng nhập thất bại');
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
      <div className="relative w-full max-w-4xl min-h-[550px] grid grid-cols-1 md:grid-cols-2 bg-white/80 backdrop-blur-xl border border-zinc-200/80 rounded-3xl overflow-hidden shadow-2xl z-0">

        {/* Left Column: Brand & Slogan */}
        <div className="hidden md:flex flex-col justify-between p-12 bg-gradient-to-br from-zinc-50 via-zinc-100 to-zinc-200/80 relative overflow-hidden border-r border-zinc-200/80">
          <div className="absolute top-0 right-0 w-[250px] h-[250px] rounded-full bg-amber-500/10 blur-[80px] pointer-events-none" />

          <div className="space-y-8 z-10">
            {/* Back to Home Button (Desktop only) */}
            <div>
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

            {/* Logo */}
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-xl bg-gradient-to-tr from-zinc-900 to-zinc-800 flex items-center justify-center shadow-md shadow-zinc-900/10">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                  <rect width="14" height="20" x="5" y="2" rx="2" ry="2" />
                  <path d="M12 18h.01" />
                </svg>
              </div>
              <span className="text-sm font-bold tracking-widest bg-gradient-to-r from-zinc-900 to-zinc-600 bg-clip-text text-transparent">PHONE STORE</span>
            </div>
          </div>

          {/* Slogan */}
          <div className="space-y-4 my-auto">
            <h2 className="text-3xl font-extrabold tracking-tight leading-tight bg-gradient-to-r from-zinc-955 via-zinc-900 to-zinc-700 bg-clip-text text-transparent">
              Định Nghĩa Lại Trải Nghiệm Công Nghệ
            </h2>
            <p className="text-zinc-600 text-sm leading-relaxed max-w-xs">
              Chào mừng bạn đến với Phone Store. Nơi hội tụ những tinh hoa công nghệ đỉnh cao và trải nghiệm mua sắm xa xỉ bậc nhất.
            </p>
          </div>

          {/* Footer Info */}
          <div className="text-[11px] text-zinc-400 flex items-center justify-between">
            <span>© 2026 PhoneStore. All rights reserved.</span>
            <span className="flex items-center gap-1.5 text-zinc-500">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
              Bảo mật 256-bit
            </span>
          </div>
        </div>

        {/* Right Column: Login Form */}
        <div className="flex flex-col justify-center p-8 sm:p-12 space-y-6">
          {/* Back to Home Button (Mobile only) */}
          <div className="md:hidden self-start pb-2">
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

          <div className="text-center md:text-left space-y-2">
            <h1 className="text-2xl font-bold tracking-tight text-zinc-900">Đăng nhập tài khoản</h1>
            <p className="text-sm text-zinc-500">Nhập email và mật khẩu của bạn để truy cập hệ thống</p>
          </div>

          <form className="space-y-4" onSubmit={handleLogin}>
            <div className="space-y-1.5 text-left">
              <label htmlFor="email" className="text-xs font-semibold uppercase tracking-wider text-zinc-500">
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
            <div className="space-y-1.5 text-left">
              <label htmlFor="password" className="text-xs font-semibold uppercase tracking-wider text-zinc-500">
                Mật khẩu
              </label>
              <div className="relative">
                <input
                  type={showPassword ? "text" : "password"}
                  id="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Nhập mật khẩu của bạn"
                  className="flex h-11 w-full rounded-xl border border-zinc-200 bg-white px-4 py-3 pr-10 text-sm text-zinc-900 placeholder:text-zinc-400 focus:outline-none focus:border-zinc-400 focus:ring-4 focus:ring-zinc-500/5 transition-all duration-300 shadow-inner"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-zinc-400 hover:text-zinc-600 transition-colors cursor-pointer"
                >
                  {showPassword ? <EyeOffIcon /> : <EyeIcon />}
                </button>
              </div>
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
                  Đang đăng nhập...
                </span>
              ) : 'Đăng Nhập'}
            </button>
          </form>

          <div className="text-center space-y-3 pt-2">
            <p className="text-sm text-zinc-500">
              Chưa có tài khoản?{' '}
              <Link to="/register" className="font-semibold text-zinc-900 underline underline-offset-4 hover:text-zinc-700 transition-colors">
                Đăng ký ngay
              </Link>
            </p>
            <Link to="/forgot-password" className="block text-xs font-semibold text-zinc-500 hover:text-zinc-700 transition-colors">
              Quên mật khẩu?
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};
