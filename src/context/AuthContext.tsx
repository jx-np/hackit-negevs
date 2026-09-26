import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import type { User } from '../types';

/**
 * SCAFFOLDED AUTH.
 *
 * This is a placeholder auth layer with no real backend. It stores a fake
 * "logged in" user in localStorage so the login-to-comment flow works in the
 * UI. When the real API is ready, replace `login`/`logout` with calls to it
 * and validate the session on load.
 */
interface AuthState {
  user: User | null;
  isLoggedIn: boolean;
  /** Scaffolded sign-in: records a fake user. */
  login: (user?: Partial<User>) => void;
  logout: () => void;
}

const STORAGE_KEY = 'scamreg-auth';

const AuthContext = createContext<AuthState | undefined>(undefined);

function loadUser(): User | null {
  if (typeof window === 'undefined') return null;
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as User) : null;
  } catch {
    return null;
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(loadUser);

  useEffect(() => {
    try {
      if (user) {
        window.localStorage.setItem(STORAGE_KEY, JSON.stringify(user));
      } else {
        window.localStorage.removeItem(STORAGE_KEY);
      }
    } catch {
      /* ignore storage errors */
    }
  }, [user]);

  const login = useCallback((partial?: Partial<User>) => {
    // Scaffold: fabricate a user. Swap for real API response later.
    setUser({
      id: partial?.id ?? 'demo-user',
      email: partial?.email ?? 'demo@scamreg.app',
      name: partial?.name ?? 'Demo User',
    });
  }, []);

  const logout = useCallback(() => setUser(null), []);

  const value = useMemo<AuthState>(
    () => ({ user, isLoggedIn: user !== null, login, logout }),
    [user, login, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return ctx;
}
