import React from 'react';
import { Outlet } from 'react-router-dom';
import { Header } from './Header';
import { Footer } from './Footer';
import { CustomerChatWidget } from '../Chat/ChatWidget';

export const MainLayout: React.FC = () => {
  return (
    <div className="min-h-screen flex flex-col font-sans bg-gray-50">
      <Header />
      <main className="flex-grow pt-20">
        <Outlet />
      </main>
      <Footer />
      <CustomerChatWidget />
    </div>
  );
};
