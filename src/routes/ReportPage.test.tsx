import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it } from 'vitest';
import { renderWithProviders } from '../test/utils';
import { ReportPage } from './ReportPage';

describe('ReportPage (auth gating)', () => {
  beforeEach(() => localStorage.clear());

  it('shows a login gate when logged out', () => {
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
    localStorage.setItem(
      'scamreg-auth',
      JSON.stringify({ id: 'u1', email: 'a@b.com', name: 'Alice' }),
    );
    renderWithProviders(<ReportPage />);

    expect(
      screen.getByRole('button', { name: /submit report/i }),
    ).toBeInTheDocument();
    // Incident date picker, media picker, and category are all present.
    expect(screen.getByText(/when did it happen/i)).toBeInTheDocument();
    expect(
      screen.getByText(/click to choose an image/i),
    ).toBeInTheDocument();
    await waitFor(() =>
      expect(screen.getByText(/choose a category/i)).toBeInTheDocument(),
    );
  });

  it('validates required fields before submitting', async () => {
    const user = userEvent.setup();
    localStorage.setItem(
      'scamreg-auth',
      JSON.stringify({ id: 'u1', email: 'a@b.com', name: 'Alice' }),
    );
    renderWithProviders(<ReportPage />);

    await user.click(screen.getByRole('button', { name: /submit report/i }));
    // A validation message for the title should appear.
    await waitFor(() =>
      expect(screen.getByText(/clear title/i)).toBeInTheDocument(),
    );
  });
});
