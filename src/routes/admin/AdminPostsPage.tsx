import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  ExternalLink,
  FileText,
  Search,
  Trash2,
  X,
} from 'lucide-react';
import { useState } from 'react';
import { Link } from 'react-router-dom';
import { bulkDeletePosts, getAdminPosts } from '../../api/admin';
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
import type { AdminPostStatus, BulkDeleteResult } from '../../types';

const STATUS_OPTIONS: Array<{ value: AdminPostStatus; label: string }> = [
  { value: 'all', label: 'All posts' },
  { value: 'visible', label: 'Visible' },
  { value: 'unverified', label: 'Unverified' },
  { value: 'reviewed', label: 'Reviewed' },
  { value: 'disputed', label: 'Disputed' },
  { value: 'hidden', label: 'Hidden' },
  { value: 'removed', label: 'Removed' },
  { value: 'deleted', label: 'Deleted' },
];

export function AdminPostsPage() {
  const queryClient = useQueryClient();
  const [status, setStatus] = useState<AdminPostStatus>('all');
  const [search, setSearch] = useState('');
  const q = useDebounce(search, 350);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [lastResult, setLastResult] = useState<BulkDeleteResult | null>(null);
  const { cursor, goNext, goPrev, reset, hasPrev } = useCursorPagination();

  const { data, isLoading, isError, error, refetch, isFetching } = useQuery({
    queryKey: ['admin', 'posts', status, q, cursor],
    queryFn: () => getAdminPosts({ status, q, cursor }),
  });

  const items = data?.items ?? [];
  const selectableIds = items
    .filter((p) => !p.isDeleted)
    .map((p) => p.id);
  const allSelected =
    selectableIds.length > 0 && selectableIds.every((id) => selected.has(id));

  function invalidate() {
    queryClient.invalidateQueries({ queryKey: ['admin'] });
    queryClient.invalidateQueries({ queryKey: ['posts'] });
    queryClient.invalidateQueries({ queryKey: ['myPosts'] });
  }

  const bulkMutation = useMutation({
    mutationFn: (ids: string[]) => bulkDeletePosts(ids),
    onSuccess: (result) => {
      setLastResult(result);
      setSelected(new Set());
      invalidate();
    },
  });

  const rowMutation = useMutation({
    mutationFn: (id: string) => bulkDeletePosts([id]),
    onSuccess: (result) => {
      setLastResult(result);
      setSelected((prev) => {
        const next = new Set(prev);
        for (const id of result.deleted) next.delete(id);
        return next;
      });
      invalidate();
    },
  });

  function changeStatus(next: AdminPostStatus) {
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
        `Delete ${selected.size} ${
          selected.size === 1 ? 'post' : 'posts'
        }? This is a soft delete and can be reviewed later.`,
      )
    ) {
      return;
    }
    bulkMutation.mutate([...selected]);
  }

  function deleteOne(id: string) {
    if (!window.confirm('Delete this post? This is a soft delete.')) return;
    rowMutation.mutate(id);
  }

  return (
    <div className="space-y-4">
      <div className="rounded-2xl border border-scam-line bg-scam-800 p-4 shadow-card">
        <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <h2 className="font-display text-lg font-bold text-scam-text">
              All posts
            </h2>
            <p className="mt-0.5 text-sm text-scam-muted">
              Every submission, including hidden, removed, and soft-deleted
              posts.
            </p>
          </div>
          <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
            <div className="relative">
              <Search
                size={15}
                className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-scam-dim"
                aria-hidden
              />
              <label htmlFor="post-search" className="sr-only">
                Search posts
              </label>
              <input
                id="post-search"
                type="search"
                value={search}
                onChange={(e) => changeSearch(e.target.value)}
                placeholder="Search title or body…"
                className={`${ADMIN_INPUT_CLASS} w-full pl-9 sm:w-64`}
              />
            </div>
            <label htmlFor="post-status" className="sr-only">
              Post status
            </label>
            <select
              id="post-status"
              value={status}
              onChange={(e) => changeStatus(e.target.value as AdminPostStatus)}
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
            {lastResult.deletedCount === 1 ? 'post' : 'posts'} deleted
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
              {bulkMutation.isPending ? 'Deleting…' : 'Delete selected'}
            </DangerButton>
          </div>
        </div>
      )}

      {bulkMutation.isError && (
        <div className="rounded-xl border border-risk-high/40 bg-risk-high/10 px-4 py-3 text-sm text-risk-high">
          {(bulkMutation.error as Error).message ||
            'Bulk deletion failed. No posts were changed.'}
        </div>
      )}
      {rowMutation.isError && (
        <div className="rounded-xl border border-risk-high/40 bg-risk-high/10 px-4 py-3 text-sm text-risk-high">
          {(rowMutation.error as Error).message ||
            'Could not delete that post.'}
        </div>
      )}

      {isLoading && <AdminLoading label="Loading posts…" />}
      {isError && (
        <AdminError
          message={(error as Error)?.message}
          onRetry={() => void refetch()}
        />
      )}

      {!isLoading && !isError && items.length === 0 && (
        <AdminEmptyState
          icon={FileText}
          title="No posts match these filters"
          description="Try a different status or clear the search. Soft-deleted posts remain available here under the Deleted filter."
        />
      )}

      {!isLoading && !isError && items.length > 0 && (
        <div className="overflow-hidden rounded-2xl border border-scam-line bg-scam-800 shadow-card">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[900px] text-left text-sm">
              <thead>
                <tr className="border-b border-scam-line text-[11px] uppercase tracking-[0.12em] text-scam-muted">
                  <th className="w-10 px-4 py-3">
                    <input
                      type="checkbox"
                      checked={allSelected}
                      onChange={toggleAll}
                      disabled={selectableIds.length === 0}
                      aria-label="Select all deletable posts on this page"
                      className="h-4 w-4 accent-trust-500"
                    />
                  </th>
                  <th className="px-3 py-3 font-semibold">Post</th>
                  <th className="px-3 py-3 font-semibold">Status</th>
                  <th className="px-3 py-3 font-semibold">Activity</th>
                  <th className="px-3 py-3 font-semibold">Created</th>
                  <th className="px-4 py-3 text-right font-semibold">Actions</th>
                </tr>
              </thead>
              <tbody>
                {items.map((post) => (
                  <tr
                    key={post.id}
                    className="border-b border-scam-line/70 align-top transition last:border-0 hover:bg-scam-750/50"
                  >
                    <td className="px-4 py-3.5">
                      <input
                        type="checkbox"
                        checked={selected.has(post.id)}
                        onChange={() => toggle(post.id)}
                        disabled={post.isDeleted}
                        aria-label={`Select post ${post.id}`}
                        className="h-4 w-4 accent-trust-500 disabled:opacity-30"
                      />
                    </td>
                    <td className="max-w-md px-3 py-3.5">
                      <Link
                        to={`/forum/${post.id}`}
                        className="font-semibold text-scam-text hover:text-trust-500 hover:underline"
                      >
                        {post.title}
                      </Link>
                      <p className="mt-0.5 line-clamp-2 text-xs leading-relaxed text-scam-muted">
                        {post.body}
                      </p>
                      <div className="mt-1.5 flex flex-wrap items-center gap-1.5 text-[11px] text-scam-dim">
                        <span>u/{post.authorLabel}</span>
                        <span aria-hidden>·</span>
                        <span>#{post.id}</span>
                        {post.categorySlug && (
                          <>
                            <span aria-hidden>·</span>
                            <span>{post.categorySlug}</span>
                          </>
                        )}
                        {post.tags.slice(0, 3).map((tag) => (
                          <Badge key={tag}>#{tag}</Badge>
                        ))}
                      </div>
                    </td>
                    <td className="px-3 py-3.5">
                      <StatusBadge
                        status={
                          post.isDeleted ? 'deleted' : post.reviewStatus
                        }
                      />
                    </td>
                    <td className="px-3 py-3.5">
                      <div className="flex flex-col gap-0.5 text-xs text-scam-muted">
                        <span className="sr-nums">
                          {post.commentCount} comments
                        </span>
                        <span className="sr-nums">
                          +{post.upCount} / −{post.downCount}
                        </span>
                      </div>
                    </td>
                    <td className="whitespace-nowrap px-3 py-3.5 text-xs text-scam-muted">
                      {relativeDate(post.createdAt)}
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="flex items-center justify-end gap-2">
                        <Link
                          to={`/forum/${post.id}`}
                          className="sr-btn-ghost px-2.5 py-1.5 text-xs"
                          title="Open public post"
                        >
                          <ExternalLink size={13} /> View
                        </Link>
                        <DangerButton
                          onClick={() => deleteOne(post.id)}
                          disabled={post.isDeleted || rowMutation.isPending}
                          title={
                            post.isDeleted
                              ? 'Already deleted'
                              : 'Soft-delete this post'
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
