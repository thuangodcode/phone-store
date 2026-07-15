import React, { useState, useEffect, useRef } from "react";
import * as signalR from "@microsoft/signalr";
import { chatApi } from "../../../api/chatApi";
import { adminApi } from "../../../api/adminApi";
import { useAuth } from "../../../contexts/AuthContext";
import type { ChatSession, ChatMessage } from "../../../types";
import axiosClient from "../../../api/axiosClient";

export const StaffChatPage: React.FC = () => {
  const { user } = useAuth();
  const [sessions, setSessions] = useState<ChatSession[]>([]);
  const [activeSession, setActiveSession] = useState<ChatSession | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState("");
  const [showQuickReplies, setShowQuickReplies] = useState(false);
  const [showProductModal, setShowProductModal] = useState(false);
  const [products, setProducts] = useState<any[]>([]);
  const [connection, setConnection] = useState<signalR.HubConnection | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const activeSessionRef = useRef<ChatSession | null>(null);

  const QUICK_REPLIES = [
    "Chào bạn, PhoneStore có thể giúp gì cho bạn hôm nay?",
    "Cảm ơn quý khách đã quan tâm đến sản phẩm của shop.",
    "Xin quý khách vui lòng để lại số điện thoại để nhân viên tư vấn chi tiết hơn.",
    "Sản phẩm này hiện đang có sẵn, quý khách có muốn đặt hàng ngay không?",
    "Xin lỗi quý khách vì sự chậm trễ này, chúng tôi sẽ kiểm tra và phản hồi lại ngay.",
    "Cảm ơn quý khách, chúc quý khách một ngày tốt lành!"
  ];

  useEffect(() => {
    if (showProductModal && products.length === 0) {
      axiosClient.get('/products?pageSize=10').then((res: any) => {
        setProducts(res.data?.items || []);
      }).catch(console.error);
    }
  }, [showProductModal]);

  useEffect(() => {
    activeSessionRef.current = activeSession;
  }, [activeSession]);

  const fetchSessions = async () => {
    try {
      const data = await chatApi.getSessions();
      setSessions(data || []);
    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => {
    fetchSessions();

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
        if (activeSessionRef.current && message.sessionId === activeSessionRef.current.id) {
          return [...prev, message];
        }
        return prev;
      });
    });

    conn.on("NewMessage", async () => {
      await fetchSessions();
    });

    conn.on("StaffAssigned", async (updatedSession: ChatSession) => {
      setSessions(prev => prev.map(s => s.id === updatedSession.id ? updatedSession : s));
      if (activeSessionRef.current?.id === updatedSession.id) {
        setActiveSession(updatedSession);
      }
    });

    conn.start().then(async () => {
      setConnection(conn);
      try {
        await conn.invoke("JoinStaff");
      } catch (err) {
        console.error("Error joining staff group:", err);
      }
    });

    return () => { conn.stop(); };
  }, []);

  useEffect(() => {
    if (activeSession && connection) {
      chatApi.getMessages(activeSession.id).then(data => setMessages(data || []));
      connection.invoke("JoinSession", activeSession.id).catch(console.error);
    }
  }, [activeSession, connection]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || !activeSession) return;
    try {
      await chatApi.sendMessage(activeSession.id, input);
      setInput("");
    } catch (e) {
      console.error(e);
    }
  };

  const handleAssignStaff = async () => {
    if (!activeSession) return;
    try {
      const updatedSession = await adminApi.assignStaffToSession(activeSession.id);
      setSessions(prev => prev.map(s => s.id === updatedSession.id ? updatedSession : s));
      setActiveSession(updatedSession);
    } catch (e) {
      console.error(e);
    }
  };

  const renderMessageContent = (content: string) => {
    if (content.startsWith('[PRODUCT]:')) {
      const productId = content.replace('[PRODUCT]:', '');
      return (
        <div className="mt-2 p-3 bg-white border border-gray-200 rounded-lg text-black text-xs font-sans">
          <div className="flex items-center gap-2 mb-2">
            <svg className="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"></path></svg>
            <strong>S?n ph?m dính kèm</strong>
          </div>
          <div className="text-gray-600 truncate">ID: {productId}</div>
          <a href={`/product/${productId}`} target="_blank" rel="noreferrer" className="text-blue-600 underline mt-2 inline-block">Xem chi ti?t &rarr;</a>
        </div>
      );
    }
    return <div>{content}</div>;
  };

  return (
    <div className="flex h-[calc(100vh-64px)] font-sans border-t border-gray-200">
      <div className="w-80 bg-white border-r flex flex-col">
        <div className="p-4 bg-gray-50 border-b font-bold text-gray-700">KhÃ¡ch hÃ ng cáº§n há»— trá»£</div>
        <div className="flex-1 overflow-y-auto">
          {sessions.map(s => (
            <div 
              key={s.id} 
              onClick={() => setActiveSession(s)}
              className={`p-4 border-b cursor-pointer hover:bg-gray-50 transition-colors ${activeSession?.id === s.id ? "bg-blue-50 border-l-4 border-l-blue-600" : ""}`}
            >
              <div className="font-bold text-gray-800">{s.customerName}</div>
              {s.staffName && (
                <div className="text-xs text-blue-600 mt-1 font-medium">
                  ÄÆ°á»£c há»— trá»£ bá»Ÿi: {s.staffName}
                </div>
              )}
              <div className="text-xs text-gray-500 mt-1">{new Date(s.updatedAt).toLocaleString("vi-VN")}</div>
            </div>
          ))}
        </div>
      </div>
      
      <div className="flex-1 flex flex-col bg-gray-50">
        {activeSession ? (
          <>
            <div className="p-4 bg-white border-b shadow-sm font-bold flex justify-between items-center">
              <div>
                <span>Chat vá»›i {activeSession.customerName}</span>
                {activeSession.staffName && (
                  <div className="text-xs text-gray-500 mt-1">NhÃ¢n viÃªn há»— trá»£: {activeSession.staffName}</div>
                )}
              </div>
              <div className="flex gap-2 items-center">
                {!activeSession.staffId && (
                  <button 
                    onClick={handleAssignStaff}
                    className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700 transition-colors"
                  >
                    Nháº­n há»— trá»£
                  </button>
                )}
                <span className="bg-green-100 text-green-700 px-3 py-1 rounded-full text-xs">Äang hoáº¡t Ä‘á»™ng</span>
              </div>
            </div>
            <div className="flex-1 overflow-y-auto p-6 flex flex-col gap-4">
              {messages.map((msg, idx) => (
                <div key={idx} className={`max-w-[70%] p-3 rounded-2xl text-sm shadow-sm ${msg.senderId === user?.id ? "bg-blue-600 text-white self-end rounded-br-none shadow-md" : "bg-white border border-gray-200 text-gray-800 self-start rounded-bl-none shadow-sm"}`}>
                  <div className="font-bold text-xs opacity-70 mb-1">{msg.senderName} ({msg.senderRole})</div>
                  {renderMessageContent(msg.content)}
                  <div className="text-xs opacity-50 mt-1">{new Date(msg.timestamp).toLocaleTimeString("vi-VN")}</div>
                </div>
              ))}
              <div ref={messagesEndRef} />
            </div>
            <div className="p-4 bg-white border-t">
              <form onSubmit={handleSend} className="flex gap-2 relative">
                <button type="button" onClick={() => setShowProductModal(!showProductModal)} className="p-3 text-gray-500 hover:text-blue-600 hover:bg-gray-100 rounded-xl transition-colors" title="Gửi sản phẩm">
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"></path></svg>
                </button>
                <button 
                  type="button" 
                  onClick={() => setShowQuickReplies(!showQuickReplies)} 
                  className="p-3 text-gray-500 hover:text-blue-600 hover:bg-gray-100 rounded-xl transition-colors" 
                  title="Tin nhắn mẫu"
                >
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z"></path></svg>
                </button>
                
                {showProductModal && (
                  <div className="absolute bottom-full left-0 mb-2 w-80 bg-white border border-gray-200 shadow-xl rounded-xl overflow-hidden z-10 animate-fade-in-up">
                    <div className="p-3 font-bold bg-gray-50 border-b text-sm flex justify-between items-center">
                      Gửi sản phẩm
                      <button type="button" onClick={() => setShowProductModal(false)} className="text-gray-400 hover:text-gray-600">
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                      </button>
                    </div>
                    <ul className="max-h-60 overflow-y-auto p-2">
                      {products.map(p => (
                        <li 
                          key={p.id} 
                          onClick={async () => { 
                            if (!activeSession) return;
                            try {
                              await chatApi.sendMessage(activeSession.id, `[PRODUCT]:${p.id}`);
                              setShowProductModal(false);
                            } catch (e) {
                              console.error(e);
                            }
                          }} 
                          className="flex items-center gap-3 p-2 hover:bg-blue-50 cursor-pointer rounded-lg border-b last:border-0"
                        >
                          <img src={p.images?.[0] || 'https://via.placeholder.com/40'} className="w-10 h-10 object-cover rounded" alt={p.name} />
                          <div className="flex-1 text-xs">
                            <div className="font-bold line-clamp-1">{p.name}</div>
                            <div className="text-blue-600">{p.price?.toLocaleString('vi-VN')} đ</div>
                          </div>
                        </li>
                      ))}
                    </ul>
                  </div>
                )}
                
                {showQuickReplies && (
                  <div className="absolute bottom-full left-0 mb-2 w-80 bg-white border border-gray-200 shadow-xl rounded-xl overflow-hidden z-10 animate-fade-in-up">
                    <div className="p-3 font-bold bg-gray-50 border-b text-sm flex justify-between items-center">
                      Tin nháº¯n máº«u
                      <button type="button" onClick={() => setShowQuickReplies(false)} className="text-gray-400 hover:text-gray-600">
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                      </button>
                    </div>
                    <ul className="max-h-60 overflow-y-auto">
                      {QUICK_REPLIES.map((reply, idx) => (
                        <li 
                          key={idx} 
                          onClick={() => { setInput(reply); setShowQuickReplies(false); }} 
                          className="p-3 text-sm text-gray-700 hover:bg-blue-50 hover:text-blue-700 cursor-pointer border-b last:border-0 transition-colors"
                        >
                          {reply}
                        </li>
                      ))}
                    </ul>
                  </div>
                )}

                <input 
                  type="text" 
                  value={input} 
                  onChange={(e) => setInput(e.target.value)} 
                  placeholder="Nháº­p tin nháº¯n..." 
                  className="flex-1 px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500" 
                />
                <button type="submit" className="bg-blue-600 text-white px-6 py-3 rounded-xl hover:bg-blue-700 font-medium transition-colors shadow-sm flex items-center gap-2">
                  <span>Gá»­i</span>
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"></path></svg>
                </button>
              </form>
            </div>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center text-gray-400">
            Chá»n má»™t cuá»™c trÃ² chuyá»‡n Ä‘á»ƒ báº¯t Ä‘áº§u
          </div>
        )}
      </div>
    </div>
  );
};


