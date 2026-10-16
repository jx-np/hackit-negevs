import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { renderWithProviders } from '../test/utils';
import { mockFetch } from '../test/mockFetch';
import { NumberCheckPage } from './NumberCheckPage';
import type { ApiTrustScore } from '../types';

beforeEach(() => localStorage.clear());
afterEach(() => vi.unstubAllGlobals());

function trustScore(over: Partial<ApiTrustScore> = {}): ApiTrustScore {
  return {
    phone_number: '+18005551234',
    trust_score: 60,
    rating: 'unknown',
    report_count: 0,
    known: false,
    ...over,
  };
}

async function lookup(value: string) {
  const user = userEvent.setup();
  renderWithProviders(<NumberCheckPage />);
  await user.type(screen.getByLabelText(/phone number/i), value);
  await user.click(screen.getByRole('button', { name: /check number/i }));
  return user;
}

describe('NumberCheckPage', () => {
  it('renders the lookup form', () => {
    renderWithProviders(<NumberCheckPage />);
    expect(screen.getByLabelText(/phone number/i)).toBeInTheDocument();
    expect(
      screen.getByRole('button', { name: /check number/i }),
    ).toBeInTheDocument();
  });

  it('shows a high-risk result for a scam number', async () => {
    mockFetch([
      {
        match: '/trust-score',
        json: trustScore({
          trust_score: 18,
          rating: 'high_risk',
          report_count: 42,
          known: true,
        }),
      },
    ]);
    await lookup('+18005551234');
    await waitFor(() =>
      expect(screen.getByText(/high risk/i)).toBeInTheDocument(),
    );
    // Trust score and scam reports are shown.
    expect(screen.getByText('18/100')).toBeInTheDocument();
    expect(screen.getByText('42')).toBeInTheDocument();
  });

  it('shows a trusted result for a trusted number', async () => {
    mockFetch([
      {
        match: '/trust-score',
        json: trustScore({
          phone_number: '+441632960000',
          trust_score: 90,
          rating: 'trusted',
          known: true,
        }),
      },
    ]);
    await lookup('+441632960000');
    await waitFor(() =>
      expect(screen.getByText(/trusted/i)).toBeInTheDocument(),
    );
  });

  it('shows an unknown result with a note when the number is not in the database', async () => {
    mockFetch([{ match: '/trust-score', json: trustScore() }]);
    await lookup('+19998887766');
    await waitFor(() =>
      expect(screen.getByText(/unknown/i)).toBeInTheDocument(),
    );
    expect(
      screen.getByText(/in the database yet/i),
    ).toBeInTheDocument();
  });

  it('shows the classification label only when the backend provides one', async () => {
    mockFetch([
      {
        match: '/trust-score',
        json: trustScore({
          trust_score: 18,
          rating: 'high_risk',
          report_count: 42,
          known: true,
          classification: 'impersonation',
        }),
      },
    ]);
    await lookup('+18005551234');
    await waitFor(() =>
      expect(screen.getByText('impersonation')).toBeInTheDocument(),
    );
    expect(screen.getByText(/reported as/i)).toBeInTheDocument();
  });

  it('omits the classification row when the label is empty', async () => {
    mockFetch([
      {
        match: '/trust-score',
        json: trustScore({ trust_score: 18, rating: 'high_risk', known: true }),
      },
    ]);
    await lookup('+18005551234');
    await waitFor(() =>
      expect(screen.getByText(/high risk/i)).toBeInTheDocument(),
    );
    expect(screen.queryByText(/reported as/i)).not.toBeInTheDocument();
  });
});
