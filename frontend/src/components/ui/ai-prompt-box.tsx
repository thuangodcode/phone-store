import React, { useEffect, useRef, useState } from 'react';
import { ArrowUp } from 'lucide-react';

interface PromptInputBoxProps {
  onSend: (message: string) => void;
  placeholder?: string;
  disabled?: boolean;
}

export const PromptInputBox: React.FC<PromptInputBoxProps> = ({
  onSend,
  placeholder = 'Hỏi tôi bất cứ điều gì...',
  disabled = false,
}) => {
  const [input, setInput] = useState('');
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
      textareaRef.current.style.height = `${Math.min(textareaRef.current.scrollHeight, 120)}px`;
    }
  }, [input]);

  const handleSend = () => {
    if (!input.trim() || disabled) return;

    onSend(input.trim());
    setInput('');

    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
    }
  };

  const handleKeyDown = (event: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      handleSend();
    }
  };

  const canSend = input.trim().length > 0 && !disabled;

  return (
    <div className="w-full">
      <div className="flex items-end gap-2 rounded-2xl border border-slate-200 bg-slate-50 p-1.5 shadow-sm transition-all duration-200 focus-within:border-blue-400 focus-within:bg-white focus-within:ring-4 focus-within:ring-blue-500/10">
        <textarea
          ref={textareaRef}
          value={input}
          onChange={(event) => setInput(event.target.value)}
          onKeyDown={handleKeyDown}
          placeholder={placeholder}
          disabled={disabled}
          rows={1}
          className="max-h-[120px] min-h-11 w-full resize-none bg-transparent px-3 py-2.5 text-sm leading-6 text-slate-800 outline-none placeholder:text-slate-400 disabled:cursor-not-allowed disabled:opacity-60"
          aria-label="Tin nhắn cho trợ lý AI"
        />
        <button
          type="button"
          onClick={handleSend}
          disabled={!canSend}
          aria-label="Gửi tin nhắn"
          className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl transition-all duration-200 ${
            canSend
              ? 'bg-slate-950 text-white shadow-md shadow-slate-950/20 hover:-translate-y-0.5 hover:bg-blue-600 active:translate-y-0'
              : 'bg-slate-200 text-slate-400'
          }`}
        >
          <ArrowUp size={18} strokeWidth={2.5} />
        </button>
      </div>
      <div className="mt-2 flex items-center justify-between px-1 text-[11px] text-slate-400">
        <span>Enter để gửi</span>
        <span>Shift + Enter để xuống dòng</span>
      </div>
    </div>
  );
};
