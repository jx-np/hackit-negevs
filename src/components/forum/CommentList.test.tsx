import { screen, waitFor } from '@testing-library/react';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { renderWithProviders } from '../../test/utils';
import { mockFetch } from '../../test/mockFetch';
import { CommentList } from './CommentList';

afterEach(() => vi.unstubAllGlobals());

describe('CommentList', () => {
  it('fetches and renders a post\u2019s comments with threaded replies', async () => {
    mockFetch([
      {
        match: '/community/discussion/posts/post-1/comments',
        json: {
          items: [
            {
              comment_id: '1',
              author_id: 'u1',
              author_label: 'Alex',
              body: 'I got this exact message too!',
              status: 'visible',
              created_at: '2026-09-29T09:10:00Z',
              updated_at: '2026-09-29T09:10:00Z',
            },
            {
              comment_id: '2',
              parent_id: '1',
              author_id: 'u2',
              author_label: 'Jamie',
              body: 'Same here, reported it.',
              status: 'visible',
              created_at: '2026-09-29T09:20:00Z',
              updated_at: '2026-09-29T09:20:00Z',
            },
          ],
          next_cursor: null,
        },
      },
    ]);

    renderWithProviders(<CommentList postId="post-1" />);

    await waitFor(() =>
      expect(screen.getByText('I got this exact message too!')).toBeInTheDocument(),
    );
    // The one-level reply is rendered too.
    expect(screen.getByText('Same here, reported it.')).toBeInTheDocument();
    expect(screen.getByText('Alex')).toBeInTheDocument();
    expect(screen.getByText('Jamie')).toBeInTheDocument();
  });

  it('shows an empty state when there are no comments', async () => {
    mockFetch([
      {
        match: '/community/discussion/posts/post-2/comments',
        json: { items: [], next_cursor: null },
      },
    ]);

    renderWithProviders(<CommentList postId="post-2" />);

    await waitFor(() =>
      expect(screen.getByText(/no comments yet/i)).toBeInTheDocument(),
    );
  });
});
