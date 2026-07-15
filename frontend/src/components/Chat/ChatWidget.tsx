import React, { useState, useEffect, useRef } from "react";
import * as signalR from "@microsoft/signalr";
import { useAuth } from "../../contexts/AuthContext";
import { chatApi } from "../../api/chatApi";
import { adminApi } from "../../api/adminApi";
import axiosClient from "../../api/axiosClient";

const EMOJIS = ["😀","😂","😍","🥰","😎","😭","😡","👍","🙏","❤️","🔥","✨","🎉","📱","💻"];

export const CustomerChatWidget: React.FC = () => {
  const { isAuthenticated, user } = useAuth();
  const [isOpen, setIsOpen] = useState(false);
  const [messages, setMessages] = useState<any[]>([]);
  const [input, setInput] = useState("");
  const [session, setSession] = useState<any>(null);
  
  const [showEmojiPicker, setShowEmojiPicker] = useState(false);
  const [showProductModal, setShowProductModal] = useState(false);
  const [products, setProducts] = useState<any[]>([]);
  const [brands, setBrands] = useState<any[]>([]);
  const [selectedBrand, setSelectedBrand] = useState<any | null>(null);
  
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const connectionRef = useRef<signalR.HubConnection | null>(null);

  useEffect(() => {
    if (!isAuthenticated) return;

    let isMounted = true;

    const initChat = async () => {
      try {
        const sessionData = await chatApi.getActiveSession();
        if (!isMounted) return;
        setSession(sessionData);

        const msgs = await chatApi.getMessages(sessionData.id);
        if (isMounted) setMessages(msgs || []);

        const baseUrl = (import.meta.env.VITE_API_URL || 'https://phone-store-api-4bah.onrender.com/api').replace(/\/api$/, '');
        const token = localStorage.getItem('token');

        const conn = new signalR.HubConnectionBuilder()
          .withUrl(`${baseUrl}/chatHub`, {
             accessTokenFactory: () => token || '',
             skipNegotiation: true,
             transport: signalR.HttpTransportType.WebSockets
          })
          .withAutomaticReconnect()
          .build();

        conn.on("ReceiveMessage", (message) => {
          setMessages(prev => {
            if (prev.some(m => m.id === message.id)) return prev;
            return [...prev, message];
          });
        });

        await conn.start();
        await conn.invoke("JoinSession", sessionData.id);
        
        if (isMounted) {
          connectionRef.current = conn;
        } else {
          conn.stop();
        }
      } catch (err) {
        console.error("Chat init error:", err);
      }
    };

    initChat();

    return () => {
      isMounted = false;
      if (connectionRef.current) {
        connectionRef.current.stop();
      }
    };
  }, [isAuthenticated]);

  useEffect(() => {
    if (showProductModal && brands.length === 0) {
      adminApi.getBrands().then((res: any) => setBrands(res)).catch(console.error);
    }
  }, [showProductModal]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, isOpen]);

  const sendMessage = async (e?: React.FormEvent, customContent?: string) => {
    if (e) e.preventDefault();
    const contentToSend = customContent || input;
    if (!contentToSend.trim() || !session) return;
    try {
      if (!customContent) setInput("");
      await chatApi.sendMessage(session.id, contentToSend);
    } catch (error) {
      console.error("Error sending msg", error);
    }
  };

  const renderMessageContent = (content: string) => {
    if (content.startsWith('[PRODUCT]:')) {
      const productId = content.replace('[PRODUCT]:', '');
      return (
        <div className="mt-2 p-3 bg-white border border-gray-200 rounded-lg text-black text-xs font-sans">
          <div className="flex items-center gap-2 mb-2">
            <svg className="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"></path></svg>
            <strong>Sản phẩm đính kèm</strong>
          </div>
          <div className="text-gray-600 truncate">ID: {productId}</div>
          <a href={`/products/${productId}`} target="_blank" rel="noreferrer" className="text-blue-600 underline mt-2 inline-block">Xem chi tiết &rarr;</a>
        </div>
      );
    }
    return <div>{content}</div>;
  };

  if (!isAuthenticated) return null;

  return (
    <div className="fixed bottom-6 right-6 z-50 font-sans">
      {!isOpen && (
        <button 
          onClick={() => setIsOpen(true)}
          className="bg-blue-600 hover:bg-blue-700 text-white rounded-full p-4 shadow-lg transition-transform hover:scale-105 flex items-center justify-center relative"
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z"></path></svg>
          <span className="absolute top-0 right-0 w-3 h-3 bg-red-500 rounded-full border-2 border-white"></span>
        </button>
      )}

      {isOpen && (
        <div className="bg-white rounded-2xl shadow-2xl border border-gray-200 w-80 sm:w-96 flex flex-col h-[500px] overflow-hidden animate-fade-in-up">
          {/* Header */}
          <div className="bg-gradient-to-r from-blue-600 to-blue-700 p-4 text-white flex justify-between items-center shadow-md z-10">
            <div className="flex items-center gap-3">
              <div className="relative">
                <div className="w-10 h-10 bg-white rounded-full flex items-center justify-center text-blue-600 font-bold text-lg">
                  PS
                </div>
                <div className="absolute bottom-0 right-0 w-3 h-3 bg-green-400 rounded-full border-2 border-white"></div>
              </div>
              <div>
                <h3 className="font-bold leading-tight">PhoneStore Support</h3>
                <div className="text-xs text-blue-100">Đang hoạt động</div>
              </div>
            </div>
            <button onClick={() => setIsOpen(false)} className="text-white hover:bg-blue-800 p-2 rounded-full transition-colors">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
            </button>
          </div>
          
          {/* Messages */}
          <div className="flex-1 p-4 overflow-y-auto bg-gray-50 flex flex-col gap-3 relative">
            {messages.length === 0 && (
              <div className="text-center text-gray-500 text-sm mt-10">
                <div className="text-4xl mb-3">👋</div>
                Bắt đầu trò chuyện với chúng tôi!
              </div>
            )}
            {messages.map((msg, idx) => (
              <div key={idx} className={`max-w-[80%] p-3 rounded-2xl text-sm shadow-sm ${msg.senderId === user?.id ? "bg-blue-600 text-white self-end rounded-br-none" : "bg-white border text-gray-800 self-start rounded-bl-none"}`}>
                <div className="font-bold text-xs opacity-70 mb-1">{msg.senderName}</div>
                {renderMessageContent(msg.content)}
              </div>
            ))}
            <div ref={messagesEndRef} />
            
            {/* Product Modal overlay */}
            {showProductModal && (
              <div className="absolute inset-0 bg-white z-20 flex flex-col">
                <div className="p-3 border-b flex justify-between items-center font-bold bg-gray-50">
                  <div className="flex items-center gap-2">
                    {selectedBrand && (
                      <button onClick={() => setSelectedBrand(null)} className="text-blue-600 hover:bg-blue-50 p-1 rounded">
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 19l-7-7 7-7"></path></svg>
                      </button>
                    )}
                    {selectedBrand ? `SP của ${selectedBrand.name}` : 'Chọn hãng'}
                  </div>
                  <button onClick={() => { setShowProductModal(false); setSelectedBrand(null); }} className="text-gray-500 hover:bg-gray-100 p-1 rounded">
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                  </button>
                </div>
                <div className="flex-1 overflow-y-auto p-2">
                  {!selectedBrand ? (
                    <div className="grid grid-cols-2 gap-2">
                      {brands.map(b => (
                        <div key={b.id} onClick={() => {
                          setSelectedBrand(b);
                          axiosClient.get(`/products?brandId=${b.id}&pageSize=50`).then((res: any) => setProducts(res.data?.items || []));
                        }} className="border rounded-lg p-3 text-center cursor-pointer hover:border-blue-500 hover:bg-blue-50 font-medium">
                          {b.name}
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="flex flex-col">
                      {products.length === 0 ? <div className="p-4 text-center text-gray-500 text-sm">Đang tải hoặc không có sản phẩm...</div> : null}
                      {products.map(p => (
                        <div key={p.id} onClick={() => { sendMessage(undefined, `[PRODUCT]:${p.id}`); setShowProductModal(false); setSelectedBrand(null); }} className="flex items-center gap-3 p-2 hover:bg-blue-50 cursor-pointer rounded-lg border-b">
                          <img src={p.images?.[0] || 'https://via.placeholder.com/40'} className="w-10 h-10 object-cover rounded" alt={p.name} />
                          <div className="flex-1 text-xs">
                            <div className="font-bold line-clamp-1">{p.name}</div>
                            <div className="text-blue-600">{p.price?.toLocaleString('vi-VN')} đ</div>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>

          {/* Input Area */}
          <div className="p-3 bg-white border-t relative">
            {/* Emoji Picker */}
            {showEmojiPicker && (
              <div className="absolute bottom-full left-3 mb-2 bg-white border shadow-xl rounded-xl p-2 grid grid-cols-5 gap-2 w-48 z-10">
                {EMOJIS.map(emoji => (
                  <button key={emoji} type="button" onClick={() => { setInput(i => i + emoji); setShowEmojiPicker(false); }} className="hover:bg-gray-100 p-1 rounded text-lg">
                    {emoji}
                  </button>
                ))}
              </div>
            )}

            <form onSubmit={(e) => sendMessage(e)} className="flex items-center gap-2">
              <button type="button" onClick={() => setShowProductModal(!showProductModal)} className="text-gray-400 hover:text-blue-600 p-2" title="Gửi sản phẩm">
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"></path></svg>
              </button>
              
              <button type="button" onClick={() => setShowEmojiPicker(!showEmojiPicker)} className="text-gray-400 hover:text-yellow-500 p-2" title="Biểu tượng cảm xúc">
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
              </button>

              <input 
                type="text" 
                value={input} 
                onChange={(e) => setInput(e.target.value)} 
                placeholder="Nhập tin nhắn..." 
                className="flex-1 px-4 py-2 bg-gray-100 border-transparent rounded-full text-sm focus:bg-white focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all" 
              />
              <button type="submit" disabled={!input.trim()} className="bg-blue-600 text-white rounded-full p-2 hover:bg-blue-700 disabled:opacity-50 disabled:hover:bg-blue-600 transition-colors">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"></path></svg>
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

