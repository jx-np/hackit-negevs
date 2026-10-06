/**
 * Auth context — real JWT auth backed by the Go backend.
 *
 * Token storage is managed via the tokenStore module (shared with the HTTP
 * client). On mount, if tokens exist, we validate them by fetching `/me`.
 * Login and registration save tokens immediately.
 */
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import * as authApi from '../api/auth';
import { clearTokens, getTokens, setTokens } from '../api/tokenStore';
import type { User } from '../types';

interface AuthState {
  user: User | null;
  isLoggedIn: boolean;
  /** True while the initial session restore is in progress. */
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (email: string, password: string, displayName: string) => Promise<void>;
  /** Scaffolded demo login — creates a fake local session. */
  loginDemo: (partial?: Partial<User>) => void;
  logout: () => Promise<void>;
}

// Persist user alongside tokens so we can render immediately while validating.
const USER_KEY = 'scamreg-user';

function loadPersistedUser(): User | null {
  try {
    const raw = window.localStorage.getItem(USER_KEY);
    return raw ? (JSON.parse(raw) as User) : null;
  } catch {
    return null;
  }
}

function persistUser(u: User | null): void {
  try {
    if (u) window.localStorage.setItem(USER_KEY, JSON.stringify(u));
    else window.localStorage.removeItem(USER_KEY);
  } catch {
    /* ignore */
  }
}

const AuthContext = createContext<AuthState | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(loadPersistedUser);
  const [isLoading, setIsLoading] = useState(() => !!getTokens());

  // On mount, validate persisted tokens with /me.
  useEffect(() => {
    const tokens = getTokens();
    if (!tokens) {
      setIsLoading(false);
      return;
    }
    authApi
      .getMe()
      .then((u) => {
        setUser(u);
        persistUser(u);
      })
      .catch(() => {
        // Token invalid or expired — clear everything.
        clearTokens();
        setUser(null);
        persistUser(null);
      })
      .finally(() => setIsLoading(false));
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    const result = await authApi.login({ email, password });
    setTokens(result.tokens);
    setUser(result.user);
    persistUser(result.user);
  }, []);

  const register = useCallback(
    async (email: string, password: string, displayName: string) => {
      const result = await authApi.register({ email, password, displayName });
      setTokens(result.tokens);
      setUser(result.user);
      persistUser(result.user);
    },
    [],
  );

  /** Demo login for the "Continue as demo user" button on /auth. */
  const loginDemo = useCallback((partial?: Partial<User>) => {
    const demo: User = {
      id: partial?.id ?? 'demo-user',
      email: partial?.email ?? 'demo@scamreg.app',
      name: partial?.name ?? 'Demo User',
    };
    setUser(demo);
    persistUser(demo);
    // No real tokens — pages will degrade gracefully.
  }, []);

  const logout = useCallback(async () => {
    await authApi.logout();
    clearTokens();
    setUser(null);
    persistUser(null);
  }, []);

  const value = useMemo<AuthState>(
    () => ({
      user,
      isLoggedIn: user !== null,
      isLoading,
      login,
      register,
      loginDemo,
      logout,
    }),
    [user, isLoading, login, register, loginDemo, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within an AuthProvider');
  return ctx;
}
