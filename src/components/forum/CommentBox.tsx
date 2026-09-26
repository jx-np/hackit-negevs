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
      <div className="flex flex-col items-center gap-3 rounded-2xl border border-dashed border-slate-300 bg-slate-50 p-5 text-center dark:border-slate-700 dark:bg-slate-800/40 sm:flex-row sm:justify-between sm:text-left">
        <p className="text-base text-slate-600 dark:text-slate-300">
          <span className="font-semibold">Log in to comment</span> and join the
          discussion.
        </p>
        <Link
          to="/auth"
          className="inline-flex shrink-0 items-center gap-2 rounded-xl bg-brand-600 px-5 py-2.5 text-base font-semibold text-white transition hover:bg-brand-700"
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
        <span className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-brand-100 text-sm font-semibold text-brand-700 dark:bg-brand-900/40 dark:text-brand-300">
          {user?.name?.slice(0, 2).toUpperCase() ?? 'ME'}
        </span>
        <textarea
          id={`comment-${postId}`}
          value={value}
          onChange={(e) => setValue(e.target.value)}
          rows={2}
          placeholder="Share your thoughts…"
          className="w-full resize-none rounded-2xl border border-slate-200 bg-white px-4 py-3 text-base outline-none transition placeholder:text-slate-400 focus:border-brand-400 focus:ring-4 focus:ring-brand-100 dark:border-slate-700 dark:bg-slate-900 dark:focus:ring-brand-900/40"
        />
      </div>
      <div className="flex items-center justify-between pl-13">
        {submitted ? (
          <span className="text-sm font-medium text-green-600 dark:text-green-400">
            Comment posted (demo).
          </span>
        ) : (
          <span className="text-sm text-slate-400">
            Commenting as {user?.name}
          </span>
        )}
        <button
          type="submit"
          disabled={!value.trim()}
          className="inline-flex items-center gap-2 rounded-xl bg-brand-600 px-5 py-2.5 text-base font-semibold text-white transition hover:bg-brand-700 disabled:opacity-50"
        >
          <Send size={16} /> Comment
        </button>
      </div>
    </form>
  );
}
