import React, { useEffect, useRef, useState } from 'react';
import {
  Bot,
  CircleAlert,
  MessageCircleMore,
  RefreshCw,
  RotateCcw,
  ShieldCheck,
  Sparkles,
  X,
  Zap,
} from 'lucide-react';
import { MarkdownRenderer } from '../ui/MarkdownRenderer';
import { getAIChatErrorMessage, sendAIChatMessage } from '../../api/aiApi';
import { useAuth } from '../../contexts/AuthContext';
import { PromptInputBox } from '../ui/ai-prompt-box';

interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  isError?: boolean;
}

const createSessionId = () => {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return `web-${crypto.randomUUID()}`;
  }

  return `web-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
};

const quickPrompts = [
  {
    label: 'Chọn máy chơi game',
    prompt: 'Tìm cho tôi điện thoại chơi game tốt nhất',
    icon: Zap,
  },
  {
    label: 'Tư vấn theo ngân sách',
    prompt: 'Tôi có 15 triệu thì nên mua điện thoại gì?',
    icon: Sparkles,
  },
];

export const AIAssistantWidget: React.FC = () => {
  const { user } = useAuth();
  const [isOpen, setIsOpen] = useState(false);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [loading, setLoading] = useState(false);
  const [sessionId, setSessionId] = useState(createSessionId);
  const [lastFailedMessage, setLastFailedMessage] = useState<string | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (isOpen) {
      requestAnimationFrame(() => messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' }));
    }
  }, [isOpen, messages, loading]);

  const sendMessage = async (text: string, includeUserMessage = true) => {
    const message = text.trim();
    if (!message || loading) return;

    if (includeUserMessage) {
      setMessages((current) => [
        ...current,
        { id: `user-${Date.now()}`, role: 'user', content: message },
      ]);
    }

    setLoading(true);
    setLastFailedMessage(null);

    try {
      const response = await sendAIChatMessage(message, sessionId);
      const answer = response.response?.trim();

      if (!answer) {
        throw new Error('EMPTY_AI_RESPONSE');
      }

      setMessages((current) => [
        ...current,
        { id: `assistant-${Date.now()}`, role: 'assistant', content: answer },
      ]);
    } catch (error) {
      console.error('AI chat error:', error);
      setLastFailedMessage(message);
      setMessages((current) => [
        ...current,
        {
          id: `assistant-error-${Date.now()}`,
          role: 'assistant',
          content: getAIChatErrorMessage(error),
          isError: true,
        },
      ]);
    } finally {
      setLoading(false);
    }
  };

  const resetConversation = () => {
    if (loading) return;

    setMessages([]);
    setLastFailedMessage(null);
    setSessionId(createSessionId());
  };

  const firstName = user?.fullName?.trim().split(' ')[0] || 'bạn';

  return (
    <div className="fixed bottom-[5.5rem] right-4 z-[60] max-sm:left-4 sm:right-6">
      {!isOpen && (
        <button
          type="button"
          onClick={() => setIsOpen(true)}
          aria-label="Mở trợ lý AI PhoneStore"
          className="group relative flex h-14 w-14 items-center justify-center rounded-2xl bg-slate-950 text-white shadow-xl shadow-slate-950/25 transition-all duration-300 hover:-translate-y-1 hover:bg-blue-600 hover:shadow-blue-600/30"
        >
          <span className="absolute inset-0 rounded-2xl border border-white/15" />
          <MessageCircleMore size={24} strokeWidth={2.1} />
          <span className="absolute -right-1 -top-1 flex h-4 w-4">
            <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-75" />
            <span className="relative inline-flex h-4 w-4 rounded-full border-2 border-white bg-emerald-400" />
          </span>
          <span className="pointer-events-none absolute right-[calc(100%+0.75rem)] whitespace-nowrap rounded-lg bg-slate-950 px-3 py-2 text-xs font-medium opacity-0 shadow-lg transition-opacity duration-200 group-hover:opacity-100 max-sm:hidden">
            Hỏi PhoneStore AI
          </span>
        </button>
      )}

      {isOpen && (
        <section
          role="dialog"
          aria-label="Trợ lý AI PhoneStore"
          className="flex h-[min(42rem,calc(100dvh-7rem))] w-[calc(100vw-2rem)] flex-col overflow-hidden rounded-[1.5rem] border border-slate-200 bg-white shadow-2xl shadow-slate-950/20 sm:w-[26rem]"
        >
          <header className="relative overflow-hidden bg-gradient-to-br from-slate-950 via-slate-900 to-blue-950 px-5 py-4 text-white">
            <div className="absolute -right-10 -top-16 h-36 w-36 rounded-full bg-blue-400/20 blur-2xl" />
            <div className="absolute -bottom-12 left-16 h-28 w-28 rounded-full bg-cyan-300/10 blur-2xl" />
            <div className="relative flex items-center justify-between">
              <div className="flex min-w-0 items-center gap-3">
                <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl border border-white/15 bg-white/10 shadow-inner shadow-white/10">
                  <Bot size={23} strokeWidth={2.1} />
                </div>
                <div className="min-w-0">
                  <div className="flex items-center gap-2">
                    <h3 className="truncate text-sm font-bold tracking-wide">PhoneStore AI</h3>
                    <span className="rounded-full border border-emerald-300/20 bg-emerald-400/10 px-1.5 py-0.5 text-[10px] font-semibold text-emerald-200">
                      BETA
                    </span>
                  </div>
                  <p className="mt-0.5 flex items-center gap-1.5 text-xs text-slate-300">
                    <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
                    Tư vấn sản phẩm thông minh
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-1">
                <button
                  type="button"
                  onClick={resetConversation}
                  disabled={loading || messages.length === 0}
                  aria-label="Bắt đầu cuộc trò chuyện mới"
                  title="Bắt đầu cuộc trò chuyện mới"
                  className="rounded-xl p-2 text-slate-300 transition-colors hover:bg-white/10 hover:text-white disabled:cursor-not-allowed disabled:opacity-35"
                >
                  <RotateCcw size={17} />
                </button>
                <button
                  type="button"
                  onClick={() => setIsOpen(false)}
                  aria-label="Đóng trợ lý AI"
                  className="rounded-xl p-2 text-slate-300 transition-colors hover:bg-white/10 hover:text-white"
                >
                  <X size={19} />
                </button>
              </div>
            </div>
          </header>

          <div className="relative flex-1 overflow-y-auto bg-slate-50 px-4 py-5">
            <div className="pointer-events-none absolute inset-x-0 top-0 h-28 bg-gradient-to-b from-blue-50/70 to-transparent" />
            <div className="relative flex min-h-full flex-col gap-4">
              {messages.length === 0 && (
                <div className="my-auto py-4">
                  <div className="mx-auto flex max-w-sm flex-col items-center text-center">
                    <div className="relative mb-5 flex h-16 w-16 items-center justify-center rounded-3xl bg-gradient-to-br from-blue-600 to-cyan-500 text-white shadow-lg shadow-blue-500/20">
                      <Sparkles size={28} />
                      <span className="absolute -bottom-1 -right-1 h-5 w-5 rounded-full border-4 border-slate-50 bg-emerald-400" />
                    </div>
                    <p className="text-base font-bold text-slate-900">Chào {firstName}, mình có thể giúp gì?</p>
                    <p className="mt-2 text-sm leading-6 text-slate-500">
                      Hỏi về sản phẩm, cấu hình, mức giá hoặc nhu cầu sử dụng của bạn.
                    </p>
                    <div className="mt-6 grid w-full gap-2">
                      {quickPrompts.map(({ label, prompt, icon: Icon }) => (
                        <button
                          key={label}
                          type="button"
                          onClick={() => sendMessage(prompt)}
                          disabled={loading}
                          className="group flex items-center gap-3 rounded-2xl border border-slate-200 bg-white px-3.5 py-3 text-left shadow-sm transition-all hover:-translate-y-0.5 hover:border-blue-200 hover:shadow-md disabled:cursor-not-allowed disabled:opacity-60"
                        >
                          <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl bg-blue-50 text-blue-600 transition-colors group-hover:bg-blue-600 group-hover:text-white">
                            <Icon size={16} />
                          </span>
                          <span className="text-xs font-semibold text-slate-700">{label}</span>
                        </button>
                      ))}
                    </div>
                  </div>
                </div>
              )}

              {messages.map((message) => (
                <div
                  key={message.id}
                  className={`flex items-end gap-2 ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
                >
                  {message.role === 'assistant' && (
                    <div className={`mb-1 flex h-7 w-7 shrink-0 items-center justify-center rounded-xl ${message.isError ? 'bg-rose-100 text-rose-600' : 'bg-slate-900 text-white'}`}>
                      {message.isError ? <CircleAlert size={15} /> : <Bot size={15} />}
                    </div>
                  )}
                  <div
                    className={`max-w-[82%] rounded-2xl px-3.5 py-3 text-[13px] leading-6 shadow-sm ${
                      message.role === 'user'
                        ? 'rounded-br-md bg-slate-950 text-white shadow-slate-950/10'
                        : message.isError
                          ? 'rounded-bl-md border border-rose-200 bg-rose-50 text-rose-800'
                          : 'rounded-bl-md border border-slate-200 bg-white text-slate-700'
                    }`}
                  >
                    {message.role === 'assistant' ? (
                      <div className="w-full text-slate-800">
                        <MarkdownRenderer content={message.content} />
                      </div>
                    ) : (
                      <p className="m-0 whitespace-pre-wrap">{message.content}</p>
                    )}
                    {message.isError && lastFailedMessage && !loading && (
                      <button
                        type="button"
                        onClick={() => sendMessage(lastFailedMessage, false)}
                        className="mt-3 inline-flex items-center gap-1.5 rounded-lg border border-rose-200 bg-white px-2.5 py-1.5 text-xs font-semibold text-rose-700 transition-colors hover:bg-rose-100"
                      >
                        <RefreshCw size={13} />
                        Thử lại
                      </button>
                    )}
                  </div>
                </div>
              ))}

              {loading && (
                <div className="flex items-end gap-2">
                  <div className="flex h-7 w-7 items-center justify-center rounded-xl bg-slate-900 text-white">
                    <Bot size={15} />
                  </div>
                  <div className="flex items-center gap-1.5 rounded-2xl rounded-bl-md border border-slate-200 bg-white px-3.5 py-3 shadow-sm">
                    <span className="h-1.5 w-1.5 animate-bounce rounded-full bg-blue-500" />
                    <span className="h-1.5 w-1.5 animate-bounce rounded-full bg-blue-500 [animation-delay:150ms]" />
                    <span className="h-1.5 w-1.5 animate-bounce rounded-full bg-blue-500 [animation-delay:300ms]" />
                    <span className="ml-1 text-xs font-medium text-slate-500">Đang phân tích</span>
                  </div>
                </div>
              )}
              <div ref={messagesEndRef} />
            </div>
          </div>

          <footer className="border-t border-slate-200 bg-white px-4 pb-3 pt-3">
            <PromptInputBox
              onSend={(message) => sendMessage(message)}
              disabled={loading}
              placeholder="Hỏi về điện thoại, giá hoặc cấu hình..."
            />
            <div className="mt-1 flex items-center gap-1.5 px-1 text-[10px] text-slate-400">
              <ShieldCheck size={12} />
              <span>AI có thể mắc lỗi. Hãy kiểm tra thông tin quan trọng trước khi mua.</span>
            </div>
          </footer>
        </section>
      )}
    </div>
  );
};
