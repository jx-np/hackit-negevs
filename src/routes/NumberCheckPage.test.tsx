import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it } from 'vitest';
import { renderWithProviders } from '../test/utils';
import { NumberCheckPage } from './NumberCheckPage';

async function lookup(value: string) {
  const user = userEvent.setup();
  renderWithProviders(<NumberCheckPage />);
  await user.type(screen.getByLabelText(/phone number/i), value);
  await user.click(screen.getByRole('button', { name: /check number/i }));
  return user;
}

describe('NumberCheckPage', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it('renders the lookup form', () => {
    renderWithProviders(<NumberCheckPage />);
    expect(screen.getByLabelText(/phone number/i)).toBeInTheDocument();
    expect(
      screen.getByRole('button', { name: /check number/i }),
    ).toBeInTheDocument();
  });

  it('shows a scam result with report counts for a flagged number', async () => {
    await lookup('+18005551234');
    await waitFor(() =>
      expect(screen.getByText(/reported scam/i)).toBeInTheDocument(),
    );
    expect(screen.getByText('+18005551234')).toBeInTheDocument();
    // Total reports stat + scam/trusted breakdown are visible.
    expect(screen.getByText(/total reports/i)).toBeInTheDocument();
  });

  it('shows a trusted result for a trusted number', async () => {
    await lookup('+441632960000');
    // The trusted status blurb is unique to the trusted verdict.
    await waitFor(() =>
      expect(
        screen.getByText(/mostly reported as legitimate/i),
      ).toBeInTheDocument(),
    );
    expect(screen.getByText('+441632960000')).toBeInTheDocument();
  });

  it('shows "log in to report" when logged out', async () => {
    await lookup('+18005551234');
    await waitFor(() =>
      expect(screen.getByText(/log in to report/i)).toBeInTheDocument(),
    );
    // The report buttons should NOT be available while logged out.
    expect(
      screen.queryByRole('button', { name: /report as scam/i }),
    ).not.toBeInTheDocument();
    // There is a link to the auth page.
    expect(screen.getByRole('link', { name: /log in/i })).toHaveAttribute(
      'href',
      '/auth',
    );
  });

  it('shows report buttons when logged in', async () => {
    // Seed a logged-in session.
    localStorage.setItem(
      'scamreg-auth',
      JSON.stringify({ id: 'u1', email: 'a@b.com', name: 'Alice' }),
    );
    await lookup('+18005551234');
    await waitFor(() =>
      expect(
        screen.getByRole('button', { name: /report as scam/i }),
      ).toBeInTheDocument(),
    );
    expect(
      screen.getByRole('button', { name: /mark as trusted/i }),
    ).toBeInTheDocument();
    expect(screen.queryByText(/log in to report/i)).not.toBeInTheDocument();
  });
});


describe('NumberCheckPage — one report per account', () => {
  beforeEach(() => localStorage.clear());

  it('replaces the report buttons with a confirmation after reporting', async () => {
    localStorage.setItem(
      'scamreg-auth',
      JSON.stringify({ id: 'ui-user-1', email: 'a@b.com', name: 'Alice' }),
    );
    const user = await lookup('+441632960099');

    // Report buttons appear while logged in and not yet reported.
    const scamBtn = await screen.findByRole('button', {
      name: /report as scam/i,
    });
    await user.click(scamBtn);

    // After reporting, the buttons are gone and a confirmation shows.
    await waitFor(() =>
      expect(
        screen.getByText(/each account can report a number once/i),
      ).toBeInTheDocument(),
    );
    expect(
      screen.queryByRole('button', { name: /report as scam/i }),
    ).not.toBeInTheDocument();
  });
});
