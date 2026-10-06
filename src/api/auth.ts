/**
 * Auth API — register / login / logout / current user.
 *
 * These call the backend directly and return mapped UI types. Token storage
 * is handled by the AuthContext (which owns the tokenStore writes); these
 * functions just return the parsed response.
 */
import type { ApiAuthResponse, ApiUser, AuthTokens, User } from '../types';
import { apiFetch } from './client';
import { getRefreshToken } from './tokenStore';

export interface AuthResult {
  user: User;
  tokens: AuthTokens;
}

function mapUser(u: ApiUser): User {
  return {
    id: u.id,
    email: u.email,
    name: u.display_name,
    role: u.role,
    locale: u.locale,
  };
}

function mapAuth(res: ApiAuthResponse): AuthResult {
  return {
    user: mapUser(res.user),
    tokens: {
      accessToken: res.access_token,
      refreshToken: res.refresh_token,
      expiresIn: res.expires_in,
    },
  };
}

export async function register(input: {
  email: string;
  password: string;
  displayName: string;
  locale?: string;
}): Promise<AuthResult> {
  const res = await apiFetch<ApiAuthResponse>(
    '/auth/register',
    {
      method: 'POST',
      body: JSON.stringify({
        email: input.email,
        password: input.password,
        display_name: input.displayName,
        ...(input.locale ? { locale: input.locale } : {}),
      }),
    },
    true, // skip refresh — this IS the auth path
  );
  return mapAuth(res);
}

export async function login(input: {
  email: string;
  password: string;
}): Promise<AuthResult> {
  const res = await apiFetch<ApiAuthResponse>(
    '/auth/login',
    {
      method: 'POST',
      body: JSON.stringify({ email: input.email, password: input.password }),
    },
    true,
  );
  return mapAuth(res);
}

/** Revokes the current session server-side. Idempotent; never throws. */
export async function logout(): Promise<void> {
  const rt = getRefreshToken();
  if (!rt) return;
  try {
    await apiFetch<void>(
      '/auth/logout',
      { method: 'POST', body: JSON.stringify({ refresh_token: rt }) },
      true,
    );
  } catch {
    /* best-effort — clear local state regardless */
  }
}

/** Fetches the current authenticated user's profile. */
export async function getMe(): Promise<User> {
  const u = await apiFetch<ApiUser>('/me');
  return mapUser(u);
}
