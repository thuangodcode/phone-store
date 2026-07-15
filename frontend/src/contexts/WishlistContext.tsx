import React, { createContext, useContext, useEffect, useState } from 'react';
import { useAuth } from './AuthContext';
import { wishlistApi } from '../api/wishlistApi';

interface WishlistContextType {
  wishlistProductIds: string[];
  addToWishlist: (productId: string) => Promise<void>;
  removeFromWishlist: (productId: string) => Promise<void>;
  isWishlisted: (productId: string) => boolean;
}

const WishlistContext = createContext<WishlistContextType | undefined>(undefined);

export const WishlistProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated, isInitialized } = useAuth();
  
  const [wishlistProductIds, setWishlistProductIds] = useState<string[]>(() => {
    if (typeof window === 'undefined') return [];
    const localData = localStorage.getItem('guest_wishlist');
    if (localData) {
      try {
        return JSON.parse(localData);
      } catch (e) {
        return [];
      }
    }
    return [];
  });

  useEffect(() => {
    if (isInitialized && isAuthenticated) {
      // Fetch from API
      const fetchApiWishlist = async () => {
        try {
          const data: any = await wishlistApi.getWishlist();
          if (data && data.items) {
            setWishlistProductIds(data.items.map((item: any) => item.productId));
          } else {
            setWishlistProductIds([]);
          }
        } catch (error) {
          console.error("Failed to load wishlist from server", error);
        }
      };
      fetchApiWishlist();
    } else if (isInitialized && !isAuthenticated) {
      // Not authenticated, fallback to local storage
      const localData = localStorage.getItem('guest_wishlist');
      if (localData) {
        try {
          setWishlistProductIds(JSON.parse(localData));
        } catch (e) {}
      } else {
        setWishlistProductIds([]);
      }
    }
  }, [isAuthenticated, isInitialized]);

  const saveGuestWishlist = (ids: string[]) => {
    localStorage.setItem('guest_wishlist', JSON.stringify(ids));
  };

  const addToWishlist = async (productId: string) => {
    if (!wishlistProductIds.includes(productId)) {
      const newIds = [...wishlistProductIds, productId];
      setWishlistProductIds(newIds);
      
      if (isAuthenticated) {
        try {
          await wishlistApi.addToWishlist(productId);
        } catch (error) {
          console.error("Failed to add to server wishlist", error);
          // Rollback if failed
          setWishlistProductIds(wishlistProductIds);
        }
      } else {
        saveGuestWishlist(newIds);
      }
    }
  };

  const removeFromWishlist = async (productId: string) => {
    if (wishlistProductIds.includes(productId)) {
      const newIds = wishlistProductIds.filter(id => id !== productId);
      setWishlistProductIds(newIds);
      
      if (isAuthenticated) {
        try {
          await wishlistApi.removeFromWishlist(productId);
        } catch (error) {
          console.error("Failed to remove from server wishlist", error);
          // Rollback if failed
          setWishlistProductIds(wishlistProductIds);
        }
      } else {
        saveGuestWishlist(newIds);
      }
    }
  };

  const isWishlisted = (productId: string) => {
    return wishlistProductIds.includes(productId);
  };

  return (
    <WishlistContext.Provider value={{ wishlistProductIds, addToWishlist, removeFromWishlist, isWishlisted }}>
      {children}
    </WishlistContext.Provider>
  );
};

export const useWishlist = () => {
  const context = useContext(WishlistContext);
  if (context === undefined) {
    throw new Error('useWishlist must be used within a WishlistProvider');
  }
  return context;
};
