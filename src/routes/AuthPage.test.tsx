import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it } from 'vitest';
import { renderWithProviders } from '../test/utils';
import { AuthPage } from './AuthPage';

describe('AuthPage — continue as demo user', () => {
  beforeEach(() => localStorage.clear());

  it('offers a "Continue as demo user" button', () => {
    renderWithProviders(<AuthPage />);
    expect(
      screen.getByRole('button', { name: /continue as demo user/i }),
    ).toBeInTheDocument();
  });

  it('logs in a demo user on click (persists a session)', async () => {
    const user = userEvent.setup();
    renderWithProviders(<AuthPage />);

    await user.click(
      screen.getByRole('button', { name: /continue as demo user/i }),
    );
    await waitFor(() => {
      const stored = JSON.parse(localStorage.getItem('scamreg-user') ?? 'null');
      expect(stored).not.toBeNull();
      expect(stored.name).toBe('Demo User');
    });
  });
});
