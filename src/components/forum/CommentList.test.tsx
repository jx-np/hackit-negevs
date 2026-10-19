import { screen, waitFor } from '@testing-library/react';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { renderWithProviders } from '../../test/utils';
import { mockFetch } from '../../test/mockFetch';
import { CommentList } from './CommentList';
import type { Comment } from '../../types';

afterEach(() => vi.unstubAllGlobals());

function liveComment(overrides: Partial<Comment> = {}): Comment {
  return {
    id: 'c-live',
    parentId: null,
    authorId: 'bot',
    authorLabel: 'NegevAI',
    isBot: true,
    body: 'Here is what I found.',
    status: 'visible',
    createdAt: '2026-09-29T09:20:00Z',
    updatedAt: '2026-09-29T09:20:00Z',
    ...overrides,
  };
}

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

  it('marks bot comments with an AI badge', async () => {
    mockFetch([
      {
        match: '/community/discussion/posts/post-3/comments',
        json: {
          items: [
            {
              comment_id: '3',
              author_id: 'bot',
              author_label: 'NegevAI',
              is_bot: true,
              body: 'This is a known "advance fee" scam.',
              status: 'visible',
              created_at: '2026-09-29T09:10:00Z',
              updated_at: '2026-09-29T09:10:00Z',
            },
          ],
          next_cursor: null,
        },
      },
    ]);

    renderWithProviders(<CommentList postId="post-3" />);

    await waitFor(() =>
      expect(screen.getByText(/known "advance fee" scam/i)).toBeInTheDocument(),
    );
    expect(screen.getByTitle('AI-generated reply')).toBeInTheDocument();
  });

  it('merges live comments into the thread without duplicating them', async () => {
    mockFetch([
      {
        match: '/community/discussion/posts/post-4/comments',
        json: {
          items: [
            {
              comment_id: '1',
              author_id: 'u1',
              author_label: 'Alex',
              is_bot: false,
              body: 'I got this exact message too!',
              status: 'visible',
              created_at: '2026-09-29T09:10:00Z',
              updated_at: '2026-09-29T09:10:00Z',
            },
          ],
          next_cursor: null,
        },
      },
    ]);

    renderWithProviders(
      <CommentList
        postId="post-4"
        liveComments={[
          liveComment(),
          // Already fetched — must not be rendered twice.
          {
            id: '1',
            parentId: null,
            authorId: 'u1',
            authorLabel: 'Alex',
            isBot: false,
            body: 'I got this exact message too!',
            status: 'visible',
            createdAt: '2026-09-29T09:10:00Z',
            updatedAt: '2026-09-29T09:10:00Z',
          },
        ]}
      />,
    );

    await waitFor(() =>
      expect(screen.getByText(/I got this exact message too!/)).toBeInTheDocument(),
    );
    expect(screen.getByText('Here is what I found.')).toBeInTheDocument();
    expect(screen.getAllByText('I got this exact message too!')).toHaveLength(1);
  });

  it('shows a thinking indicator for a pending @help request', async () => {
    mockFetch([
      {
        match: '/community/discussion/posts/post-5/comments',
        json: {
          items: [
            {
              comment_id: 'c-trigger',
              author_id: 'u1',
              author_label: 'Alex',
              is_bot: false,
              body: '@help what type of scam is this?',
              status: 'visible',
              created_at: '2026-09-29T09:10:00Z',
              updated_at: '2026-09-29T09:10:00Z',
            },
          ],
          next_cursor: null,
        },
      },
    ]);

    renderWithProviders(
      <CommentList postId="post-5" pendingReplies={['c-trigger']} />,
    );

    await waitFor(() =>
      expect(screen.getByText(/NegevAI is thinking/i)).toBeInTheDocument(),
    );
  });

  it('shows the live status of the discussion stream', async () => {
    mockFetch([
      {
        match: '/community/discussion/posts/post-6/comments',
        json: { items: [], next_cursor: null },
      },
    ]);

    renderWithProviders(
      <CommentList postId="post-6" streamStatus="live" />,
    );

    await waitFor(() =>
      expect(screen.getByText(/live updates on/i)).toBeInTheDocument(),
    );
  });
});
