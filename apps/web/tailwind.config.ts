import type { Config } from 'tailwindcss';

/**
 * Token desain Campus Express — sumber tunggal: `docs/Design.md` §A.1 (warna),
 * §A.2 (tipografi + skala web), §A.3 (spacing/breakpoint), §A.4 (radius),
 * §A.5 (shadow), dan §E.1 (konfigurasi Tailwind acuan).
 *
 * Palet inti: primary `#006C4A`, mint `#8DF3CE` / `#CFF8E8`,
 * background `#F8F9FF`, surface `#FFFFFF`, lavender `#E2E7FF`.
 * Font: Plus Jakarta Sans (heading) + Inter (body) + JetBrains Mono (mono).
 */
const config: Config = {
  content: [
    './app/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
    './lib/**/*.{ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#006C4A',
          pressed: '#00553A',
          bright: '#059669',
          glow: '#10B981',
        },
        mint: { 100: '#CFF8E8', 300: '#8DF3CE', on: '#00553A' },
        // Token `on-primary` / `on-primary-muted` (Design.md §A.1) untuk teks di atas `primary`.
        'on-primary': '#FFFFFF',
        'on-primary-muted': 'rgba(255,255,255,0.78)',
        lav: { 100: '#F1F3FF', 200: '#E9EDFF', 300: '#E2E7FF', 400: '#D5DBF5' },
        bg: '#F8F9FF',
        surface: '#FFFFFF',
        ink: { 50: '#ECFDF5', 800: '#1F2A3C', 900: '#0A2219', 950: '#04130E' },
        text: { strong: '#0F1A2B', body: '#3E4A5A', muted: '#5B6676' },
        danger: { DEFAULT: '#BA1A1A', container: '#FFDAD6' },
        info: { DEFAULT: '#00639B', 100: '#D2EBFF' },
        star: '#F59E0B',
        line: { subtle: '#E3E7F4', divider: '#ECEFFA' },
        // Alias hijau untuk komponen padat kontras (tech.md §6.10).
        emerald: { 500: '#059669', 600: '#047857', 900: '#064E3B' },
      },
      // `border-subtle` / `divide-divider` dipakai langsung pada spesifikasi §B.5.
      borderColor: {
        subtle: '#E3E7F4',
        divider: '#ECEFFA',
        DEFAULT: '#E3E7F4',
      },
      divideColor: {
        subtle: '#E3E7F4',
        divider: '#ECEFFA',
        DEFAULT: '#ECEFFA',
      },
      fontFamily: {
        display: [
          'var(--font-display)',
          '"Plus Jakarta Sans"',
          'Inter',
          'system-ui',
          'sans-serif',
        ],
        sans: ['var(--font-sans)', 'Inter', 'system-ui', 'sans-serif'],
        mono: ['var(--font-mono)', '"JetBrains Mono"', 'ui-monospace', 'monospace'],
      },
      fontSize: {
        display: ['40px', { lineHeight: '48px', letterSpacing: '-0.5px', fontWeight: '800' }],
        h1: ['28px', { lineHeight: '34px', letterSpacing: '-0.3px', fontWeight: '800' }],
        h2: ['22px', { lineHeight: '28px', letterSpacing: '-0.2px', fontWeight: '700' }],
        h3: ['18px', { lineHeight: '24px', letterSpacing: '-0.1px', fontWeight: '700' }],
        h4: ['16px', { lineHeight: '22px', fontWeight: '700' }],
        h5: ['15px', { lineHeight: '20px', fontWeight: '600' }],
        'body-l': ['16px', { lineHeight: '24px' }],
        'body-m': ['14px', { lineHeight: '20px' }],
        'body-s': ['13px', { lineHeight: '18px' }],
        caption: ['12px', { lineHeight: '16px', fontWeight: '500', letterSpacing: '0.1px' }],
        micro: ['11px', { lineHeight: '14px', fontWeight: '700', letterSpacing: '0.4px' }],
        price: ['16px', { lineHeight: '22px', fontWeight: '700' }],
        'price-l': ['20px', { lineHeight: '26px', fontWeight: '800' }],
        pin: ['32px', { lineHeight: '40px', fontWeight: '800' }],
        mono: ['12px', { lineHeight: '16px', fontWeight: '700', letterSpacing: '0.3px' }],
        'web-h1': ['40px', { lineHeight: '48px', letterSpacing: '-0.5px', fontWeight: '800' }],
        'web-h2': ['26px', { lineHeight: '32px', letterSpacing: '-0.3px', fontWeight: '800' }],
        'web-stat': ['30px', { lineHeight: '36px', fontWeight: '800' }],
        'web-eyebrow': ['11px', { lineHeight: '14px', letterSpacing: '0.6px', fontWeight: '700' }],
        'web-body': ['16px', { lineHeight: '24px' }],
        'web-card-title': ['16px', { lineHeight: '22px', fontWeight: '700' }],
        'web-small': ['13px', { lineHeight: '18px' }],
      },
      borderRadius: {
        xs: '4px',
        sm: '8px',
        md: '12px',
        lg: '16px',
        xl: '24px',
        sheet: '28px',
        bento: '20px',
      },
      boxShadow: {
        card: '0 1px 3px rgba(15,26,43,.06), 0 1px 2px rgba(15,26,43,.04)',
        'bar-top': '0 -4px 16px rgba(15,26,43,.08)',
        float: '0 8px 24px rgba(15,26,43,.14)',
        cta: '0 4px 10px rgba(0,108,74,.28)',
      },
      backgroundImage: {
        wallet: 'linear-gradient(135deg, #006C4A 0%, #047857 100%)',
        'photo-fade': 'linear-gradient(to top, rgba(0,0,0,.65), rgba(0,0,0,0) 60%)',
      },
      transitionTimingFunction: {
        emphasis: 'cubic-bezier(0.2, 0, 0, 1)',
      },
      transitionDuration: {
        fast: '150ms',
        base: '250ms',
        slow: '300ms',
        emphasis: '400ms',
      },
      keyframes: {
        'pulse-soft': {
          '0%, 100%': { opacity: '1', transform: 'scale(1)' },
          '50%': { opacity: '.5', transform: 'scale(1.25)' },
        },
        shimmer: {
          '100%': { transform: 'translateX(100%)' },
        },
      },
      animation: {
        'pulse-soft': 'pulse-soft 1600ms ease-in-out infinite',
        shimmer: 'shimmer 1200ms linear infinite',
      },
      maxWidth: {
        content: '1248px',
        measure: '640px',
      },
      screens: {
        sm: '640px',
        md: '768px',
        lg: '1024px',
        xl: '1280px',
      },
    },
  },
  plugins: [],
};

export default config;
