import { QueryClientProvider } from '@tanstack/react-query';
import { act, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { AppearanceProvider } from '../context/AppearanceContext';
import { AuthProvider } from '../context/AuthContext';
import { SavedFeedsProvider } from '../context/SavedFeedsContext';
import { makeQueryClient } from '../test/utils';
import { mockFetch } from '../test/mockFetch';
import { lastEventSource } from '../test/mockEventSource';
import { PostDetailPage } from './PostDetailPage';
import type { ApiPostDetail } from '../types';

afterEach(() => {
  vi.unstubAllGlobals();
});

const MOCK_POST: ApiPostDetail = {
  post_id: 'post-1',
  title: 'Fake bank SMS',
  redacted_text: 'Your account is suspended ...',
  category: { slug: 'phishing', name_key: 'category.phishing' },
  tags: [{ slug: 'bank-impersonation', name_key: 'tag.bank_impersonation' }],
  review_status: 'reviewed',
  created_at: '2026-09-29T08:30:00Z',
  updated_at: '2026-09-29T09:00:00Z',
  comment_count: 4,
  reactions: { up: 10, down: 1 },
  my_vote: 0,
};

function renderAt(path: string) {
  const client = makeQueryClient();
  return render(
    <QueryClientProvider client={client}>
      <AppearanceProvider>
        <AuthProvider>
          <SavedFeedsProvider>
            <MemoryRouter initialEntries={[path]}>
              <Routes>
                <Route path="/forum/:id" element={<PostDetailPage />} />
              </Routes>
            </MemoryRouter>
          </SavedFeedsProvider>
        </AuthProvider>
      </AppearanceProvider>
    </QueryClientProvider>,
  );
}

describe('PostDetailPage', () => {
  it('renders the full post for a valid id', async () => {
    mockFetch([
      { match: '/community/posts/post-1', json: MOCK_POST },
    ]);
    renderAt('/forum/post-1');
    await waitFor(() =>
      expect(
        screen.getByRole('heading', { level: 1 }),
      ).toBeInTheDocument(),
    );
    expect(screen.getByText('Fake bank SMS')).toBeInTheDocument();
    expect(
      screen.getByRole('heading', { name: /discussion ·/i }),
    ).toBeInTheDocument();
    expect(screen.getByText(/back to forum/i)).toBeInTheDocument();
  });

  it('shows an error for an unknown id', async () => {
    mockFetch([
      {
        match: '/community/posts/does-not-exist',
        status: 404,
        json: { error: { code: 'not_found', message: 'Post not found' } },
      },
    ]);
    renderAt('/forum/does-not-exist');
    await waitFor(() =>
      expect(screen.getByText('Post not found')).toBeInTheDocument(),
    );
    expect(
      screen.getByRole('link', { name: /return to the forum/i }),
    ).toBeInTheDocument();
  });

  it('shows comments announced over the live stream without a reload', async () => {
    mockFetch([
      { match: '/community/posts/post-1', json: MOCK_POST },
      {
        match: '/community/discussion/posts/post-1/comments',
        json: { items: [], next_cursor: null },
      },
    ]);
    renderAt('/forum/post-1');

    await waitFor(() =>
      expect(screen.getByText(/no comments yet/i)).toBeInTheDocument(),
    );

    const source = lastEventSource();
    expect(source.url).toContain('/community/posts/post-1/sse');

    act(() => {
      source.open();
      source.emit('ready', { post_id: 'post-1' });
      source.emit('comment_created', {
        comment_id: 'c-bot',
        parent_id: null,
        author_id: 'bot',
        author_label: 'NegevAI',
        is_bot: true,
        body: 'This is a phishing attempt.',
        status: 'visible',
        created_at: '2026-09-29T09:20:00Z',
        updated_at: '2026-09-29T09:20:00Z',
      });
    });

    await waitFor(() =>
      expect(screen.getByText('This is a phishing attempt.')).toBeInTheDocument(),
    );
    expect(screen.getByTitle('AI-generated reply')).toBeInTheDocument();
    expect(screen.getByText(/live updates on/i)).toBeInTheDocument();
  });
});
