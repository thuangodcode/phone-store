import React from 'react';

interface ActionButtonProps {
  label: string;
  onClick: () => void;
  icon: React.ReactNode;
  variant?: 'primary' | 'danger' | 'secondary';
  disabled?: boolean;
}

const variantClasses: Record<NonNullable<ActionButtonProps['variant']>, string> = {
  primary: 'bg-blue-600 text-white hover:bg-blue-700',
  danger: 'bg-red-600 text-white hover:bg-red-700',
  secondary: 'bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-zinc-800 dark:text-zinc-100 dark:hover:bg-zinc-700',
};

export const ActionButton: React.FC<ActionButtonProps> = ({
  label,
  onClick,
  icon,
  variant = 'secondary',
  disabled = false,
}) => (
  <button
    type="button"
    onClick={onClick}
    disabled={disabled}
    className={`inline-flex items-center gap-2 rounded-full px-3 py-1.5 text-sm font-semibold transition duration-150 shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-1 ${variantClasses[variant]} ${disabled ? 'cursor-not-allowed opacity-50' : 'cursor-pointer'}`}
  >
    {icon}
    <span>{label}</span>
  </button>
);

export const EditIcon = () => (
  <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M12 20h9" />
    <path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19.5 3 21l1.5-4L16.5 3.5z" />
  </svg>
);

export const TrashIcon = () => (
  <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <polyline points="3 6 5 6 21 6" />
    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
    <line x1="10" y1="11" x2="10" y2="17" />
    <line x1="14" y1="11" x2="14" y2="17" />
  </svg>
);

export const RefreshIcon = () => (
  <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M23 4v6h-6" />
    <path d="M1 20v-6h6" />
    <path d="M3.51 9a9 9 0 0 1 14.13-3.36L23 10" />
    <path d="M20.49 15a9 9 0 0 1-14.13 3.36L1 14" />
  </svg>
);

export const InfoIcon = () => (
  <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="12" cy="12" r="10" />
    <line x1="12" y1="16" x2="12" y2="12" />
    <line x1="12" y1="8" x2="12.01" y2="8" />
  </svg>
);
