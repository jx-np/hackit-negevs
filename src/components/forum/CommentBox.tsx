import { useMutation, useQueryClient } from '@tanstack/react-query';
import { LogIn, Send } from 'lucide-react';
import { useState } from 'react';
import { Link } from 'react-router-dom';
import { createComment } from '../../api/comments';
import { useAuth } from '../../context/AuthContext';

interface CommentBoxProps {
  postId: string;
}

/**
 * Comment input, gated behind authentication.
 * Posts comments via the real backend API.
 */
export function CommentBox({ postId }: CommentBoxProps) {
  const { isLoggedIn, user } = useAuth();
  const [value, setValue] = useState('');
  const queryClient = useQueryClient();

  const mutation = useMutation({
    mutationFn: (body: string) => createComment(postId, body),
    onSuccess: () => {
      setValue('');
      // Invalidate queries that might show comment counts or comment lists.
      queryClient.invalidateQueries({ queryKey: ['post', postId] });
      queryClient.invalidateQueries({ queryKey: ['comments', postId] });
      queryClient.invalidateQueries({ queryKey: ['posts'] });
    },
  });

  // Logged-out state: prompt the user to sign in.
  if (!isLoggedIn) {
    return (
      <div className="flex flex-col items-center gap-3 rounded-md border border-dashed border-scam-line bg-scam-750 p-5 text-center sm:flex-row sm:justify-between sm:text-left">
        <p className="text-base text-scam-muted">
          <span className="font-semibold text-scam-text">
            Log in to comment
          </span>{' '}
          and join the discussion.
        </p>
        <Link
          to="/auth"
          className="inline-flex shrink-0 items-center gap-2 rounded-md bg-trust-500 px-5 py-2.5 text-base font-semibold text-white shadow-soft transition hover:bg-trust-600"
        >
          <LogIn size={18} /> Log in
        </Link>
      </div>
    );
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!value.trim() || mutation.isPending) return;
    mutation.mutate(value.trim());
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-2">
      <label htmlFor={`comment-${postId}`} className="sr-only">
        Add a comment
      </label>
      <div className="flex items-start gap-3">
        <span className="grid h-10 w-10 shrink-0 place-items-center rounded-md border border-scam-line bg-scam-750 text-sm font-semibold text-scam-muted">
          {user?.name?.slice(0, 2).toUpperCase() ?? 'ME'}
        </span>
        <textarea
          id={`comment-${postId}`}
          value={value}
          onChange={(e) => setValue(e.target.value)}
          rows={2}
          placeholder="Share your thoughts…"
          className="w-full resize-none rounded-md border border-scam-line bg-scam-750 px-4 py-3 text-base text-scam-text outline-none transition placeholder:text-scam-muted focus:border-trust-500 focus:ring-2 focus:ring-trust-500/30"
        />
      </div>
      <div className="flex items-center justify-between pl-13">
        {mutation.isSuccess ? (
          <span className="text-xs font-medium text-risk-low">
            Comment posted.
          </span>
        ) : mutation.isError ? (
          <span className="text-xs text-risk-high">
            {(mutation.error as Error).message}
          </span>
        ) : (
          <span className="text-xs text-scam-muted">
            Commenting as {user?.name}
          </span>
        )}
        <button
          type="submit"
          disabled={!value.trim() || mutation.isPending}
          className="inline-flex items-center gap-2 rounded-md bg-trust-500 px-5 py-2.5 text-base font-semibold text-white shadow-soft transition hover:bg-trust-600 disabled:opacity-50"
        >
          <Send size={16} /> {mutation.isPending ? 'Posting…' : 'Comment'}
        </button>
      </div>
    </form>
  );
}
