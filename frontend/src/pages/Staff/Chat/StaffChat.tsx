import React, { useState, useEffect, useRef } from "react";
import * as signalR from "@microsoft/signalr";
import { chatApi } from "../../../api/chatApi";
import { adminApi } from "../../../api/adminApi";
import { useAuth } from "../../../contexts/AuthContext";
import type { ChatSession, ChatMessage } from "../../../types";

export const StaffChatPage: React.FC = () => {
  const { user } = useAuth();
  const [sessions, setSessions] = useState<ChatSession[]>([]);
  const [activeSession, setActiveSession] = useState<ChatSession | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState("");
  const [connection, setConnection] = useState<signalR.HubConnection | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

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

    const conn = new signalR.HubConnectionBuilder()
      .withUrl("https://localhost:7119/chatHub", { skipNegotiation: true, transport: signalR.HttpTransportType.WebSockets })
      .withAutomaticReconnect()
      .build();

    conn.on("ReceiveMessage", (message) => {
      setMessages(prev => {
        if (activeSession && message.sessionId === activeSession.id) {
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
      if (activeSession?.id === updatedSession.id) {
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

  return (
    <div className="flex h-[calc(100vh-64px)] font-sans border-t border-gray-200">
      <div className="w-80 bg-white border-r flex flex-col">
        <div className="p-4 bg-gray-50 border-b font-bold text-gray-700">Khách hàng cần hỗ trợ</div>
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
                  Được hỗ trợ bởi: {s.staffName}
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
                <span>Chat với {activeSession.customerName}</span>
                {activeSession.staffName && (
                  <div className="text-xs text-gray-500 mt-1">Nhân viên hỗ trợ: {activeSession.staffName}</div>
                )}
              </div>
              <div className="flex gap-2 items-center">
                {!activeSession.staffId && (
                  <button 
                    onClick={handleAssignStaff}
                    className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700 transition-colors"
                  >
                    Nhận hỗ trợ
                  </button>
                )}
                <span className="bg-green-100 text-green-700 px-3 py-1 rounded-full text-xs">Đang hoạt động</span>
              </div>
            </div>
            <div className="flex-1 overflow-y-auto p-6 flex flex-col gap-4">
              {messages.map((msg, idx) => (
                <div key={idx} className={`max-w-[70%] p-3 rounded-2xl text-sm shadow-sm ${msg.senderId === user?.id ? "bg-blue-600 text-white self-end rounded-br-none shadow-md" : "bg-white border border-gray-200 text-gray-800 self-start rounded-bl-none shadow-sm"}`}>
                  <div className="font-bold text-xs opacity-70 mb-1">{msg.senderName} ({msg.senderRole})</div>
                  <div>{msg.content}</div>
                  <div className="text-xs opacity-50 mt-1">{new Date(msg.timestamp).toLocaleTimeString("vi-VN")}</div>
                </div>
              ))}
              <div ref={messagesEndRef} />
            </div>
            <div className="p-4 bg-white border-t">
              <form onSubmit={handleSend} className="flex gap-2">
                <input 
                  type="text" 
                  value={input} 
                  onChange={(e) => setInput(e.target.value)} 
                  placeholder="Nhập tin nhắn..." 
                  className="flex-1 px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500" 
                />
                <button type="submit" className="bg-blue-600 text-white px-6 py-3 rounded-xl hover:bg-blue-700 font-medium transition-colors shadow-sm">
                  Gửi
                </button>
              </form>
            </div>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center text-gray-400">
            Chọn một cuộc trò chuyện để bắt đầu
          </div>
        )}
      </div>
    </div>
  );
};
