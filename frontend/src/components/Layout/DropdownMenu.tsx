
import React, { useState, useEffect, useRef } from "react";
import type { ReactNode } from "react";

interface DropdownMenuProps {
  children: ReactNode;
  trigger: ReactNode;
}

export const DropdownMenu = ({ children, trigger }: DropdownMenuProps) => {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (
        dropdownRef.current &&
        !dropdownRef.current.contains(event.target as Node)
      ) {
        setIsOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, []);

  const handleTriggerClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    setIsOpen(!isOpen);
  };

  return (
    <div className="relative inline-block text-left" ref={dropdownRef}>
      <div onClick={handleTriggerClick} className="cursor-pointer">
        {trigger}
      </div>
      {isOpen && (
        <div
          className="origin-top-right absolute right-0 mt-2 w-64 rounded-2xl shadow-xl bg-white dark:bg-zinc-900 ring-1 ring-black ring-opacity-5 focus:outline-none z-50 p-2"
          role="menu"
          aria-orientation="vertical"
        >
          {children}
        </div>
      )}
    </div>
  );
};

interface DropdownMenuItemProps {
  children: ReactNode;
  onClick?: () => void;
  active?: boolean;
  danger?: boolean;
}

export const DropdownMenuItem = ({
  children,
  onClick,
  active = false,
  danger = false,
}: DropdownMenuItemProps) => (
  <button
    onClick={(e: React.MouseEvent) => {
      e.preventDefault();
      if (onClick) onClick();
    }}
    className={`
      w-full text-left font-medium group flex items-center 
      px-3 py-2.5 text-sm rounded-lg transition-colors duration-150
      ${
        active
          ? "bg-zinc-100 dark:bg-zinc-800"
          : danger
          ? "text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20"
          : "text-zinc-800 dark:text-zinc-200 hover:bg-zinc-100 dark:hover:bg-zinc-800"
      }
    `}
    role="menuitem"
  >
    {children}
  </button>
);

export const DropdownMenuSeparator = () => (
  <div className="my-2 h-px bg-zinc-200 dark:bg-zinc-700" />
);

export const DropdownMenuLabel = ({ children }: { children: ReactNode }) => (
  <div className="px-3 py-2 text-sm font-semibold text-zinc-900 dark:text-zinc-100">
    {children}
  </div>
);
