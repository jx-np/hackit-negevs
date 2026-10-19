/**
 * Live discussion stream for a post (Server-Sent Events).
 *
 * The backend streams `GET /community/posts/{id}/sse`, which announces new
 * comments and the AI assistant's (`@help`) progress for one publicly visible
 * post.
 * `EventSource` cannot send an `Authorization` header, but the endpoint only
 * ever streams already-public, server-scrubbed data, so no token is needed.
 *
 * Protocol notes (see `API.docs.md` §8):
 *  - The stream opens with `ready`; a reconnect also gets a fresh `ready`.
 *  - There is no event replay (`Last-Event-ID` is not supported), so the
 *    comments list is refetched on every `ready` to fill any gap.
 *  - A bot reply is announced as `comment_created` immediately followed by
 *    `grok_replied` carrying the same comment, so clients de-duplicate by
 *    `comment_id`.
 *  - Every `grok_thinking` is terminated by exactly one `grok_replied` or
 *    `grok_failed`.
 */
import { useEffect, useRef, useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { mapStreamComment } from '../api/comments';
import { getPostStreamUrl } from '../api/sse';
import type {
  ApiStreamComment,
  ApiStreamBotFailed,
  ApiStreamBotReplied,
  ApiStreamBotThinking,
  ApiStreamReady,
  Comment,
  StreamStatus,
} from '../types';

export interface PostCommentsStream {
  /** Comments announced live, de-duplicated by id, in arrival order. */
  comments: Comment[];
  /** `trigger_comment_id`s of AI-bot requests the bot is still answering. */
  pendingReplies: string[];
  /** Connection state of the stream. */
  status: StreamStatus;
  /** Set when the stream could not be established (e.g. post not visible). */
  error: string | null;
}

/** `EventSource` ready state (the DOM constants are not available in tests). */
const ES_CLOSED = 2;

interface PostStreamState {
  comments: Comment[];
  pendingReplies: string[];
  status: StreamStatus;
  error: string | null;
}

const INITIAL_STATE: PostStreamState = {
  comments: [],
  pendingReplies: [],
  status: 'connecting',
  error: null,
};

function parseData<T>(event: Event): T | null {
  try {
    return JSON.parse((event as MessageEvent<string>).data) as T;
  } catch {
    return null;
  }
}

/**
 * Subscribe to a post's live discussion stream.
 *
 * Pass `undefined` (or `enabled: false`) to stay disconnected — the returned
 * state is then empty and the status is `offline`.
 */
export function usePostCommentsStream(
  postId: string | undefined,
  enabled = true,
): PostCommentsStream {
  const queryClient = useQueryClient();
  // State is kept per post so switching posts never shows stale comments.
  const [states, setStates] = useState<Record<string, PostStreamState>>({});
  // Ids already rendered, so a bot reply announced twice (`comment_created`
  // + `grok_replied`) is only shown once.
  const seen = useRef<Map<string, Set<string>>>(new Map());

  useEffect(() => {
    if (!enabled || !postId) return;

    const seenIds = seen.current.get(postId) ?? new Set<string>();
    seen.current.set(postId, seenIds);

    const update = (patch: Partial<PostStreamState>) => {
      setStates((prev) => ({
        ...prev,
        [postId]: { ...(prev[postId] ?? INITIAL_STATE), ...patch },
      }));
    };

    const source = new EventSource(getPostStreamUrl(postId));

    const onReady = (event: Event) => {
      const data = parseData<ApiStreamReady>(event);
      if (data?.post_id && data.post_id !== postId) return;
      update({ status: 'live', error: null, pendingReplies: [] });
      // No event replay: refetch the thread so anything that happened while
      // the stream was down is picked up.
      queryClient.invalidateQueries({ queryKey: ['comments', postId] });
    };

    const onCommentCreated = (event: Event) => {
      const data = parseData<ApiStreamComment>(event);
      if (!data?.comment_id) return;
      if (seenIds.has(data.comment_id)) return;
      seenIds.add(data.comment_id);
      setStates((prev) => {
        const current = prev[postId] ?? INITIAL_STATE;
        return {
          ...prev,
          [postId]: {
            ...current,
            comments: [...current.comments, mapStreamComment(data)],
          },
        };
      });
      // Keep the comment count on the post fresh.
      queryClient.invalidateQueries({ queryKey: ['post', postId] });
    };

    const onBotThinking = (event: Event) => {
      const data = parseData<ApiStreamBotThinking>(event);
      const trigger = data?.trigger_comment_id;
      if (!trigger) return;
      setStates((prev) => {
        const current = prev[postId] ?? INITIAL_STATE;
        if (current.pendingReplies.includes(trigger)) return prev;
        return {
          ...prev,
          [postId]: {
            ...current,
            pendingReplies: [...current.pendingReplies, trigger],
          },
        };
      });
    };

    const onBotReplied = (event: Event) => {
      const data = parseData<ApiStreamBotReplied>(event);
      if (!data) return;
      const reply = data.comment;
      const isNew = !!reply?.comment_id && !seenIds.has(reply.comment_id);
      if (isNew) seenIds.add(reply!.comment_id);

      setStates((prev) => {
        const current = prev[postId] ?? INITIAL_STATE;
        return {
          ...prev,
          [postId]: {
            ...current,
            pendingReplies: current.pendingReplies.filter(
              (id) => id !== data.trigger_comment_id,
            ),
            comments: isNew
              ? [...current.comments, mapStreamComment(reply!)]
              : current.comments,
          },
        };
      });

      if (!reply?.comment_id) {
        // The stored row could not be re-loaded — refetch the thread.
        queryClient.invalidateQueries({ queryKey: ['comments', postId] });
      }
      queryClient.invalidateQueries({ queryKey: ['post', postId] });
    };

    const onBotFailed = (event: Event) => {
      const data = parseData<ApiStreamBotFailed>(event);
      if (!data?.trigger_comment_id) return;
      setStates((prev) => {
        const current = prev[postId] ?? INITIAL_STATE;
        return {
          ...prev,
          [postId]: {
            ...current,
            pendingReplies: current.pendingReplies.filter(
              (id) => id !== data.trigger_comment_id,
            ),
          },
        };
      });
    };

    const onError = () => {
      if (source.readyState === ES_CLOSED) {
        // The server refused the stream (invalid/hidden post, or the
        // connection cap was reached). `EventSource` gives up for good.
        update({
          status: 'offline',
          error: 'Live updates are unavailable for this post.',
        });
        return;
      }
      // Still reconnecting (the browser retries after the `retry: 3000` hint).
      update({ status: 'connecting' });
    };

    source.addEventListener('ready', onReady);
    source.addEventListener('comment_created', onCommentCreated);
    source.addEventListener('grok_thinking', onBotThinking);
    source.addEventListener('grok_replied', onBotReplied);
    source.addEventListener('grok_failed', onBotFailed);
    source.addEventListener('error', onError);

    return () => {
      source.removeEventListener('ready', onReady);
      source.removeEventListener('comment_created', onCommentCreated);
      source.removeEventListener('grok_thinking', onBotThinking);
      source.removeEventListener('grok_replied', onBotReplied);
      source.removeEventListener('grok_failed', onBotFailed);
      source.removeEventListener('error', onError);
      source.close();
    };
  }, [postId, enabled, queryClient]);

  if (!enabled || !postId) {
    return { comments: [], pendingReplies: [], status: 'offline', error: null };
  }
  const state = states[postId] ?? INITIAL_STATE;
  return {
    comments: state.comments,
    pendingReplies: state.pendingReplies,
    status: state.status,
    error: state.error,
  };
}
