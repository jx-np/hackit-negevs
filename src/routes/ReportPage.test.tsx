import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { renderWithProviders } from '../test/utils';
import { mockFetch } from '../test/mockFetch';
import { ReportPage } from './ReportPage';

beforeEach(() => localStorage.clear());
afterEach(() => vi.unstubAllGlobals());

function seedLoggedIn() {
  localStorage.setItem(
    'scamreg-user',
    JSON.stringify({ id: 'u1', email: 'a@b.com', name: 'Alice' }),
  );
}

describe('ReportPage (auth gating)', () => {
  it('shows a login gate when logged out', () => {
    mockFetch([{ match: '/community/scam-types', json: { items: [] } }]);
    renderWithProviders(<ReportPage />);
    expect(screen.getByText(/log in to report a scam/i)).toBeInTheDocument();
    expect(
      screen.queryByRole('button', { name: /submit report/i }),
    ).not.toBeInTheDocument();
    expect(
      screen.getByRole('link', { name: /log in to continue/i }),
    ).toHaveAttribute('href', '/auth');
  });

  it('shows the full report form when logged in', async () => {
    mockFetch([
      {
        match: '/community/scam-types',
        json: { items: [{ slug: 'phishing', name_key: 'category.phishing' }] },
      },
    ]);
    seedLoggedIn();
    renderWithProviders(<ReportPage />);

    expect(
      screen.getByRole('button', { name: /submit report/i }),
    ).toBeInTheDocument();
    expect(screen.getByText(/when did it happen/i)).toBeInTheDocument();
    expect(screen.getByText(/click to choose an image/i)).toBeInTheDocument();
    await waitFor(() =>
      expect(screen.getByText(/choose a category/i)).toBeInTheDocument(),
    );
  });

  it('validates required fields before submitting', async () => {
    mockFetch([{ match: '/community/scam-types', json: { items: [] } }]);
    const user = userEvent.setup();
    seedLoggedIn();
    renderWithProviders(<ReportPage />);

    await user.click(screen.getByRole('button', { name: /submit report/i }));
    await waitFor(() =>
      expect(screen.getByText(/clear title/i)).toBeInTheDocument(),
    );
  });
});
