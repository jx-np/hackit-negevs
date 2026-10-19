import { act, renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import type { ReactNode } from 'react';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { usePostCommentsStream } from './usePostCommentsStream';
import { lastEventSource, MockEventSource } from '../test/mockEventSource';

function wrapper({ children }: { children: ReactNode }) {
  const client = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  return (
    <QueryClientProvider client={client}>{children}</QueryClientProvider>
  );
}

const botComment = {
  comment_id: 'c-bot',
  parent_id: 'c-trigger',
  author_id: 'bot',
  author_label: 'NegevAI',
  is_bot: true,
  body: 'Here is what I found.',
  status: 'visible',
  created_at: '2026-09-29T09:20:00Z',
  updated_at: '2026-09-29T09:20:00Z',
};

afterEach(() => vi.unstubAllGlobals());

describe('usePostCommentsStream', () => {
  it('does not connect without a post id', () => {
    const { result } = renderHook(() => usePostCommentsStream(undefined), {
      wrapper,
    });

    expect(result.current.status).toBe('offline');
    expect(MockEventSource.instances).toHaveLength(0);
  });

  it('connects to the post stream and reports the live status', async () => {
    const { result } = renderHook(() => usePostCommentsStream('post-1'), {
      wrapper,
    });

    const source = lastEventSource();
    expect(source.url).toContain('/community/posts/post-1/sse');

    act(() => {
      source.open();
      source.emit('ready', { post_id: 'post-1' });
    });

    await waitFor(() => expect(result.current.status).toBe('live'));
    expect(result.current.error).toBeNull();
  });

  it('announces a new comment over the stream', async () => {
    const { result } = renderHook(() => usePostCommentsStream('post-1'), {
      wrapper,
    });
    const source = lastEventSource();

    act(() => {
      source.emit('comment_created', {
        comment_id: 'c-1',
        author_id: 'u1',
        author_label: 'Alex',
        is_bot: false,
        body: 'New comment',
        status: 'visible',
        created_at: '2026-09-29T09:10:00Z',
        updated_at: '2026-09-29T09:10:00Z',
      });
    });

    await waitFor(() => expect(result.current.comments).toHaveLength(1));
    expect(result.current.comments[0].id).toBe('c-1');
    expect(result.current.comments[0].isBot).toBe(false);
  });

  it('de-duplicates a bot reply announced twice', async () => {
    const { result } = renderHook(() => usePostCommentsStream('post-1'), {
      wrapper,
    });
    const source = lastEventSource();

    act(() => {
      // The server announces the reply as `comment_created` and then again
      // as `grok_replied` with the same comment.
      source.emit('comment_created', botComment);
      source.emit('grok_replied', {
        post_id: 'post-1',
        trigger_comment_id: 'c-trigger',
        reply_comment_id: 'c-bot',
        fallback: false,
        comment: botComment,
      });
    });

    await waitFor(() => expect(result.current.comments).toHaveLength(1));
    expect(result.current.comments[0].id).toBe('c-bot');
    expect(result.current.comments[0].isBot).toBe(true);
  });

  it('tracks a pending @help request until it is answered', async () => {
    const { result } = renderHook(() => usePostCommentsStream('post-1'), {
      wrapper,
    });
    const source = lastEventSource();

    act(() => {
      source.emit('grok_thinking', {
        post_id: 'post-1',
        trigger_comment_id: 'c-trigger',
      });
    });

    await waitFor(() =>
      expect(result.current.pendingReplies).toEqual(['c-trigger']),
    );

    act(() => {
      source.emit('grok_replied', {
        post_id: 'post-1',
        trigger_comment_id: 'c-trigger',
        reply_comment_id: 'c-bot',
        fallback: false,
        comment: botComment,
      });
    });

    await waitFor(() => expect(result.current.pendingReplies).toHaveLength(0));
  });

  it('clears the pending state when the bot fails', async () => {
    const { result } = renderHook(() => usePostCommentsStream('post-1'), {
      wrapper,
    });
    const source = lastEventSource();

    act(() => {
      source.emit('grok_thinking', {
        post_id: 'post-1',
        trigger_comment_id: 'c-trigger',
      });
    });
    await waitFor(() =>
      expect(result.current.pendingReplies).toEqual(['c-trigger']),
    );

    act(() => {
      source.emit('grok_failed', {
        post_id: 'post-1',
        trigger_comment_id: 'c-trigger',
        reason: 'error',
      });
    });

    await waitFor(() => expect(result.current.pendingReplies).toHaveLength(0));
  });

  it('goes offline when the server refuses the stream', async () => {
    const { result } = renderHook(() => usePostCommentsStream('post-1'), {
      wrapper,
    });
    const source = lastEventSource();

    act(() => {
      source.emitError(true);
    });

    await waitFor(() => expect(result.current.status).toBe('offline'));
    expect(result.current.error).toMatch(/unavailable/i);
  });

  it('closes the stream when the component unmounts', () => {
    const { unmount } = renderHook(() => usePostCommentsStream('post-1'), {
      wrapper,
    });
    const source = lastEventSource();

    unmount();

    expect(source.readyState).toBe(MockEventSource.CLOSED);
    expect(source.listenerCount('comment_created')).toBe(0);
  });
});
