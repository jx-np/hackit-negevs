/** @type {import('tailwindcss').Config} */
export default {
  darkMode: 'class',
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      fontFamily: {
        // Driven by CSS variable so the user can toggle at runtime
        app: 'var(--app-font-family)',
        // IA "security-grade" type system
        display: ["'Space Grotesk'", 'system-ui', 'sans-serif'],
        mono: ['ui-monospace', "'SF Mono'", "'Cascadia Code'", 'Menlo', 'Consolas', 'monospace'],
      },
      fontSize: {
        // Scales relative to the root --app-font-scale variable
        base: 'calc(1rem * var(--app-font-scale))',
      },
      colors: {
        brand: {
          50: '#eef2ff',
          100: '#e0e7ff',
          200: '#c7d2fe',
          300: '#a5b4fc',
          400: '#818cf8',
          500: '#6366f1',
          600: '#4f46e5',
          700: '#4338ca',
          800: '#3730a3',
          900: '#312e81',
        },
        accent: {
          400: '#22d3ee',
          500: '#06b6d4',
          600: '#0891b2',
        },
        // ===== IA "security-grade" semantic tokens =====
        // Ink = near-black text/structure; paper = off-white surface
        ink: {
          50: '#f6f7f8',
          100: '#eceef1',
          200: '#d6dae0',
          300: '#b0b8c1',
          400: '#7c8794',
          500: '#586471',
          600: '#434d58',
          700: '#333b44',
          800: '#20262d',
          900: '#12161b',
          950: '#0a0d10',
        },
        paper: '#faf9f6',
        // "Safe / verified" — the trust primary
        safe: {
          50: '#ecfdf5',
          100: '#d1fae5',
          200: '#a7f3d0',
          400: '#34d399',
          500: '#10b981',
          600: '#059669',
          700: '#047857',
          800: '#065f46',
        },
        // "Caution / flagged" — semantic warning accent
        caution: {
          50: '#fffbeb',
          100: '#fef3c7',
          400: '#fbbf24',
          500: '#f59e0b',
          600: '#d97706',
          700: '#b45309',
        },
        // "High risk" — danger for flagged scams
        risk: {
          50: '#fef2f2',
          100: '#fee2e2',
          500: '#ef4444',
          600: '#dc2626',
          700: '#b91c1c',
        },
      },
      boxShadow: {
        soft: '0 4px 24px -8px rgba(79, 70, 229, 0.15)',
        glow: '0 0 0 1px rgba(99,102,241,0.1), 0 8px 32px -8px rgba(99,102,241,0.3)',
        // IA: crisp, low, structural — not floaty
        ia: '0 1px 0 0 rgba(18,22,27,0.04), 0 1px 3px 0 rgba(18,22,27,0.08)',
      },
      backgroundImage: {
        'brand-gradient':
          'linear-gradient(135deg, #6366f1 0%, #8b5cf6 50%, #06b6d4 100%)',
        'mesh-light':
          'radial-gradient(at 20% 20%, rgba(99,102,241,0.12) 0px, transparent 50%), radial-gradient(at 80% 0%, rgba(6,182,212,0.10) 0px, transparent 50%), radial-gradient(at 0% 80%, rgba(139,92,246,0.10) 0px, transparent 50%)',
        'mesh-dark':
          'radial-gradient(at 20% 20%, rgba(99,102,241,0.18) 0px, transparent 50%), radial-gradient(at 80% 0%, rgba(6,182,212,0.12) 0px, transparent 50%), radial-gradient(at 0% 80%, rgba(139,92,246,0.15) 0px, transparent 50%)',
      },
      keyframes: {
        'fade-up': {
          '0%': { opacity: '0', transform: 'translateY(16px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        float: {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-10px)' },
        },
        'gradient-x': {
          '0%, 100%': { backgroundPosition: '0% 50%' },
          '50%': { backgroundPosition: '100% 50%' },
        },
      },
      animation: {
        'fade-up': 'fade-up 0.5s ease-out both',
        float: 'float 6s ease-in-out infinite',
        'gradient-x': 'gradient-x 6s ease infinite',
      },
    },
  },
  plugins: [],
};
