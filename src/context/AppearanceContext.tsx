import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';

export type ThemeMode = 'light' | 'dark';
export type FontChoice =
  | 'sans'
  | 'serif'
  | 'mono'
  | 'atkinson'
  | 'lexend'
  | 'opensans';
export type FontSize = 'sm' | 'md' | 'lg';

const FONT_STACKS: Record<FontChoice, string> = {
  sans: "'Inter', system-ui, -apple-system, sans-serif",
  serif: "'Georgia', 'Times New Roman', serif",
  mono: "'JetBrains Mono', 'Courier New', monospace",
  // Readability-focused options (easier on the eye / dyslexia-friendly)
  atkinson: "'Atkinson Hyperlegible', system-ui, sans-serif",
  lexend: "'Lexend', system-ui, sans-serif",
  opensans: "'Open Sans', system-ui, sans-serif",
};

const FONT_SCALES: Record<FontSize, number> = {
  sm: 0.9,
  md: 1,
  lg: 1.15,
};

interface AppearanceState {
  theme: ThemeMode;
  font: FontChoice;
  fontSize: FontSize;
  toggleTheme: () => void;
  setFont: (font: FontChoice) => void;
  setFontSize: (size: FontSize) => void;
}

const STORAGE_KEY = 'forum-appearance';

interface Persisted {
  theme: ThemeMode;
  font: FontChoice;
  fontSize: FontSize;
}

function loadInitial(): Persisted {
  if (typeof window !== 'undefined') {
    try {
      const raw = window.localStorage.getItem(STORAGE_KEY);
      if (raw) return JSON.parse(raw) as Persisted;
    } catch {
      /* ignore malformed storage */
    }
    const prefersDark = window.matchMedia(
      '(prefers-color-scheme: dark)',
    ).matches;
    return {
      theme: prefersDark ? 'dark' : 'light',
      font: 'atkinson',
      fontSize: 'md',
    };
  }
  return { theme: 'light', font: 'atkinson', fontSize: 'md' };
}

const AppearanceContext = createContext<AppearanceState | undefined>(undefined);

export function AppearanceProvider({ children }: { children: ReactNode }) {
  const initial = loadInitial();
  const [theme, setTheme] = useState<ThemeMode>(initial.theme);
  const [font, setFontState] = useState<FontChoice>(initial.font);
  const [fontSize, setFontSizeState] = useState<FontSize>(initial.fontSize);

  // Apply theme class + CSS variables to <html> and persist on any change.
  useEffect(() => {
    const root = document.documentElement;
    root.classList.toggle('dark', theme === 'dark');
    root.style.setProperty('--app-font-family', FONT_STACKS[font]);
    root.style.setProperty('--app-font-scale', String(FONT_SCALES[fontSize]));

    try {
      window.localStorage.setItem(
        STORAGE_KEY,
        JSON.stringify({ theme, font, fontSize }),
      );
    } catch {
      /* ignore quota errors */
    }
  }, [theme, font, fontSize]);

  const toggleTheme = useCallback(
    () => setTheme((t) => (t === 'dark' ? 'light' : 'dark')),
    [],
  );
  const setFont = useCallback((f: FontChoice) => setFontState(f), []);
  const setFontSize = useCallback((s: FontSize) => setFontSizeState(s), []);

  const value = useMemo(
    () => ({ theme, font, fontSize, toggleTheme, setFont, setFontSize }),
    [theme, font, fontSize, toggleTheme, setFont, setFontSize],
  );

  return (
    <AppearanceContext.Provider value={value}>
      {children}
    </AppearanceContext.Provider>
  );
}

export function useAppearance(): AppearanceState {
  const ctx = useContext(AppearanceContext);
  if (!ctx) {
    throw new Error('useAppearance must be used within an AppearanceProvider');
  }
  return ctx;
}
