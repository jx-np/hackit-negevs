import { screen, waitFor } from '@testing-library/react';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { mockFetch } from '../../test/mockFetch';
import { renderWithProviders } from '../../test/utils';
import { AdminReportsPage } from './AdminReportsPage';

afterEach(() => vi.unstubAllGlobals());

describe('AdminReportsPage', () => {
  it('renders a flag when the server omits post_review_status', async () => {
    mockFetch([
      {
        match: '/admin/flags',
        json: {
          items: [
            {
              flag_id: '9',
              reporter_id: '3',
              reason: 'spam',
              status: 'open',
              created_at: '2026-10-19T09:20:00Z',
              target_type: 'post',
              target_id: '44',
              post_id: '44',
              post_title: 'Suspicious post',
              excerpt: 'Buy now, limited offer.',
              // Deliberately missing: post_review_status
              post_deleted: false,
              target_author_id: '12',
            },
          ],
          next_cursor: null,
        },
      },
    ]);

    renderWithProviders(<AdminReportsPage />, { route: '/admin/reports' });

    await waitFor(() =>
      expect(screen.getByText('Suspicious post')).toBeInTheDocument(),
    );
    expect(screen.getByText('Unknown')).toBeInTheDocument();
  });
});
