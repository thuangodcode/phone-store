import React, { useState, useEffect, useRef } from "react";
import * as signalR from "@microsoft/signalr";
import { useAuth } from "../../contexts/AuthContext";
import { chatApi } from "../../api/chatApi";

export const CustomerChatWidget: React.FC = () => {
  const { isAuthenticated, user } = useAuth();
  const [isOpen, setIsOpen] = useState(false);
  const [messages, setMessages] = useState<any[]>([]);
  const [input, setInput] = useState("");
  const [session, setSession] = useState<any>(null);
  const [connection, setConnection] = useState<signalR.HubConnection | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!isAuthenticated || !isOpen) return;

    const initChat = async () => {
      try {
        const sessionData = await chatApi.getActiveSession();
        setSession(sessionData);

        const msgs = await chatApi.getMessages(sessionData.id);
        setMessages(msgs || []);

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
          setMessages(prev => [...prev, message]);
        });

        await conn.start();
        await conn.invoke("JoinSession", sessionData.id);
        setConnection(conn);
      } catch (err) {
        console.error("Chat init error:", err);
      }
    };

    initChat();

    return () => {
      if (connection) {
        connection.stop();
      }
    };
  }, [isAuthenticated, isOpen]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const sendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || !session) return;
    try {
      await chatApi.sendMessage(session.id, input);
      setInput("");
    } catch (error) {
      console.error("Error sending msg", error);
    }
  };

  if (!isAuthenticated) return null;

  return (
    <div className="fixed bottom-6 right-6 z-50 font-sans">
      {!isOpen && (
        <button 
          onClick={() => setIsOpen(true)}
          className="bg-blue-600 hover:bg-blue-700 text-white rounded-full p-4 shadow-lg transition-transform hover:scale-105 flex items-center justify-center"
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z"></path></svg>
        </button>
      )}

      {isOpen && (
        <div className="bg-white rounded-2xl shadow-2xl border border-gray-200 w-80 sm:w-96 flex flex-col h-[500px] overflow-hidden">
          <div className="bg-blue-600 p-4 text-white flex justify-between items-center">
            <h3 className="font-bold">Chat với Nhân viên</h3>
            <button onClick={() => setIsOpen(false)} className="text-white hover:text-gray-200">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
            </button>
          </div>
          
          <div className="flex-1 p-4 overflow-y-auto bg-gray-50 flex flex-col gap-3">
            {messages.length === 0 && (
              <div className="text-center text-gray-500 text-sm mt-10">Bắt đầu trò chuyện với chúng tôi!</div>
            )}
            {messages.map((msg, idx) => (
              <div key={idx} className={`max-w-[80%] p-3 rounded-xl text-sm ${msg.senderId === user?.id ? "bg-blue-600 text-white self-end rounded-tr-none" : "bg-white border text-gray-800 self-start rounded-tl-none shadow-sm"}`}>
                <div className="font-bold text-xs opacity-70 mb-1">{msg.senderName}</div>
                <div>{msg.content}</div>
              </div>
            ))}
            <div ref={messagesEndRef} />
          </div>

          <div className="p-3 bg-white border-t">
            <form onSubmit={sendMessage} className="flex gap-2">
              <input 
                type="text" 
                value={input} 
                onChange={(e) => setInput(e.target.value)} 
                placeholder="Nhập tin nhắn..." 
                className="flex-1 px-3 py-2 border rounded-full text-sm focus:outline-none focus:border-blue-500" 
              />
              <button type="submit" className="bg-blue-600 text-white rounded-full p-2 hover:bg-blue-700">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"></path></svg>
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
