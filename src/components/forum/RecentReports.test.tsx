import { screen } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { mockFetch } from '../../test/mockFetch';
import { renderWithProviders } from '../../test/utils';
import { RecentReports } from './RecentReports';

beforeEach(() => localStorage.clear());

afterEach(() => vi.unstubAllGlobals());

describe('RecentReports – active threat alerts', () => {
  it('renders alerts fetched from the news API', async () => {
    mockFetch([
      { match: '/community/feed', json: { items: [], next_cursor: null } },
      {
        match: '/news',
        json: {
          articles: [
            {
              id: 'news-1',
              icon: 'message_square_warning',
              title: {
                en: 'Fake bank SMS on the rise',
                ms: 'SMS bank palsu semakin meningkat',
              },
              text: {
                en: 'Scammers are sending texts that look like your bank. Never tap links in a text message.',
              },
            },
          ],
        },
      },
    ]);

    renderWithProviders(<RecentReports />);

    expect(
      await screen.findByText('Fake bank SMS on the rise'),
    ).toBeInTheDocument();
    expect(
      screen.getByText(
        'Scammers are sending texts that look like your bank. Never tap links in a text message.',
      ),
    ).toBeInTheDocument();
  });
});
