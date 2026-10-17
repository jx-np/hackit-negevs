import { screen } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { renderWithProviders } from '../test/utils';
import { NotFoundPage } from './NotFoundPage';

describe('NotFoundPage', () => {
  beforeEach(() => localStorage.clear());
  afterEach(() => vi.unstubAllGlobals());

  it('renders the 404 heading', () => {
    renderWithProviders(<NotFoundPage />, { route: '/nope' });
    expect(screen.getByRole('heading', { name: '404' })).toBeInTheDocument();
  });

  it('shows the attempted pathname', () => {
    renderWithProviders(<NotFoundPage />, { route: '/some/missing/path' });
    expect(screen.getByText('/some/missing/path')).toBeInTheDocument();
  });

  it('links back to home and to the forum', () => {
    renderWithProviders(<NotFoundPage />, { route: '/nope' });
    expect(screen.getByRole('link', { name: /back to home/i })).toHaveAttribute(
      'href',
      '/',
    );
    expect(
      screen.getByRole('link', { name: /enter the forum/i }),
    ).toHaveAttribute('href', '/forum');
  });
});
