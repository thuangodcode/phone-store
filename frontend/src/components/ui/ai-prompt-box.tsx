import React, { useState, useRef, useEffect } from 'react';

interface PromptInputBoxProps {
  onSend: (message: string) => void;
  placeholder?: string;
  disabled?: boolean;
}

export const PromptInputBox: React.FC<PromptInputBoxProps> = ({ 
  onSend, 
  placeholder = "Hỏi tôi bất cứ điều gì...", 
  disabled = false 
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

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  return (
    <div className="relative flex w-full max-w-3xl items-center justify-center p-4">
      <div className="relative flex w-full flex-row items-end overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm focus-within:border-blue-500 focus-within:ring-1 focus-within:ring-blue-500 transition-all dark:border-gray-800 dark:bg-gray-950">
        <textarea
          ref={textareaRef}
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder={placeholder}
          disabled={disabled}
          className="max-h-[120px] w-full resize-none bg-transparent px-4 py-4 text-sm outline-none placeholder:text-gray-400 disabled:opacity-50"
          rows={1}
        />
        <div className="flex h-[52px] items-center justify-center px-2">
          <button
            onClick={handleSend}
            disabled={!input.trim() || disabled}
            className={`flex h-8 w-8 items-center justify-center rounded-lg transition-colors ${
              input.trim() && !disabled
                ? 'bg-blue-600 text-white hover:bg-blue-700'
                : 'bg-gray-100 text-gray-400 dark:bg-gray-800'
            }`}
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <line x1="22" y1="2" x2="11" y2="13" />
              <polygon points="22 2 15 22 11 13 2 9 22 2" />
            </svg>
          </button>
        </div>
      </div>
    </div>
  );
};
