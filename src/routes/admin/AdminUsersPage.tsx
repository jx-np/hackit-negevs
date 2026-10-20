import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Search, ShieldAlert, UserCog, X } from 'lucide-react';
import { useState } from 'react';
import { getAdminUsers, updateUserRole } from '../../api/admin';
import {
  ADMIN_INPUT_CLASS,
  ADMIN_SELECT_CLASS,
  AdminEmptyState,
  AdminError,
  AdminLoading,
  Badge,
  PaginationBar,
  StatusBadge,
} from '../../components/admin/AdminUi';
import { useAuth } from '../../context/AuthContext';
import { useCursorPagination } from '../../hooks/useCursorPagination';
import { useDebounce } from '../../hooks/useDebounce';
import { relativeDate } from '../../lib/date';
import { ROLE_LABELS } from '../../lib/roles';
import type { UserRole } from '../../types';

const ROLE_OPTIONS: UserRole[] = ['resident', 'helper', 'moderator', 'admin'];

export function AdminUsersPage() {
  const { user, isAdmin, refreshUser } = useAuth();
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [role, setRole] = useState<UserRole | 'all'>('all');
  const q = useDebounce(search, 350);
  const { cursor, goNext, goPrev, reset, hasPrev } = useCursorPagination();

  const { data, isLoading, isError, error, refetch, isFetching } = useQuery({
    queryKey: ['admin', 'users', q, role, cursor],
    queryFn: () => getAdminUsers({ q, role, cursor }),
    enabled: isAdmin,
  });

  const roleMutation = useMutation({
    mutationFn: ({ id, nextRole }: { id: string; nextRole: UserRole }) =>
      updateUserRole(id, nextRole),
    onSuccess: (updated) => {
      queryClient.invalidateQueries({ queryKey: ['admin'] });
      // If an administrator changes their own role, refresh the session so the
      // console reflects the new permissions immediately.
      if (updated.id === user?.id) {
        void refreshUser();
      }
    },
  });

  function changeSearch(next: string) {
    setSearch(next);
    reset();
  }

  function changeRoleFilter(next: UserRole | 'all') {
    setRole(next);
    reset();
  }

  function changeRole(id: string, displayName: string, current: UserRole, next: UserRole) {
    if (next === current) return;
    const ok = window.confirm(
      `Change ${displayName}'s role from ${ROLE_LABELS[current]} to ${
        ROLE_LABELS[next]
      }?\n\nTheir refresh sessions will be revoked. The new role takes effect within about 15 minutes.`,
    );
    if (!ok) return;
    roleMutation.mutate({ id, nextRole: next });
  }

  if (!isAdmin) {
    return (
      <AdminEmptyState
        icon={ShieldAlert}
        title="Administrator access required"
        description="Moderators can review content and reports, but only administrators can list accounts or change roles."
      />
    );
  }

  const items = data?.items ?? [];

  return (
    <div className="space-y-4">
      <div className="rounded-2xl border border-scam-line bg-scam-800 p-4 shadow-card">
        <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <h2 className="font-display text-lg font-bold text-scam-text">
              Users &amp; roles
            </h2>
            <p className="mt-0.5 text-sm text-scam-muted">
              Promote or demote accounts. Emails are only visible to
              administrators.
            </p>
          </div>
          <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
            <div className="relative">
              <Search
                size={15}
                className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-scam-dim"
                aria-hidden
              />
              <label htmlFor="user-search" className="sr-only">
                Search users
              </label>
              <input
                id="user-search"
                type="search"
                value={search}
                onChange={(e) => changeSearch(e.target.value)}
                placeholder="Search email or name…"
                className={`${ADMIN_INPUT_CLASS} w-full pl-9 sm:w-64`}
              />
            </div>
            <label htmlFor="user-role" className="sr-only">
              Filter by role
            </label>
            <select
              id="user-role"
              value={role}
              onChange={(e) =>
                changeRoleFilter(e.target.value as UserRole | 'all')
              }
              className={ADMIN_SELECT_CLASS}
            >
              <option value="all">All roles</option>
              {ROLE_OPTIONS.map((r) => (
                <option key={r} value={r}>
                  {ROLE_LABELS[r]}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {roleMutation.isError && (
        <div
          role="alert"
          className="flex items-start gap-3 rounded-xl border border-risk-high/40 bg-risk-high/10 px-4 py-3 text-sm text-risk-high"
        >
          <span className="flex-1">
            {(roleMutation.error as Error).message ||
              'Could not change this role.'}
            {roleMutation.error instanceof Error &&
              roleMutation.error.message.toLowerCase().includes('admin') && (
                <span className="mt-1 block text-xs opacity-80">
                  The deployment must keep at least one administrator.
                </span>
              )}
          </span>
          <button
            type="button"
            onClick={() => roleMutation.reset()}
            className="grid h-6 w-6 place-items-center rounded hover:bg-risk-high/10"
            aria-label="Dismiss error"
          >
            <X size={14} />
          </button>
        </div>
      )}

      {isLoading && <AdminLoading label="Loading accounts…" />}
      {isError && (
        <AdminError
          message={(error as Error)?.message}
          onRetry={() => void refetch()}
        />
      )}

      {!isLoading && !isError && items.length === 0 && (
        <AdminEmptyState
          icon={UserCog}
          title="No accounts match these filters"
          description="Try a different role or clear the search."
        />
      )}

      {!isLoading && !isError && items.length > 0 && (
        <div className="overflow-hidden rounded-2xl border border-scam-line bg-scam-800 shadow-card">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[820px] text-left text-sm">
              <thead>
                <tr className="border-b border-scam-line text-[11px] uppercase tracking-[0.12em] text-scam-muted">
                  <th className="px-4 py-3 font-semibold">Account</th>
                  <th className="px-3 py-3 font-semibold">Current role</th>
                  <th className="px-3 py-3 font-semibold">Change role</th>
                  <th className="px-3 py-3 font-semibold">Locale</th>
                  <th className="px-4 py-3 font-semibold">Joined</th>
                </tr>
              </thead>
              <tbody>
                {items.map((account) => {
                  const isSelf = account.id === user?.id;
                  const pending =
                    roleMutation.isPending &&
                    roleMutation.variables?.id === account.id;
                  return (
                    <tr
                      key={account.id}
                      className="border-b border-scam-line/70 align-middle transition last:border-0 hover:bg-scam-750/50"
                    >
                      <td className="px-4 py-3.5">
                        <div className="flex items-center gap-2">
                          <p className="font-semibold text-scam-text">
                            {account.displayName}
                          </p>
                          {isSelf && <Badge tone="trust">You</Badge>}
                          {account.isBot && <Badge tone="violet">AI bot</Badge>}
                        </div>
                        <p className="mt-0.5 text-xs text-scam-muted">
                          {account.email ?? 'No email address'}
                        </p>
                        <p className="mt-0.5 text-[11px] text-scam-dim">
                          ID #{account.id}
                        </p>
                      </td>
                      <td className="px-3 py-3.5">
                        <StatusBadge status={account.role} />
                      </td>
                      <td className="px-3 py-3.5">
                        <label className="sr-only" htmlFor={`role-${account.id}`}>
                          Role for {account.displayName}
                        </label>
                        <select
                          id={`role-${account.id}`}
                          value={account.role}
                          disabled={pending}
                          onChange={(e) =>
                            changeRole(
                              account.id,
                              account.displayName,
                              account.role,
                              e.target.value as UserRole,
                            )
                          }
                          className={`${ADMIN_SELECT_CLASS} py-1.5 text-xs disabled:opacity-50`}
                        >
                          {ROLE_OPTIONS.map((r) => (
                            <option key={r} value={r}>
                              {ROLE_LABELS[r]}
                            </option>
                          ))}
                        </select>
                        {pending && (
                          <p className="mt-1 text-[11px] text-scam-muted">
                            Saving…
                          </p>
                        )}
                      </td>
                      <td className="px-3 py-3.5 text-xs text-scam-muted">
                        {account.locale ?? '—'}
                      </td>
                      <td className="whitespace-nowrap px-4 py-3.5 text-xs text-scam-muted">
                        {relativeDate(account.createdAt)}
                      </td>
                    </tr>
                  );
                })}
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
