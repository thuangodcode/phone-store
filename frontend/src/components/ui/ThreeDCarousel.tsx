'use client';
import React, { useMemo, useRef, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';

/* 1️⃣  Assets ————————————————————————— */
const FALLBACK =
  'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" ' +
  'width="160" height="220"><rect width="100%" height="100%" ' +
  'fill="%23e2e8f0"/><text x="50%" y="50%" dominant-baseline="middle"' +
  ' text-anchor="middle" fill="%234a5568" font-size="18">Image</text></svg>';

const DEFAULT_PRODUCTS = [
  { id: '1', name: 'iPhone 15 Pro', image: 'https://i.pinimg.com/736x/9f/09/45/9f0945103fc6158cb16e1828a2665b5c.jpg', price: 25000000 },
  { id: '2', name: 'Samsung Galaxy S24', image: 'https://i.pinimg.com/1200x/6e/4c/39/6e4c394783c731f261f295e7ffd1deed.jpg', price: 23000000 },
];

/* 2️⃣  Config ————————————————————————— */
const CARD_W = 240;
const CARD_H = 320;
const RADIUS = 320;
const TILT_SENSITIVITY = 10;
const DRAG_SENSITIVITY = 0.5;
const INERTIA_FRICTION = 0.95;
const AUTOSPIN_SPEED = 0.08;
const IDLE_TIMEOUT = 2000;

/* 3️⃣  Card Component (Memoized for Performance) ——— */
export interface CarouselProduct {
  id: string;
  name: string;
  image: string;
  price: number;
}

interface CardProps {
  product: CarouselProduct;
  transform: string;
  cardW: number;
  cardH: number;
  onClick: (id: string) => void;
}

const Card = React.memo(({ product, transform, cardW, cardH, onClick }: CardProps) => (
  <div
    className="absolute cursor-pointer"
    style={{
      width: cardW,
      height: cardH,
      transform,
      transformStyle: 'preserve-3d',
      willChange: 'transform',
    }}
    onClick={() => onClick(product.id)}
  >
    <div
      className="w-full h-full rounded-2xl overflow-hidden bg-white
                 border border-white/20 shadow-[0_0_15px_rgba(255,255,255,0.05)]
                 transition-all duration-300 hover:scale-105 hover:shadow-[0_0_30px_rgba(255,255,255,0.2)]
                 hover:z-10 group relative flex flex-col"
      style={{ backfaceVisibility: 'hidden' }}
    >
      <div className="flex-1 w-full h-full p-4 flex items-center justify-center bg-white">
        <img
          src={product.image}
          alt={product.name}
          className="w-full h-full object-contain transition-transform duration-700 group-hover:scale-110"
          style={{ mixBlendMode: 'multiply' }}
          loading="lazy"
          draggable="false"
          onError={e => {
            e.currentTarget.src = FALLBACK;
          }}
        />
      </div>
      {/* Premium Gradient Overlay for Product Info */}
      <div className="absolute bottom-0 left-0 right-0 p-4 pt-12 bg-gradient-to-t from-gray-900 via-gray-900/80 to-transparent">
        <h3 className="text-white font-bold text-[15px] leading-tight line-clamp-2 mb-1">{product.name}</h3>
        <p className="text-blue-400 font-bold text-sm">{product.price.toLocaleString('vi-VN')} đ</p>
      </div>
    </div>
  </div>
));

Card.displayName = 'Card';

/* 4️⃣  Main component —————————————————— */
interface ThreeDCarouselProps {
  products?: CarouselProduct[];
  radius?: number;
  cardW?: number;
  cardH?: number;
}

const ThreeDCarousel = React.memo(
  ({
    products = DEFAULT_PRODUCTS,
    radius = RADIUS,
    cardW = CARD_W,
    cardH = CARD_H,
  }: ThreeDCarouselProps) => {
    const parentRef = useRef<HTMLDivElement>(null);
    const wheelRef = useRef<HTMLDivElement>(null);

    const rotationRef = useRef(0);
    const tiltRef = useRef(0);
    const targetTiltRef = useRef(0);
    const velocityRef = useRef(0);
    const isDraggingRef = useRef(false);
    const dragStartRef = useRef(0);
    const dragDistanceRef = useRef(0);
    const initialRotationRef = useRef(0);
    const lastInteractionRef = useRef(Date.now());
    const animationFrameRef = useRef<number | null>(null);
    const navigate = useNavigate();

    useEffect(() => {
      const handleMouseMove = (e: MouseEvent) => {
        if (!parentRef.current || isDraggingRef.current) return;

        lastInteractionRef.current = Date.now();
        const parentRect = parentRef.current.getBoundingClientRect();
        const mouseY = e.clientY - parentRect.top;
        const normalizedY = (mouseY / parentRect.height - 0.5) * 2;

        targetTiltRef.current = -normalizedY * TILT_SENSITIVITY;
      };

      window.addEventListener('mousemove', handleMouseMove);

      return () => {
        window.removeEventListener('mousemove', handleMouseMove);
      };
    }, []);

    useEffect(() => {
      const animate = () => {
        if (!isDraggingRef.current) {
          // Apply inertia
          if (Math.abs(velocityRef.current) > 0.01) {
            rotationRef.current += velocityRef.current;
            velocityRef.current *= INERTIA_FRICTION;
          } else if (Date.now() - lastInteractionRef.current > IDLE_TIMEOUT) {
            rotationRef.current += AUTOSPIN_SPEED;
          }
        }

        tiltRef.current += (targetTiltRef.current - tiltRef.current) * 0.1;

        if (wheelRef.current) {
          wheelRef.current.style.transform = `rotateX(${tiltRef.current}deg) rotateY(${rotationRef.current}deg)`;
        }

        animationFrameRef.current = requestAnimationFrame(animate);
      };

      animationFrameRef.current = requestAnimationFrame(animate);

      return () => {
        if (animationFrameRef.current) {
          cancelAnimationFrame(animationFrameRef.current);
        }
      };
    }, []);

    const handleDragStart = useCallback((clientX: number) => {
      lastInteractionRef.current = Date.now();
      isDraggingRef.current = true;
      velocityRef.current = 0;
      dragStartRef.current = clientX;
      dragDistanceRef.current = 0;
      initialRotationRef.current = rotationRef.current;
    }, []);

    const handleDragMove = useCallback((clientX: number) => {
      if (!isDraggingRef.current) return;
      lastInteractionRef.current = Date.now();

      const deltaX = clientX - dragStartRef.current;
      dragDistanceRef.current = Math.abs(deltaX);
      const newRotation = initialRotationRef.current + deltaX * DRAG_SENSITIVITY;

      velocityRef.current = newRotation - rotationRef.current;
      rotationRef.current = newRotation;
    }, []);

    // Handle drag end
    const handleDragEnd = useCallback(() => {
      isDraggingRef.current = false;
      lastInteractionRef.current = Date.now();
    }, []);

    // Event listeners for mouse and touch
    const onMouseDown = (e: React.MouseEvent) => handleDragStart(e.clientX);
    const onMouseMove = (e: React.MouseEvent) => handleDragMove(e.clientX);
    const onTouchStart = (e: React.TouchEvent) => handleDragStart(e.touches[0].clientX);
    const onTouchMove = (e: React.TouchEvent) => handleDragMove(e.touches[0].clientX);

    const handleCardClick = useCallback((id: string) => {
      if (dragDistanceRef.current < 5) {
        navigate(`/products/${id}`);
      }
    }, [navigate]);

    /* Pre-compute card transforms (only re-computes if products/radius change) */
    const cards = useMemo(
      () =>
        products.map((product, idx) => {
          const angle = (idx * 360) / products.length;
          return {
            key: idx,
            product,
            transform: `rotateY(${angle}deg) translateZ(${radius}px)`,
          };
        }),
      [products, radius]
    );

    return (
      <div
        ref={parentRef}
        className="w-full h-full flex items-center justify-center overflow-hidden font-sans cursor-grab active:cursor-grabbing"
        style={{ userSelect: 'none' }}
        onMouseDown={onMouseDown}
        onMouseMove={onMouseMove}
        onMouseUp={handleDragEnd}
        onMouseLeave={handleDragEnd}
        onTouchStart={onTouchStart}
        onTouchMove={onTouchMove}
        onTouchEnd={handleDragEnd}
      >
        <div
          className="relative"
          style={{
            perspective: 1500,
            perspectiveOrigin: 'center',
            width: Math.max(cardW * 1.5, radius * 2.2),
            height: Math.max(cardH * 1.8, radius * 1.5),
          }}
        >
          <div
            ref={wheelRef}
            className="relative"
            style={{
              width: cardW,
              height: cardH,
              transformStyle: 'preserve-3d',
              willChange: 'transform',
              position: 'absolute',
              left: '50%',
              top: '50%',
              marginLeft: -cardW / 2,
              marginTop: -cardH / 2,
            }}
          >
            {cards.map(card => (
              <Card
                key={card.key}
                product={card.product}
                transform={card.transform}
                cardW={cardW}
                cardH={cardH}
                onClick={handleCardClick}
              />
            ))}
          </div>
        </div>
      </div>
    );
  }
);

ThreeDCarousel.displayName = 'ThreeDCarousel';

export default ThreeDCarousel;
