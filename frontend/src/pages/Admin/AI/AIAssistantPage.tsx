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

interface Conversation {
  id: string;
  title: string;
  createdAt: string;
  updatedAt: string;
  messages: ChatMessage[];
  deletedAt?: string | null;
}

const STORAGE_KEY = 'phoneStoreAiConversations';

const generateId = () => `conv-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;

const createConversation = () => {
  const createdAt = new Date().toISOString();
  return {
    id: generateId(),
    title: `Cuộc trò chuyện mới (${new Date(createdAt).toLocaleString('vi-VN')})`,
    createdAt,
    updatedAt: createdAt,
    messages: [],
    deletedAt: null,
  } as Conversation;
};

const deriveConversationTitle = (conversation: Conversation) => {
  const firstUserMessage = conversation.messages.find((message) => message.role === 'user');
  if (firstUserMessage) {
    const summary = firstUserMessage.content.trim().slice(0, 40);
    return summary.length === 40 ? `Q: ${summary}...` : `Q: ${summary}`;
  }
  return conversation.title;
};

export const AIAssistantPage: React.FC = () => {
  const { user } = useAuth();
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [activeConversationId, setActiveConversationId] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [showDeleted, setShowDeleted] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const activeConversation = conversations.find((conversation) => conversation.id === activeConversationId) ?? null;
  const messages = activeConversation?.messages ?? [];

  useEffect(() => {
    const saved = typeof window !== 'undefined' ? localStorage.getItem(STORAGE_KEY) : null;
    if (saved) {
      try {
        const storedConversations = JSON.parse(saved) as Conversation[];
        if (Array.isArray(storedConversations) && storedConversations.length > 0) {
          const latestConversation = storedConversations.find((conv) => !conv.deletedAt);
          if (latestConversation && latestConversation.messages.length === 0) {
            setConversations(storedConversations);
            setActiveConversationId(latestConversation.id);
          } else {
            const fresh = createConversation();
            setConversations([fresh, ...storedConversations]);
            setActiveConversationId(fresh.id);
          }
          return;
        }
      } catch {
        // ignore parse errors and initialize fresh
      }
    }

    const initialConversation = createConversation();
    setConversations([initialConversation]);
    setActiveConversationId(initialConversation.id);
  }, []);

  useEffect(() => {
    if (typeof window !== 'undefined') {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(conversations));
    }
  }, [conversations]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const appendMessage = (message: ChatMessage) => {
    if (!activeConversationId) return;
    setConversations((current) =>
      current.map((conversation) =>
        conversation.id === activeConversationId
          ? {
              ...conversation,
              title: deriveConversationTitle({ ...conversation, messages: [...conversation.messages, message] }),
              updatedAt: new Date().toISOString(),
              messages: [...conversation.messages, message],
            }
          : conversation,
      ),
    );
  };

  const handleSend = async (text: string) => {
    if (!text.trim() || !activeConversationId) return;

    const userMessage: ChatMessage = {
      id: Date.now().toString(),
      role: 'user',
      content: text,
    };

    appendMessage(userMessage);
    setLoading(true);

    try {
      const response = await sendAIChatMessage(text, activeConversationId);
      const aiMessage: ChatMessage = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: response.response || 'Không nhận được phản hồi từ trợ lý AI.',
      };
      appendMessage(aiMessage);
    } catch (error) {
      console.error('AI Chat Error:', error);
      const errorMessage: ChatMessage = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: getAIChatErrorMessage(error),
      };
      appendMessage(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const createNewConversation = () => {
    const active = conversations.find((c) => c.id === activeConversationId);
    if (active && !active.deletedAt && active.messages.length === 0) return;

    const newConversation = createConversation();
    setConversations((current) => [newConversation, ...current]);
    setActiveConversationId(newConversation.id);
  };

  const handleSelectConversation = (id: string) => {
    setActiveConversationId(id);
  };

  const handleSoftDeleteConversation = (id: string) => {
    setConversations((current) => {
      const updated = current.map((conversation) =>
        conversation.id === id
          ? { ...conversation, deletedAt: new Date().toISOString(), updatedAt: new Date().toISOString() }
          : conversation,
      );

      if (id === activeConversationId) {
        const nextConversation = updated.find((conversation) => !conversation.deletedAt && conversation.id !== id);
        if (nextConversation) {
          setActiveConversationId(nextConversation.id);
        } else {
          const fresh = createConversation();
          updated.unshift(fresh);
          setActiveConversationId(fresh.id);
        }
      }

      return updated;
    });
  };

  const handleRestoreConversation = (id: string) => {
    setConversations((current) =>
      current.map((conversation) =>
        conversation.id === id
          ? { ...conversation, deletedAt: null, updatedAt: new Date().toISOString() }
          : conversation,
      ),
    );
    setActiveConversationId(id);
  };

  const visibleConversations = conversations.filter((conversation) => !conversation.deletedAt).slice(0, 5);
  const deletedConversations = conversations.filter((conversation) => conversation.deletedAt);

  return (
    <div className="flex h-[calc(100vh-100px)] bg-gray-50 rounded-2xl overflow-hidden shadow-sm border border-gray-200 m-6">
      <div className="flex-1 flex flex-col overflow-hidden">
        <div className="bg-white p-6 border-b border-gray-200 flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <h2 className="text-2xl font-bold text-gray-800 flex items-center gap-2">
              ✨ PhoneStore AI Assistant
            </h2>
            <p className="text-gray-500 text-sm mt-1">Trợ lý phân tích kinh doanh và hỗ trợ nghiệp vụ</p>
          </div>
          <div className="flex flex-wrap items-center gap-3">
            <button
              type="button"
              onClick={createNewConversation}
              className="rounded-2xl border border-indigo-200 bg-indigo-50 px-4 py-2 text-sm font-semibold text-indigo-700 transition hover:bg-indigo-100"
            >
              + Cuộc trò chuyện mới
            </button>
            <button
              type="button"
              onClick={() => setShowDeleted((value) => !value)}
              className="rounded-2xl border border-slate-200 bg-white px-4 py-2 text-sm text-slate-700 transition hover:border-slate-300"
            >
              {showDeleted ? 'Ẩn đã xoá' : 'Hiện đã xoá'}
            </button>
          </div>
        </div>

        <div className="flex flex-1 overflow-hidden">
          <div className="flex-1 p-8 overflow-y-auto bg-gray-50 flex flex-col gap-6">
            {messages.length === 0 && (
              <div className="flex flex-col items-center justify-center h-full text-gray-500 space-y-6 max-w-2xl mx-auto text-center">
                <div className="w-24 h-24 bg-linear-to-tr from-indigo-100 to-purple-100 rounded-full flex items-center justify-center mb-4 shadow-inner">
                  <span className="text-5xl">👋</span>
                </div>
                <h3 className="font-bold text-gray-800 text-2xl">Xin chào {user?.fullName || 'bạn'}!</h3>
                <p className="text-base text-gray-600">
                  Tôi là trợ lý AI chuyên nghiệp dành cho bộ phận Quản lý. Tôi có thể truy xuất báo cáo doanh thu, tình trạng đơn hàng, và phân tích hiệu suất kinh doanh hoàn toàn tự động.
                </p>
                <div className="flex gap-3 flex-wrap justify-center mt-6">
                  <button
                    type="button"
                    className="bg-white border border-gray-200 px-4 py-2 rounded-xl text-sm font-medium shadow-sm hover:border-indigo-400 hover:text-indigo-600 transition-colors"
                    onClick={() => handleSend('Cho tôi xem báo cáo doanh thu tổng quan')}
                  >
                    📊 Báo cáo doanh thu
                  </button>
                  <button
                    type="button"
                    className="bg-white border border-gray-200 px-4 py-2 rounded-xl text-sm font-medium shadow-sm hover:border-indigo-400 hover:text-indigo-600 transition-colors"
                    onClick={() => handleSend('Sản phẩm nào đang bán chạy nhất?')}
                  >
                    🏆 Sản phẩm bán chạy
                  </button>
                </div>
              </div>
            )}

            {messages.map((msg) => (
              <div key={msg.id} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                <div
                  className={`max-w-[75%] p-5 rounded-3xl text-sm shadow-sm ${
                    msg.role === 'user'
                      ? 'bg-linear-to-r from-blue-600 to-indigo-600 text-white rounded-br-none'
                      : 'bg-white border border-gray-200 text-gray-800 rounded-bl-none'
                  }`}
                >
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
                  <span className="w-2.5 h-2.5 bg-purple-600 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }} />
                  <span className="w-2.5 h-2.5 bg-pink-600 rounded-full animate-bounce" style={{ animationDelay: '0.4s' }} />
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>

          <aside className="hidden xl:flex xl:w-90 flex-col border-l border-gray-200 bg-slate-50">
            <div className="p-6 flex-1 flex flex-col gap-4 overflow-hidden">
              <div className="space-y-2">
                <div className="text-xs font-semibold uppercase tracking-[0.24em] text-slate-500">Lịch sử hội thoại</div>
                <h3 className="text-lg font-semibold text-slate-900">Cuộc trò chuyện trước đó</h3>
                <p className="text-sm text-slate-600">Lưu giữ lại hội thoại với AI và xoá mềm để có thể khôi phục sau này.</p>
              </div>

              <div className="rounded-3xl border border-slate-200 bg-white p-4 overflow-y-auto flex-1 space-y-4">
                {visibleConversations.length === 0 ? (
                  <div className="rounded-3xl bg-slate-50 p-4 text-sm text-slate-500">Chưa có cuộc trò chuyện nào.</div>
                ) : (
                  visibleConversations.map((conversation) => (
                    <button
                      type="button"
                      key={conversation.id}
                      onClick={() => handleSelectConversation(conversation.id)}
                      className={`block w-full text-left rounded-3xl border px-4 py-3 transition ${conversation.id === activeConversationId ? 'border-indigo-300 bg-indigo-50 shadow-sm' : 'border-slate-200 bg-white hover:border-slate-300 hover:bg-slate-50'}`}
                    >
                      <div className="flex items-center justify-between gap-2">
                        <span className="text-sm font-semibold text-slate-900">{conversation.title}</span>
                        <span className="text-[11px] text-slate-500">{new Date(conversation.updatedAt).toLocaleTimeString('vi-VN')}</span>
                      </div>
                      <div className="mt-2 flex items-center justify-between gap-2 text-xs text-slate-500">
                        <span>{new Date(conversation.createdAt).toLocaleDateString('vi-VN')}</span>
                        <button
                          type="button"
                          onClick={(event) => {
                            event.stopPropagation();
                            handleSoftDeleteConversation(conversation.id);
                          }}
                          className="rounded-full border border-rose-200 bg-rose-50 px-2 py-1 text-rose-700 transition hover:bg-rose-100"
                        >
                          Xoá
                        </button>
                      </div>
                    </button>
                  ))
                )}
              </div>

              {showDeleted && (
                <div className="rounded-3xl border border-slate-200 bg-white p-4 space-y-3">
                  <div className="flex items-center justify-between gap-3 text-sm font-semibold text-slate-900">
                    <span>Đã xoá</span>
                    <span className="text-xs text-slate-500">{deletedConversations.length} mục</span>
                  </div>
                  {deletedConversations.length === 0 ? (
                    <div className="rounded-3xl bg-slate-50 p-3 text-sm text-slate-500">Không có cuộc trò chuyện đã xoá.</div>
                  ) : (
                    deletedConversations.map((conversation) => (
                      <div key={conversation.id} className="rounded-3xl border border-slate-200 bg-slate-50 p-3">
                        <div className="text-sm font-semibold text-slate-900">{conversation.title}</div>
                        <div className="mt-1 flex items-center justify-between gap-2 text-xs text-slate-500">
                          <span>{new Date(conversation.updatedAt).toLocaleDateString('vi-VN')}</span>
                          <button
                            type="button"
                            onClick={() => handleRestoreConversation(conversation.id)}
                            className="rounded-full border border-slate-200 bg-white px-2 py-1 text-slate-700 transition hover:bg-slate-100"
                          >
                            Khôi phục
                          </button>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              )}
            </div>
          </aside>
        </div>

        <div className="bg-white border-t border-gray-200 p-4">
          <PromptInputBox onSend={handleSend} disabled={loading} placeholder="Nhập yêu cầu phân tích dữ liệu hoặc hỏi đáp nghiệp vụ..." />
        </div>
      </div>
    </div>
  );
};
