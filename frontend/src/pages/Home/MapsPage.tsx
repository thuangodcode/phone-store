import React, { useState } from 'react';

export const MapsPage: React.FC = () => {
  const [address, setAddress] = useState('');
  
  const destination = 'Nhà văn hoá sinh viên, Bình Dương';
  const encodedDestination = encodeURIComponent(destination);
  const mapIframeUrl = `https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3918.066487841584!2d106.79899127480655!3d10.882548889272365!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x3174d8a5568c997f%3A0xdeac05f17a166e0c!2zTmjDoCBWxINuIGhvw6Egc2luaCB2acOqbiBUUC5IQ00gKENTIEzDoG5nIMSQSCBRR-G7kWMgR2lhIFRQLkhDTSk!5e0!3m2!1svi!2s!4v1700000000000!5m2!1svi!2s`;

  const handleGetDirections = (e: React.FormEvent) => {
    e.preventDefault();
    if (!address.trim()) return;
    const encodedOrigin = encodeURIComponent(address);
    const directionsUrl = `https://www.google.com/maps/dir/?api=1&origin=${encodedOrigin}&destination=${encodedDestination}`;
    window.open(directionsUrl, '_blank');
  };

  return (
    <div className="container mx-auto px-4 py-8 max-w-6xl font-sans">
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Hệ thống Cửa hàng</h1>
        <p className="text-gray-600">Tìm kiếm đường đi đến cửa hàng PhoneStore gần bạn nhất</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Left column: Info & Form */}
        <div className="lg:col-span-1 space-y-6">
          <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200">
            <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
              <svg className="w-6 h-6 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
              Trụ sở chính
            </h2>
            <div className="space-y-3 text-gray-600">
              <p><strong>Địa chỉ:</strong> Nhà Văn Hoá Sinh Viên, ĐHQG TPHCM, Dĩ An, Bình Dương</p>
              <p><strong>Điện thoại:</strong> 0123 456 789</p>
              <p><strong>Giờ mở cửa:</strong> 08:00 - 21:00 (Tất cả các ngày trong tuần)</p>
            </div>
          </div>

          <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200">
            <h2 className="text-xl font-bold mb-4">Chỉ đường tới cửa hàng</h2>
            <form onSubmit={handleGetDirections} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Địa chỉ của bạn</label>
                <input 
                  type="text" 
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  placeholder="Nhập địa chỉ của bạn..." 
                  className="w-full px-4 py-2 rounded-lg border focus:ring-2 focus:ring-blue-500 outline-none"
                  required
                />
              </div>
              <button 
                type="submit" 
                className="w-full bg-blue-600 text-white font-bold py-2 rounded-lg hover:bg-blue-700 transition flex items-center justify-center gap-2"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7"></path></svg>
                Tìm đường đi
              </button>
            </form>
          </div>
        </div>

        {/* Right column: Map */}
        <div className="lg:col-span-2 bg-gray-100 rounded-2xl overflow-hidden shadow-sm border border-gray-200 h-[500px] lg:h-auto min-h-[400px]">
          <iframe 
            src={mapIframeUrl}
            width="100%" 
            height="100%" 
            style={{ border: 0 }} 
            allowFullScreen={true} 
            loading="lazy" 
            referrerPolicy="no-referrer-when-downgrade"
            title="Bản đồ PhoneStore"
          ></iframe>
        </div>
      </div>
    </div>
  );
};
