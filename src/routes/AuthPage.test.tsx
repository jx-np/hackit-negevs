import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { renderWithProviders } from '../test/utils';
import { mockFetch } from '../test/mockFetch';
import { AuthPage } from './AuthPage';

describe('AuthPage — continue as demo user', () => {
  beforeEach(() => localStorage.clear());
  afterEach(() => vi.unstubAllGlobals());

  it('offers a "Continue as demo user" button', () => {
    mockFetch([]);
    renderWithProviders(<AuthPage />);
    expect(
      screen.getByRole('button', { name: /continue as demo user/i }),
    ).toBeInTheDocument();
  });

  it('logs in with the real backend using the demo credentials', async () => {
    const fetchMock = mockFetch([
      {
        match: '/auth/login',
        method: 'POST',
        json: {
          user: {
            id: 'demo-1',
            email: 'demo@gmail.com',
            display_name: 'Demo User',
            role: 'resident',
            locale: 'en',
          },
          access_token: 'access-token',
          refresh_token: 'refresh-token',
          expires_in: 3600,
        },
      },
    ]);

    const user = userEvent.setup();
    renderWithProviders(<AuthPage />);

    await user.click(
      screen.getByRole('button', { name: /continue as demo user/i }),
    );

    // The demo credentials were POSTed to the real login endpoint.
    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalled();
    });
    const loginCall = fetchMock.mock.calls.find(([url]) =>
      String(url).includes('/auth/login'),
    );
    expect(loginCall).toBeTruthy();
    const body = JSON.parse((loginCall![1] as RequestInit).body as string);
    expect(body.email).toBe('demo@gmail.com');
    expect(body.password).toBe('xSFJ@2KyMQEKYa8');

    // The authenticated user is persisted to the session.
    await waitFor(() => {
      const stored = JSON.parse(localStorage.getItem('scamreg-user') ?? 'null');
      expect(stored).not.toBeNull();
      expect(stored.name).toBe('Demo User');
    });
  });
});
