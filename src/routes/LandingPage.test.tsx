import { screen } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { renderWithProviders } from '../test/utils';
import { mockFetch } from '../test/mockFetch';
import { LandingPage } from './LandingPage';

describe('LandingPage', () => {
  beforeEach(() => localStorage.clear());
  afterEach(() => vi.unstubAllGlobals());

  it('promotes the ScamWatch app with a top-level heading', () => {
    mockFetch([]);
    renderWithProviders(<LandingPage />, { route: '/' });
    // The marketing hero always has an h1, and the ScamWatch brand name
    // appears somewhere on the page. Both survive copy changes.
    expect(
      screen.getByRole('heading', { level: 1 }),
    ).toBeInTheDocument();
    expect(screen.getAllByText(/scamwatch/i).length).toBeGreaterThan(0);
  });

  it('links to the forum', () => {
    mockFetch([]);
    renderWithProviders(<LandingPage />, { route: '/' });
    const forumLinks = screen
      .getAllByRole('link')
      .filter((el) => el.getAttribute('href') === '/forum');
    expect(forumLinks.length).toBeGreaterThan(0);
  });
});
