
import { useState, useEffect, useRef } from 'react';
import { ChevronDown } from "lucide-react";

interface Option {
  value: string;
  label: string;
}

interface CustomSelectProps {
  options: Option[];
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
}

export const CustomSelect = ({
  options,
  value,
  onChange,
  placeholder = "Chọn..."
}: CustomSelectProps) => {
  const [isOpen, setIsOpen] = useState(false);
  const selectRef = useRef<HTMLDivElement>(null);

  const selectedOption = options.find(opt => opt.value === value);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (selectRef.current && !selectRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  return (
    <div className="relative" ref={selectRef}>
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center justify-between w-full px-4 py-2 text-sm font-semibold text-zinc-800 bg-white border border-zinc-200 rounded-lg shadow-sm hover:bg-zinc-50 transition-colors"
      >
        <span>{selectedOption?.label || placeholder}</span>
        <ChevronDown size={16} className={`transition-transform ${isOpen ? "rotate-180" : ""}`} />
      </button>
      {isOpen && (
        <div className="origin-top-left absolute left-0 mt-2 w-full rounded-2xl shadow-xl bg-white ring-1 ring-black ring-opacity-5 focus:outline-none z-50 p-2">
          <div className="flex flex-col space-y-1">
            {options.map(opt => (
              <button
                key={opt.value}
                onClick={() => {
                  onChange(opt.value);
                  setIsOpen(false);
                }}
                className={`text-left font-medium group flex items-center px-3 py-2.5 text-sm rounded-lg transition-colors duration-150 ${
                  opt.value === value
                    ? "bg-zinc-100 text-zinc-900"
                    : "text-zinc-800 hover:bg-zinc-100"
                }`}
              >
                {opt.label}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
