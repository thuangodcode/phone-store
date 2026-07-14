import React from 'react';

export const Footer: React.FC = () => {
  return (
    <footer className="bg-gray-900 text-gray-300 py-12">
      <div className="container mx-auto px-4 grid grid-cols-1 md:grid-cols-4 gap-8">
        <div>
          <h3 className="text-white text-xl font-bold mb-4">PhoneStore</h3>
          <p className="text-sm">Your one-stop destination for the latest and greatest smartphones.</p>
        </div>
        <div>
          <h4 className="text-white font-semibold mb-4">Quick Links</h4>
          <ul className="space-y-2 text-sm">
            <li><a href="#" className="hover:text-white">About Us</a></li>
            <li><a href="#" className="hover:text-white">Contact</a></li>
            <li><a href="#" className="hover:text-white">FAQ</a></li>
          </ul>
        </div>
        <div>
          <h4 className="text-white font-semibold mb-4">Policies</h4>
          <ul className="space-y-2 text-sm">
            <li><a href="#" className="hover:text-white">Privacy Policy</a></li>
            <li><a href="#" className="hover:text-white">Terms of Service</a></li>
            <li><a href="#" className="hover:text-white">Return Policy</a></li>
          </ul>
        </div>
        <div>
          <h4 className="text-white font-semibold mb-4">Newsletter</h4>
          <div className="flex">
            <input type="email" placeholder="Your email" className="px-3 py-2 bg-gray-800 text-white w-full rounded-l-md focus:outline-none" />
            <button className="bg-primary-600 text-white px-4 py-2 rounded-r-md hover:bg-primary-700">Subscribe</button>
          </div>
        </div>
      </div>
      <div className="container mx-auto px-4 mt-8 pt-8 border-t border-gray-800 text-sm text-center">
        &copy; {new Date().getFullYear()} PhoneStore. All rights reserved.
      </div>
    </footer>
  );
};
