import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  ExternalLink,
  MessageSquare,
  Search,
  Trash2,
  X,
} from 'lucide-react';
import { useState } from 'react';
import { Link } from 'react-router-dom';
import { bulkDeleteComments, getAdminComments } from '../../api/admin';
import {
  ADMIN_INPUT_CLASS,
  ADMIN_SELECT_CLASS,
  AdminEmptyState,
  AdminError,
  AdminLoading,
  Badge,
  DangerButton,
  PaginationBar,
  StatusBadge,
} from '../../components/admin/AdminUi';
import { useCursorPagination } from '../../hooks/useCursorPagination';
import { useDebounce } from '../../hooks/useDebounce';
import { relativeDate } from '../../lib/date';
import type { AdminCommentStatus, BulkDeleteResult } from '../../types';

const STATUS_OPTIONS: Array<{ value: AdminCommentStatus; label: string }> = [
  { value: 'all', label: 'All comments' },
  { value: 'visible', label: 'Visible' },
  { value: 'hidden', label: 'Hidden' },
  { value: 'removed', label: 'Removed' },
];

export function AdminCommentsPage() {
  const queryClient = useQueryClient();
  const [status, setStatus] = useState<AdminCommentStatus>('all');
  const [search, setSearch] = useState('');
  const q = useDebounce(search, 350);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [lastResult, setLastResult] = useState<BulkDeleteResult | null>(null);
  const { cursor, goNext, goPrev, reset, hasPrev } = useCursorPagination();

  const { data, isLoading, isError, error, refetch, isFetching } = useQuery({
    queryKey: ['admin', 'comments', status, q, cursor],
    queryFn: () => getAdminComments({ status, q, cursor }),
  });

  const items = data?.items ?? [];
  const selectableIds = items
    .filter((c) => c.status !== 'removed')
    .map((c) => c.id);
  const allSelected =
    selectableIds.length > 0 && selectableIds.every((id) => selected.has(id));

  function invalidate(postIds: string[]) {
    queryClient.invalidateQueries({ queryKey: ['admin'] });
    queryClient.invalidateQueries({ queryKey: ['posts'] });
    for (const postId of new Set(postIds)) {
      queryClient.invalidateQueries({ queryKey: ['post', postId] });
      queryClient.invalidateQueries({ queryKey: ['comments', postId] });
    }
  }

  const bulkMutation = useMutation({
    mutationFn: (ids: string[]) => bulkDeleteComments(ids),
    onSuccess: (result) => {
      setLastResult(result);
      setSelected(new Set());
      invalidate(items.map((c) => c.postId));
    },
  });

  const rowMutation = useMutation({
    mutationFn: (comment: { id: string; postId: string }) =>
      bulkDeleteComments([comment.id]),
    onSuccess: (result, comment) => {
      setLastResult(result);
      setSelected((prev) => {
        const next = new Set(prev);
        for (const id of result.deleted) next.delete(id);
        return next;
      });
      invalidate([comment.postId]);
    },
  });

  function changeStatus(next: AdminCommentStatus) {
    setStatus(next);
    setSelected(new Set());
    reset();
  }

  function changeSearch(next: string) {
    setSearch(next);
    setSelected(new Set());
    reset();
  }

  function toggle(id: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  function toggleAll() {
    setSelected((prev) => {
      if (allSelected) {
        const next = new Set(prev);
        for (const id of selectableIds) next.delete(id);
        return next;
      }
      return new Set([...prev, ...selectableIds]);
    });
  }

  function deleteSelected() {
    if (selected.size === 0) return;
    if (
      !window.confirm(
        `Remove ${selected.size} ${
          selected.size === 1 ? 'comment' : 'comments'
        }? This is a soft removal and can be reviewed later.`,
      )
    ) {
      return;
    }
    bulkMutation.mutate([...selected]);
  }

  function deleteOne(comment: { id: string; postId: string }) {
    if (!window.confirm('Remove this comment?')) return;
    rowMutation.mutate(comment);
  }

  return (
    <div className="space-y-4">
      <div className="rounded-2xl border border-scam-line bg-scam-800 p-4 shadow-card">
        <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <h2 className="font-display text-lg font-bold text-scam-text">
              Comments
            </h2>
            <p className="mt-0.5 text-sm text-scam-muted">
              Comments across every post, including hidden and removed replies.
            </p>
          </div>
          <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
            <div className="relative">
              <Search
                size={15}
                className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-scam-dim"
                aria-hidden
              />
              <label htmlFor="comment-search" className="sr-only">
                Search comments
              </label>
              <input
                id="comment-search"
                type="search"
                value={search}
                onChange={(e) => changeSearch(e.target.value)}
                placeholder="Search body or post title…"
                className={`${ADMIN_INPUT_CLASS} w-full pl-9 sm:w-64`}
              />
            </div>
            <label htmlFor="comment-status" className="sr-only">
              Comment status
            </label>
            <select
              id="comment-status"
              value={status}
              onChange={(e) => changeStatus(e.target.value as AdminCommentStatus)}
              className={ADMIN_SELECT_CLASS}
            >
              {STATUS_OPTIONS.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {lastResult && (
        <div
          role="status"
          className="flex flex-wrap items-center gap-x-3 gap-y-2 rounded-xl border border-scam-line bg-scam-800 px-4 py-3 text-sm"
        >
          <span className="font-semibold text-risk-low">
            {lastResult.deletedCount}{' '}
            {lastResult.deletedCount === 1 ? 'comment' : 'comments'} removed
          </span>
          {lastResult.failedCount > 0 && (
            <span className="text-scam-muted">
              {lastResult.failedCount} failed:{' '}
              {lastResult.failed
                .slice(0, 3)
                .map((f) => `#${f.id} (${f.reason})`)
                .join(', ')}
              {lastResult.failedCount > 3 ? '…' : ''}
            </span>
          )}
          <button
            type="button"
            onClick={() => setLastResult(null)}
            className="ml-auto grid h-6 w-6 place-items-center rounded text-scam-muted hover:bg-scam-750 hover:text-scam-text"
            aria-label="Dismiss result"
          >
            <X size={14} />
          </button>
        </div>
      )}

      {selected.size > 0 && (
        <div className="flex flex-wrap items-center gap-3 rounded-xl border border-risk-high/30 bg-risk-high/10 px-4 py-3">
          <span className="text-sm font-semibold text-scam-text">
            <span className="sr-nums">{selected.size}</span> selected
          </span>
          <button
            type="button"
            onClick={() => setSelected(new Set())}
            className="text-xs font-semibold text-scam-muted underline hover:text-scam-text"
          >
            Clear selection
          </button>
          <div className="ml-auto">
            <DangerButton
              onClick={deleteSelected}
              disabled={bulkMutation.isPending || rowMutation.isPending}
            >
              <Trash2 size={14} />
              {bulkMutation.isPending ? 'Removing…' : 'Remove selected'}
            </DangerButton>
          </div>
        </div>
      )}

      {bulkMutation.isError && (
        <div className="rounded-xl border border-risk-high/40 bg-risk-high/10 px-4 py-3 text-sm text-risk-high">
          {(bulkMutation.error as Error).message ||
            'Bulk removal failed. No comments were changed.'}
        </div>
      )}
      {rowMutation.isError && (
        <div className="rounded-xl border border-risk-high/40 bg-risk-high/10 px-4 py-3 text-sm text-risk-high">
          {(rowMutation.error as Error).message ||
            'Could not remove that comment.'}
        </div>
      )}

      {isLoading && <AdminLoading label="Loading comments…" />}
      {isError && (
        <AdminError
          message={(error as Error)?.message}
          onRetry={() => void refetch()}
        />
      )}

      {!isLoading && !isError && items.length === 0 && (
        <AdminEmptyState
          icon={MessageSquare}
          title="No comments match these filters"
          description="Try a different status or clear the search. Removed comments remain available for audit under the Removed filter."
        />
      )}

      {!isLoading && !isError && items.length > 0 && (
        <div className="overflow-hidden rounded-2xl border border-scam-line bg-scam-800 shadow-card">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[880px] text-left text-sm">
              <thead>
                <tr className="border-b border-scam-line text-[11px] uppercase tracking-[0.12em] text-scam-muted">
                  <th className="w-10 px-4 py-3">
                    <input
                      type="checkbox"
                      checked={allSelected}
                      onChange={toggleAll}
                      disabled={selectableIds.length === 0}
                      aria-label="Select all removable comments on this page"
                      className="h-4 w-4 accent-trust-500"
                    />
                  </th>
                  <th className="px-3 py-3 font-semibold">Comment</th>
                  <th className="px-3 py-3 font-semibold">Post</th>
                  <th className="px-3 py-3 font-semibold">Status</th>
                  <th className="px-3 py-3 font-semibold">Created</th>
                  <th className="px-4 py-3 text-right font-semibold">Actions</th>
                </tr>
              </thead>
              <tbody>
                {items.map((comment) => (
                  <tr
                    key={comment.id}
                    className="border-b border-scam-line/70 align-top transition last:border-0 hover:bg-scam-750/50"
                  >
                    <td className="px-4 py-3.5">
                      <input
                        type="checkbox"
                        checked={selected.has(comment.id)}
                        onChange={() => toggle(comment.id)}
                        disabled={comment.status === 'removed'}
                        aria-label={`Select comment ${comment.id}`}
                        className="h-4 w-4 accent-trust-500 disabled:opacity-30"
                      />
                    </td>
                    <td className="max-w-md px-3 py-3.5">
                      <p className="line-clamp-2 text-sm leading-relaxed text-scam-text">
                        {comment.body}
                      </p>
                      <div className="mt-1.5 flex flex-wrap items-center gap-1.5 text-[11px] text-scam-dim">
                        <span>u/{comment.authorLabel}</span>
                        <span aria-hidden>·</span>
                        <span>#{comment.id}</span>
                        {comment.isBot && <Badge tone="trust">AI</Badge>}
                        {comment.parentId && (
                          <span>reply to #{comment.parentId}</span>
                        )}
                      </div>
                    </td>
                    <td className="max-w-xs px-3 py-3.5">
                      <Link
                        to={`/forum/${comment.postId}`}
                        className="line-clamp-2 text-xs font-medium text-scam-text hover:text-trust-500 hover:underline"
                      >
                        {comment.postTitle}
                      </Link>
                      {comment.postDeleted && (
                        <div className="mt-1">
                          <StatusBadge status="deleted" />
                        </div>
                      )}
                    </td>
                    <td className="px-3 py-3.5">
                      <StatusBadge status={comment.status} />
                    </td>
                    <td className="whitespace-nowrap px-3 py-3.5 text-xs text-scam-muted">
                      {relativeDate(comment.createdAt)}
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="flex items-center justify-end gap-2">
                        <Link
                          to={`/forum/${comment.postId}#comment-${comment.id}`}
                          className="sr-btn-ghost px-2.5 py-1.5 text-xs"
                          title="Open the comment in its post"
                        >
                          <ExternalLink size={13} /> View
                        </Link>
                        <DangerButton
                          onClick={() =>
                            deleteOne({
                              id: comment.id,
                              postId: comment.postId,
                            })
                          }
                          disabled={
                            comment.status === 'removed' ||
                            rowMutation.isPending
                          }
                          title={
                            comment.status === 'removed'
                              ? 'Already removed'
                              : 'Soft-remove this comment'
                          }
                        >
                          <Trash2 size={13} />
                        </DangerButton>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <PaginationBar
            hasPrev={hasPrev}
            hasNext={!!data?.nextCursor}
            onPrev={goPrev}
            onNext={() => data?.nextCursor && goNext(data.nextCursor)}
            loading={isFetching}
            count={items.length}
          />
        </div>
      )}
    </div>
  );
}
