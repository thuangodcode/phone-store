import React, { useState, useRef, useEffect } from 'react';
import { getAIChatErrorMessage, sendAIChatMessage } from '../../../api/aiApi';
import { useAuth } from '../../../contexts/AuthContext';
import { PromptInputBox } from '../../../components/ui/ai-prompt-box';
import ReactMarkdown from 'react-markdown';

interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
}

export const AIAssistantPage: React.FC = () => {
  const { user } = useAuth();
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [loading, setLoading] = useState(false);
  const [sessionId] = useState(`session-${Math.random().toString(36).substr(2, 9)}`);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSend = async (text: string) => {
    if (!text.trim()) return;

    const userMessage: ChatMessage = {
      id: Date.now().toString(),
      role: 'user',
      content: text,
    };
    setMessages((prev) => [...prev, userMessage]);
    setLoading(true);

    try {
      const response = await sendAIChatMessage(text, sessionId);
      
      const aiMessage: ChatMessage = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: response.response || 'Không nhận được phản hồi từ trợ lý AI.',
      };
      
      setMessages((prev) => [...prev, aiMessage]);
    } catch (error) {
      console.error('AI Chat Error:', error);
      const errorMessage: ChatMessage = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: getAIChatErrorMessage(error),
      };
      setMessages((prev) => [...prev, errorMessage]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col h-[calc(100vh-100px)] bg-gray-50 rounded-2xl overflow-hidden shadow-sm border border-gray-200 m-6">
      {/* Header */}
      <div className="bg-white p-6 border-b border-gray-200 flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-800 flex items-center gap-2">
            ✨ PhoneStore AI Assistant
          </h2>
          <p className="text-gray-500 text-sm mt-1">Trợ lý phân tích kinh doanh và hỗ trợ nghiệp vụ</p>
        </div>
      </div>
      
      {/* Messages Area */}
      <div className="flex-1 p-8 overflow-y-auto bg-gray-50 flex flex-col gap-6">
        {messages.length === 0 && (
          <div className="flex flex-col items-center justify-center h-full text-gray-500 space-y-6 max-w-2xl mx-auto text-center">
            <div className="w-24 h-24 bg-gradient-to-tr from-indigo-100 to-purple-100 rounded-full flex items-center justify-center mb-4 shadow-inner">
              <span className="text-5xl">👋</span>
            </div>
            <h3 className="font-bold text-gray-800 text-2xl">Xin chào {user?.fullName || 'bạn'}!</h3>
            <p className="text-base text-gray-600">
              Tôi là trợ lý AI chuyên nghiệp dành cho bộ phận Quản lý. Tôi có thể truy xuất báo cáo doanh thu, tình trạng đơn hàng, và phân tích hiệu suất kinh doanh hoàn toàn tự động.
            </p>
            <div className="flex gap-3 justify-center mt-6">
              <button className="bg-white border border-gray-200 px-4 py-2 rounded-xl text-sm font-medium shadow-sm hover:border-indigo-400 hover:text-indigo-600 transition-colors" onClick={() => handleSend('Cho tôi xem báo cáo doanh thu tổng quan')}>
                📊 Báo cáo doanh thu
              </button>
              <button className="bg-white border border-gray-200 px-4 py-2 rounded-xl text-sm font-medium shadow-sm hover:border-indigo-400 hover:text-indigo-600 transition-colors" onClick={() => handleSend('Sản phẩm nào đang bán chạy nhất?')}>
                🏆 Sản phẩm bán chạy
              </button>
            </div>
          </div>
        )}
        
        {messages.map((msg) => (
          <div key={msg.id} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
            <div className={`max-w-[75%] p-5 rounded-3xl text-sm shadow-sm ${
              msg.role === 'user' 
                ? 'bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-br-none' 
                : 'bg-white border border-gray-200 text-gray-800 rounded-bl-none'
            }`}>
              {msg.role === 'assistant' ? (
                <div className="prose prose-sm md:prose-base max-w-none prose-p:my-2 prose-a:text-indigo-600 prose-strong:text-indigo-900">
                  <ReactMarkdown>{msg.content}</ReactMarkdown>
                </div>
              ) : (
                <div className="text-base">{msg.content}</div>
              )}
            </div>
          </div>
        ))}
        
        {loading && (
          <div className="flex justify-start">
            <div className="bg-white border border-gray-200 p-5 rounded-3xl rounded-bl-none shadow-sm flex items-center gap-3">
              <span className="w-2.5 h-2.5 bg-indigo-600 rounded-full animate-bounce"></span>
              <span className="w-2.5 h-2.5 bg-purple-600 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }}></span>
              <span className="w-2.5 h-2.5 bg-pink-600 rounded-full animate-bounce" style={{ animationDelay: '0.4s' }}></span>
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Input Area */}
      <div className="bg-white border-t border-gray-200 p-4">
        <PromptInputBox 
          onSend={handleSend} 
          disabled={loading} 
          placeholder="Nhập yêu cầu phân tích dữ liệu hoặc hỏi đáp nghiệp vụ..."
        />
      </div>
    </div>
  );
};
