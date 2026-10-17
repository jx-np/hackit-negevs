import { screen, waitFor } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { renderWithProviders } from '../test/utils';
import { mockFetch } from '../test/mockFetch';
import { MyPostsPage } from './MyPostsPage';

describe('MyPostsPage', () => {
  beforeEach(() => localStorage.clear());
  afterEach(() => vi.unstubAllGlobals());

  it('prompts anonymous visitors to sign in', async () => {
    mockFetch([]);
    renderWithProviders(<MyPostsPage />, { route: '/me/posts' });
    await waitFor(() =>
      expect(
        screen.getByText(/sign in to see your posts/i),
      ).toBeInTheDocument(),
    );
    expect(screen.getByRole('link', { name: /sign in/i })).toHaveAttribute(
      'href',
      '/auth',
    );
  });

  it('shows an empty state when a signed-in user has no posts', async () => {
    localStorage.setItem(
      'scamreg-user',
      JSON.stringify({
        id: 'demo-user',
        email: 'demo@scamwatch.app',
        name: 'Demo User',
      }),
    );
    mockFetch([
      { match: '/me/posts', json: { items: [], next_cursor: null } },
    ]);
    renderWithProviders(<MyPostsPage />, { route: '/me/posts' });
    await waitFor(() =>
      expect(screen.getByText(/no posts yet/i)).toBeInTheDocument(),
    );
    expect(
      screen.getByRole('link', { name: /report a scam/i }),
    ).toHaveAttribute('href', '/report');
  });
});
