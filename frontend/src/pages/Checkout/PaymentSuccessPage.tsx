import React, { useEffect, useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import axiosClient from '../../api/axiosClient';
import { toast } from 'react-toastify';

export const PaymentSuccessPage: React.FC = () => {
  const [status, setStatus] = useState<string>('Đang xác thực thanh toán...');
  const location = useLocation();
  const navigate = useNavigate();

  useEffect(() => {
    const searchParams = new URLSearchParams(location.search);
    const code = searchParams.get('code');
    const orderCode = searchParams.get('orderCode');
    const cancel = searchParams.get('cancel');

    if (cancel === 'true') {
      setStatus('Bạn đã huỷ thanh toán đơn hàng.');
      toast.error('Thanh toán đã bị huỷ', { toastId: 'payos-cancel' });
      setTimeout(() => navigate('/history'), 2000);
      return;
    }

    if (code === '00' && orderCode) {
      // Call backend to verify status proactively
      axiosClient.get(`/payment/check-status/${orderCode}`)
        .then((res: any) => {
          if (res.data?.data === true) {
            setStatus('Đặt hàng thành công!');
            toast.success('Thanh toán thành công! Đơn hàng của bạn đã được cập nhật.', { toastId: 'payos-success' });
          } else {
            setStatus('Thanh toán đang chờ xử lý.');
          }
          setTimeout(() => navigate('/history'), 3000);
        })
        .catch(() => {
          setStatus('Có lỗi xảy ra khi xác thực thanh toán.');
          setTimeout(() => navigate('/history'), 3000);
        });
    } else {
      setStatus('Không có thông tin thanh toán.');
      setTimeout(() => navigate('/history'), 3000);
    }
  }, [location, navigate]);

  return (
    <div className="min-h-[60vh] flex flex-col items-center justify-center font-sans px-4 text-center">
      <h1 className={`text-4xl font-bold mb-4 ${status === 'Đặt hàng thành công!' ? 'text-green-600' : 'text-gray-800'}`}>
        {status}
      </h1>
      <p className="text-gray-500 text-lg">Hệ thống đang chuyển hướng bạn về trang Lịch sử mua hàng...</p>
      
      <div className="mt-8 animate-spin rounded-full h-10 w-10 border-4 border-gray-200 border-t-red-600"></div>
    </div>
  );
};
