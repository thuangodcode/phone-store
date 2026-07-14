import React from 'react';

interface LoadingSpinnerProps {
  className?: string;
  fullScreen?: boolean;
}

export const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({ className = 'w-8 h-8', fullScreen = false }) => {
  const spinner = (
    <svg 
      className={`text-zinc-900 animate-spin ${className}`} 
      viewBox="0 0 24 24" 
      fill="currentColor"
    >
      <rect x="11" y="1" width="2" height="5" opacity="1"/>
      <rect x="11" y="1" width="2" height="5" transform="rotate(30 12 12)" opacity="0.9"/>
      <rect x="11" y="1" width="2" height="5" transform="rotate(60 12 12)" opacity="0.8"/>
      <rect x="11" y="1" width="2" height="5" transform="rotate(90 12 12)" opacity="0.7"/>
      <rect x="11" y="1" width="2" height="5" transform="rotate(120 12 12)" opacity="0.6"/>
      <rect x="11" y="1" width="2" height="5" transform="rotate(150 12 12)" opacity="0.5"/>
      <rect x="11" y="1" width="2" height="5" transform="rotate(180 12 12)" opacity="0.4"/>
      <rect x="11" y="1" width="2" height="5" transform="rotate(210 12 12)" opacity="0.3"/>
      <rect x="11" y="1" width="2" height="5" transform="rotate(240 12 12)" opacity="0.2"/>
      <rect x="11" y="1" width="2" height="5" transform="rotate(270 12 12)" opacity="0.1"/>
      <rect x="11" y="1" width="2" height="5" transform="rotate(300 12 12)" opacity="0.05"/>
      <rect x="11" y="1" width="2" height="5" transform="rotate(330 12 12)" opacity="0.02"/>
    </svg>
  );

  if (fullScreen) {
    return (
      <div className="flex justify-center items-center w-full min-h-screen bg-gray-50/50">
        {spinner}
      </div>
    );
  }

  return (
    <div className="flex justify-center items-center w-full p-8">
      {spinner}
    </div>
  );
};
