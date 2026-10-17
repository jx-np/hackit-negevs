import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { renderWithProviders } from '../../test/utils';
import { mockFetch } from '../../test/mockFetch';
import { Navbar } from './Navbar';

describe('Navbar', () => {
  beforeEach(() => localStorage.clear());
  afterEach(() => vi.unstubAllGlobals());

  it('exposes the primary navigation landmark and core destinations', () => {
    mockFetch([]);
    renderWithProviders(<Navbar />, { route: '/' });
    const nav = screen.getByRole('navigation', { name: /primary/i });
    expect(nav).toBeInTheDocument();
    const links = [
      { name: /home/i, href: '/' },
      { name: /forum/i, href: '/forum' },
      { name: /post/i, href: '/report' },
      { name: /check/i, href: '/check' },
      { name: /get help/i, href: '/help' },
    ];
    for (const { name, href } of links) {
      const matches = screen.getAllByRole('link', { name });
      expect(matches.some((el) => el.getAttribute('href') === href)).toBe(true);
    }
  });

  it('shows a sign-in link when logged out', () => {
    mockFetch([]);
    renderWithProviders(<Navbar />, { route: '/' });
    const signIn = screen
      .getAllByRole('link', { name: /sign in/i })
      .find((el) => el.getAttribute('href') === '/auth');
    expect(signIn).toBeTruthy();
  });

  it('shows the user name, My posts link, and a log out control when authenticated', async () => {
    localStorage.setItem(
      'scamreg-user',
      JSON.stringify({
        id: 'demo-user',
        email: 'demo@scamwatch.app',
        name: 'Demo User',
      }),
    );
    mockFetch([]);
    renderWithProviders(<Navbar />, { route: '/' });
    await waitFor(() =>
      expect(screen.getAllByText(/demo user/i).length).toBeGreaterThan(0),
    );
    const myPosts = screen
      .getAllByRole('link', { name: /my posts/i })
      .find((el) => el.getAttribute('href') === '/me/posts');
    expect(myPosts).toBeTruthy();
    expect(
      screen.getAllByRole('button', { name: /log out/i }).length,
    ).toBeGreaterThan(0);
  });

  it('toggles the mobile menu via the aria-expanded control', async () => {
    const user = userEvent.setup();
    mockFetch([]);
    renderWithProviders(<Navbar />, { route: '/' });
    const toggle = screen.getByRole('button', { name: /open menu/i });
    expect(toggle).toHaveAttribute('aria-expanded', 'false');
    await user.click(toggle);
    const close = screen.getByRole('button', { name: /close menu/i });
    expect(close).toHaveAttribute('aria-expanded', 'true');
  });
});
