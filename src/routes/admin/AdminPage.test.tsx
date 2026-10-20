import { screen } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { clearTokens } from '../../api/tokenStore';
import { mockFetch } from '../../test/mockFetch';
import { renderWithProviders } from '../../test/utils';
import { AdminPage } from './AdminPage';

function persistUser(role: 'resident' | 'moderator' | 'admin', name: string) {
  localStorage.setItem(
    'scamreg-user',
    JSON.stringify({
      id: '1',
      email: 'user@example.sg',
      name,
      role,
    }),
  );
}

describe('AdminPage', () => {
  beforeEach(() => {
    localStorage.clear();
    clearTokens();
  });
  afterEach(() => vi.unstubAllGlobals());

  it('asks signed-out visitors to sign in', () => {
    mockFetch([]);
    renderWithProviders(<AdminPage />, { route: '/admin' });
    expect(
      screen.getByRole('heading', { name: /staff sign-in required/i }),
    ).toBeInTheDocument();
  });

  it('blocks residents from the staff console', () => {
    persistUser('resident', 'Resident');
    mockFetch([]);
    renderWithProviders(<AdminPage />, { route: '/admin' });
    expect(
      screen.getByRole('heading', { name: /you don't have access/i }),
    ).toBeInTheDocument();
  });

  it('shows the console tabs to moderators but hides user management', () => {
    persistUser('moderator', 'Moderator');
    mockFetch([]);
    renderWithProviders(<AdminPage />, { route: '/admin' });

    expect(
      screen.getByRole('heading', { name: /admin dashboard/i }),
    ).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /reports/i })).toHaveAttribute(
      'href',
      '/admin/reports',
    );
    expect(
      screen.queryByRole('link', { name: /users & roles/i }),
    ).not.toBeInTheDocument();
  });

  it('shows user management to administrators', () => {
    persistUser('admin', 'Administrator');
    mockFetch([]);
    renderWithProviders(<AdminPage />, { route: '/admin' });

    expect(
      screen.getByRole('link', { name: /users & roles/i }),
    ).toHaveAttribute('href', '/admin/users');
  });
});
