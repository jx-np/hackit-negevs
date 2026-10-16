import { screen } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { renderWithProviders } from '../test/utils';
import { ReportUserPage } from './ReportUserPage';

describe('ReportUserPage', () => {
  beforeEach(() => localStorage.clear());
  afterEach(() => vi.unstubAllGlobals());

  it('renders the page heading', () => {
    renderWithProviders(<ReportUserPage />, { route: '/report-user' });
    expect(
      screen.getByRole('heading', { name: /report a user/i }),
    ).toBeInTheDocument();
  });

  it('lists the reportable reasons', () => {
    renderWithProviders(<ReportUserPage />, { route: '/report-user' });
    expect(screen.getByText('Spam')).toBeInTheDocument();
    expect(screen.getByText('Harmful')).toBeInTheDocument();
    expect(screen.getByText('Misinformation')).toBeInTheDocument();
    expect(screen.getByText('Personal information')).toBeInTheDocument();
    expect(screen.getByText('Other')).toBeInTheDocument();
  });

  it('links to the forum and the help center', () => {
    renderWithProviders(<ReportUserPage />, { route: '/report-user' });
    expect(
      screen.getByRole('link', { name: /go to the forum/i }),
    ).toHaveAttribute('href', '/forum');
    expect(
      screen.getByRole('link', { name: /visit the help center/i }),
    ).toHaveAttribute('href', '/help');
  });
});
