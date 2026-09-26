import { LogIn, Send } from 'lucide-react';
import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

interface CommentBoxProps {
  postId: string;
}

/**
 * Comment input, gated behind authentication.
 *
 * SCAFFOLDED: when logged in, submitting just clears the field and shows a
 * confirmation. Wire this to a real "create comment" API later, e.g.
 * postComment({ postId, body }).
 */
export function CommentBox({ postId }: CommentBoxProps) {
  const { isLoggedIn, user } = useAuth();
  const [value, setValue] = useState('');
  const [submitted, setSubmitted] = useState(false);

  // Logged-out state: prompt the user to sign in.
  if (!isLoggedIn) {
    return (
      <div className="flex flex-col items-center gap-3 border border-dashed border-ink-300 bg-ink-50 p-5 text-center dark:border-ink-700 dark:bg-ink-900/50 sm:flex-row sm:justify-between sm:text-left">
        <p className="text-base text-ink-600 dark:text-ink-300">
          <span className="font-semibold text-ink-900 dark:text-white">
            Log in to comment
          </span>{' '}
          and join the discussion.
        </p>
        <Link
          to="/auth"
          className="inline-flex shrink-0 items-center gap-2 border border-ink-900 bg-ink-900 px-5 py-2.5 text-base font-semibold text-white transition hover:bg-ink-800 dark:border-white dark:bg-white dark:text-ink-900 dark:hover:bg-ink-100"
        >
          <LogIn size={18} /> Log in
        </Link>
      </div>
    );
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!value.trim()) return;
    // Scaffold: pretend to submit. Replace with a real API call.
    console.log('new comment', { postId, body: value });
    setValue('');
    setSubmitted(true);
    setTimeout(() => setSubmitted(false), 2500);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-2">
      <label htmlFor={`comment-${postId}`} className="sr-only">
        Add a comment
      </label>
      <div className="flex items-start gap-3">
        <span className="grid h-10 w-10 shrink-0 place-items-center border border-ink-300 bg-ink-50 font-mono text-sm font-semibold text-ink-700 dark:border-ink-700 dark:bg-ink-800 dark:text-ink-200">
          {user?.name?.slice(0, 2).toUpperCase() ?? 'ME'}
        </span>
        <textarea
          id={`comment-${postId}`}
          value={value}
          onChange={(e) => setValue(e.target.value)}
          rows={2}
          placeholder="Share your thoughts…"
          className="w-full resize-none border border-ink-300 bg-white px-4 py-3 text-base outline-none transition placeholder:text-ink-400 focus:border-safe-500 focus:ring-2 focus:ring-safe-500/30 dark:border-ink-700 dark:bg-ink-900 dark:text-white"
        />
      </div>
      <div className="flex items-center justify-between pl-13">
        {submitted ? (
          <span className="font-mono text-xs font-medium text-safe-700 dark:text-safe-400">
            Comment posted (demo).
          </span>
        ) : (
          <span className="font-mono text-xs text-ink-400">
            Commenting as {user?.name}
          </span>
        )}
        <button
          type="submit"
          disabled={!value.trim()}
          className="inline-flex items-center gap-2 border border-ink-900 bg-ink-900 px-5 py-2.5 text-base font-semibold text-white transition hover:bg-ink-800 disabled:opacity-50 dark:border-white dark:bg-white dark:text-ink-900 dark:hover:bg-ink-100"
        >
          <Send size={16} /> Comment
        </button>
      </div>
    </form>
  );
}
