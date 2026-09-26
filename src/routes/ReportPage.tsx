import { zodResolver } from '@hookform/resolvers/zod';
import { useMutation } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { LogIn, ShieldPlus } from 'lucide-react';
import { useForm } from 'react-hook-form';
import { Link, useNavigate } from 'react-router-dom';
import { createPost } from '../api/posts';
import { useAuth } from '../context/AuthContext';
import { useTags } from '../hooks/useTags';
import type { RiskLevel } from '../types';
import { reportSchema, type ReportValues } from './reportSchema';

export function ReportPage() {
  const { isLoggedIn, user } = useAuth();
  const navigate = useNavigate();
  const { data: tags } = useTags();

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<ReportValues>({
    resolver: zodResolver(reportSchema),
    defaultValues: { risk: 'high', imageUrl: '' },
  });

  const create = useMutation({
    mutationFn: (values: ReportValues) => {
      const risk: RiskLevel =
        values.risk === 'none' ? null : (values.risk as 'high' | 'medium');
      return createPost({
        title: values.title,
        excerpt: values.excerpt,
        tagId: values.tagId,
        risk,
        imageUrl: values.imageUrl || null,
        authorName: user?.name ?? 'Anonymous',
      });
    },
    onSuccess: (post) => navigate(`/forum/${post.id}`),
  });

  // Login gate — mirrors the comment / number-report gating.
  if (!isLoggedIn) {
    return (
      <div className="min-h-screen bg-paper dark:bg-ink-950">
        <div className="mx-auto w-full max-w-2xl px-6 py-16 text-center">
          <span className="mx-auto grid h-16 w-16 place-items-center bg-ink-900 text-white dark:bg-white dark:text-ink-900">
            <ShieldPlus size={30} />
          </span>
          <h1 className="mt-6 font-display text-3xl font-bold text-ink-900 dark:text-white">
            Log in to report a scam
          </h1>
          <p className="mx-auto mt-3 max-w-md text-lg text-ink-600 dark:text-ink-400">
            You need an account to add a report to the community registry.
          </p>
          <Link
            to="/auth"
            className="mt-8 inline-flex items-center gap-2 border border-ink-900 bg-ink-900 px-7 py-3.5 text-base font-semibold text-white transition hover:bg-ink-800 dark:border-white dark:bg-white dark:text-ink-900 dark:hover:bg-ink-100"
          >
            <LogIn size={18} /> Log in to continue
          </Link>
        </div>
      </div>
    );
  }

  const inputCls =
    'w-full border bg-white px-4 py-3 text-base text-ink-900 outline-none transition placeholder:text-ink-400 focus:ring-2 dark:bg-ink-900 dark:text-white';
  const okBorder =
    'border-ink-300 focus:border-safe-500 focus:ring-safe-500/30 dark:border-ink-700';
  const errBorder = 'border-risk-500 focus:border-risk-500 focus:ring-risk-500/30';

  return (
    <div className="min-h-screen bg-paper dark:bg-ink-950">
      <div className="mx-auto w-full max-w-2xl px-6 py-12">
        <motion.div
          initial={{ opacity: 0, y: -12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="mb-8 flex items-center gap-4 border-b border-ink-200 pb-6 dark:border-ink-800"
        >
          <span className="grid h-14 w-14 place-items-center bg-ink-900 text-white dark:bg-white dark:text-ink-900">
            <ShieldPlus size={26} />
          </span>
          <div>
            <span className="ia-label text-safe-700 dark:text-safe-400">
              Contribute
            </span>
            <h1 className="mt-1 font-display text-3xl font-bold tracking-tight text-ink-900 dark:text-white sm:text-4xl">
              Report a scam
            </h1>
          </div>
        </motion.div>

        <form
          onSubmit={handleSubmit((v) => create.mutate(v))}
          className="space-y-6"
          noValidate
        >
          {/* Title */}
          <Field label="Title" error={errors.title?.message}>
            <input
              {...register('title')}
              placeholder="e.g. Fake bank SMS asking to verify my account"
              className={`${inputCls} ${errors.title ? errBorder : okBorder}`}
            />
          </Field>

          {/* Summary */}
          <Field label="What happened?" error={errors.excerpt?.message}>
            <textarea
              {...register('excerpt')}
              rows={5}
              placeholder="Describe the scam, the red flags you noticed, and any details that help others recognize it."
              className={`${inputCls} resize-none ${
                errors.excerpt ? errBorder : okBorder
              }`}
            />
          </Field>

          {/* Category + Risk */}
          <div className="grid gap-6 sm:grid-cols-2">
            <Field label="Category" error={errors.tagId?.message}>
              <select
                {...register('tagId')}
                defaultValue=""
                className={`${inputCls} ${errors.tagId ? errBorder : okBorder}`}
              >
                <option value="" disabled>
                  Choose a category…
                </option>
                {tags?.map((t) => (
                  <option key={t.id} value={t.id}>
                    {t.name}
                  </option>
                ))}
              </select>
            </Field>

            <Field label="Risk level" error={errors.risk?.message}>
              <select
                {...register('risk')}
                className={`${inputCls} ${okBorder}`}
              >
                <option value="high">High risk</option>
                <option value="medium">Caution</option>
                <option value="none">Not sure</option>
              </select>
            </Field>
          </div>

          {/* Image URL (optional) */}
          <Field
            label="Screenshot URL (optional)"
            error={errors.imageUrl?.message}
          >
            <input
              {...register('imageUrl')}
              placeholder="https://…"
              className={`${inputCls} ${
                errors.imageUrl ? errBorder : okBorder
              }`}
            />
          </Field>

          {create.isError && (
            <p className="border border-risk-500 bg-risk-50 px-4 py-3 font-mono text-sm text-risk-700 dark:bg-risk-500/10 dark:text-risk-500">
              {(create.error as Error).message}
            </p>
          )}

          <div className="flex items-center justify-between border-t border-ink-200 pt-6 dark:border-ink-800">
            <span className="font-mono text-xs text-ink-400">
              Posting as {user?.name}
            </span>
            <button
              type="submit"
              disabled={isSubmitting || create.isPending}
              className="inline-flex items-center gap-2 border border-ink-900 bg-ink-900 px-7 py-3.5 text-base font-semibold text-white transition hover:bg-ink-800 disabled:opacity-50 dark:border-white dark:bg-white dark:text-ink-900 dark:hover:bg-ink-100"
            >
              <ShieldPlus size={18} />
              {create.isPending ? 'Submitting…' : 'Submit report'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

function Field({
  label,
  error,
  children,
}: {
  label: string;
  error?: string;
  children: React.ReactNode;
}) {
  return (
    <div>
      <label className="mb-1.5 block font-mono text-xs font-medium uppercase tracking-wider text-ink-600 dark:text-ink-400">
        {label}
      </label>
      {children}
      {error && (
        <p className="mt-1 font-mono text-xs text-risk-600 dark:text-risk-500">
          {error}
        </p>
      )}
    </div>
  );
}
