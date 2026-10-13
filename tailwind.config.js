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
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
        },
        accent: {
          400: '#a78bfa',
          500: '#8b5cf6',
          600: '#7c3aed',
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
        // ===== ScamWatch theme palette (trust-blue + traffic-light risk) =====
        // Driven by CSS variables so the whole forum flips with light/dark
        // mode. Values are defined in index.css (:root and .dark). The
        // `<alpha-value>` placeholder keeps opacity utilities (e.g.
        // bg-scam-800/50) working.
        scam: {
          950: 'rgb(var(--scam-950) / <alpha-value>)',
          900: 'rgb(var(--scam-900) / <alpha-value>)',
          850: 'rgb(var(--scam-850) / <alpha-value>)',
          800: 'rgb(var(--scam-800) / <alpha-value>)',
          750: 'rgb(var(--scam-750) / <alpha-value>)',
          line: 'rgb(var(--scam-line) / <alpha-value>)',
          text: 'rgb(var(--scam-text) / <alpha-value>)',
          muted: 'rgb(var(--scam-muted) / <alpha-value>)',
          dim: 'rgb(var(--scam-dim) / <alpha-value>)',
        },
        // Primary accent — trust blue (institutional, secure).
        trust: {
          50: '#eff6ff',
          100: '#dbeafe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
        },
        // Brand mint kept for optional accents; no longer the primary.
        mint: {
          50: '#e9fdf5',
          100: '#c9f9e6',
          300: '#5eeac0',
          400: '#2ee6a6',
          500: '#22d3a0',
          600: '#15b386',
          700: '#0f8c69',
        },
        // Strict traffic-light risk system (red -> amber -> green), + violet PSA.
        'risk-high': '#ef4444', // High / Confirmed
        'risk-med': '#f59e0b', // Medium / Under review
        'risk-low': '#22c55e', // Low / Debunked / Safe (green reserved for "safe")
        'risk-psa': '#8b5cf6', // PSA / Official alert
        // "Safe / verified" — the trust primary
        // "safe" is the app's PRIMARY ACCENT. Per the design direction it is
        // now TRUST BLUE (institutional, secure) rather than green — green is
        // reserved for the "verified safe / debunked" risk tag only.
        safe: {
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
        },
        // True green — reserved strictly for "verified safe / debunked".
        verified: {
          50: '#f0fdf4',
          100: '#dcfce7',
          400: '#4ade80',
          500: '#22c55e',
          600: '#16a34a',
          700: '#15803d',
        },
        // "Caution / flagged" — amber (traffic-light middle)
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
        soft: '0 4px 24px -8px rgba(59, 130, 246, 0.18)',
        glow: '0 0 0 1px rgba(59,130,246,0.1), 0 8px 32px -8px rgba(59,130,246,0.3)',
        // IA: crisp, low, structural — not floaty
        ia: '0 1px 0 0 rgba(18,22,27,0.04), 0 1px 3px 0 rgba(18,22,27,0.08)',
        // Soft lift for report cards (flat-modern, not heavy)
        card: '0 1px 2px 0 rgba(0,0,0,0.3)',
        'card-hover': '0 4px 16px -4px rgba(0,0,0,0.45)',
      },
      backgroundImage: {
        'brand-gradient':
          'linear-gradient(135deg, #3b82f6 0%, #6366f1 50%, #8b5cf6 100%)',
        'mesh-light':
          'radial-gradient(at 20% 20%, rgba(59,130,246,0.14) 0px, transparent 50%), radial-gradient(at 80% 0%, rgba(139,92,246,0.10) 0px, transparent 50%), radial-gradient(at 0% 80%, rgba(99,102,241,0.10) 0px, transparent 50%)',
        'mesh-dark':
          'radial-gradient(at 20% 20%, rgba(59,130,246,0.20) 0px, transparent 50%), radial-gradient(at 80% 0%, rgba(139,92,246,0.14) 0px, transparent 50%), radial-gradient(at 0% 80%, rgba(99,102,241,0.15) 0px, transparent 50%)',
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
        'pulse-dot': {
          '0%, 100%': { opacity: '1', transform: 'scale(1)' },
          '50%': { opacity: '0.4', transform: 'scale(0.85)' },
        },
      },
      animation: {
        'fade-up': 'fade-up 0.5s ease-out both',
        float: 'float 6s ease-in-out infinite',
        'gradient-x': 'gradient-x 6s ease infinite',
        'pulse-dot': 'pulse-dot 1.6s ease-in-out infinite',
      },
    },
  },
  plugins: [],
};
