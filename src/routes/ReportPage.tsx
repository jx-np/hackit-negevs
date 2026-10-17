import { zodResolver } from '@hookform/resolvers/zod';
import { useMutation } from '@tanstack/react-query';
import { motion } from 'framer-motion';
import { LogIn, ShieldPlus } from 'lucide-react';
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { Link, useNavigate } from 'react-router-dom';
import { createPost } from '../api/posts';
import {
  MediaPicker,
  type PickedImage,
} from '../components/report/MediaPicker';
import { useAuth } from '../context/AuthContext';
import { reportSchema, todayISO, type ReportValues } from './reportSchema';

export function ReportPage() {
  const { isLoggedIn, user } = useAuth();
  const navigate = useNavigate();

  // Media is handled outside RHF (each image uploads + gets redacted async).
  const [images, setImages] = useState<PickedImage[]>([]);
  const imagesProcessing = images.some((i) => i.status === 'processing');
  const readyUploadIds = images
    .filter((i) => i.status === 'ready')
    .map((i) => i.uploadId);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<ReportValues>({
    resolver: zodResolver(reportSchema),
    defaultValues: { incidentDate: todayISO() },
  });

  const create = useMutation({
    mutationFn: (values: ReportValues) => {
      return createPost({
        title: values.title,
        excerpt: values.excerpt,
        risk: null,
        uploadIds: readyUploadIds,
        incidentDate: values.incidentDate,
        authorName: user?.name ?? 'Anonymous',
        authorId: user?.id ?? '',
      });
    },
    onSuccess: (post) => navigate(`/forum/${post.id}`),
  });

  // Login gate — mirrors the comment / number-report gating. Reachable only
  // if someone hits /report directly without signing in (incl. demo user).
  if (!isLoggedIn) {
    return (
      <div className="min-h-screen bg-scam-950 text-scam-text">
        <div className="mx-auto w-full max-w-2xl px-5 py-16 lg:px-8">
          <div className="sr-surface px-6 py-12 text-center sm:px-10">
            <span className="sr-tile mx-auto h-16 w-16">
              <ShieldPlus size={30} />
            </span>
            <h1 className="mt-6 text-2xl font-bold tracking-tight text-scam-text sm:text-3xl">
              Log in to report a scam
            </h1>
            <p className="mx-auto mt-3 max-w-md text-base leading-relaxed text-scam-muted">
              You need an account to add a report to the community registry — or
              continue as a demo user.
            </p>
            <Link
              to="/auth"
              className="sr-btn-primary sr-focus mt-8 px-6 py-3 text-base"
            >
              <LogIn size={18} /> Log in to continue
            </Link>
          </div>
        </div>
      </div>
    );
  }

  const inputCls =
    'w-full rounded-lg border bg-scam-750 px-4 py-3 text-base text-scam-text outline-none transition placeholder:text-scam-muted focus:ring-2 [color-scheme:light] dark:[color-scheme:dark]';
  const okBorder =
    'border-scam-line focus:border-trust-500 focus:ring-trust-500/30';
  const errBorder =
    'border-risk-high focus:border-risk-high focus:ring-risk-high/30';

  return (
    <div className="min-h-screen bg-scam-950 text-scam-text">
      <div className="mx-auto w-full max-w-2xl px-5 py-10 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: -12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="mb-8 flex items-center gap-3 border-b border-scam-line pb-6"
        >
          <span className="sr-tile h-12 w-12">
            <ShieldPlus size={24} />
          </span>
          <div>
            <span className="sr-eyebrow">Contribute</span>
            <h1 className="mt-1 text-2xl font-bold tracking-tight text-scam-text sm:text-3xl">
              Report a scam
            </h1>
            <p className="mt-1 text-sm text-scam-muted">
              Share what happened so the community can recognize it too.
            </p>
          </div>
        </motion.div>

        <form
          onSubmit={handleSubmit((v) => create.mutate(v))}
          className="sr-surface space-y-6 p-6 sm:p-7"
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

          {/* Incident date */}
          <Field label="When did it happen?" error={errors.incidentDate?.message}>
            <input
              type="date"
              max={todayISO()}
              {...register('incidentDate')}
              className={`${inputCls} ${
                errors.incidentDate ? errBorder : okBorder
              }`}
            />
          </Field>

          {/* Description */}
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

          {/* Media picker */}
          <Field label="Evidence (optional)">
            <MediaPicker value={images} onChange={setImages} />
            {imagesProcessing && (
              <p className="mt-2 text-xs text-scam-muted">
                Waiting for screenshots to finish redaction before publishing.
              </p>
            )}
          </Field>

          {create.isError && (
            <p className="rounded-lg border border-risk-high/40 bg-risk-high/10 px-4 py-3 text-sm text-risk-high">
              {(create.error as Error).message}
            </p>
          )}

          <div className="flex flex-wrap items-center justify-between gap-4 border-t border-scam-line pt-6">
            <span className="text-xs text-scam-muted">
              Posting as {user?.name}
            </span>
            <button
              type="submit"
              disabled={isSubmitting || create.isPending || imagesProcessing}
              className="sr-btn-primary sr-focus px-6 py-3 text-base disabled:cursor-not-allowed disabled:opacity-50"
            >
              <ShieldPlus size={18} />
              {create.isPending
                ? 'Submitting…'
                : imagesProcessing
                  ? 'Redacting…'
                  : 'Submit report'}
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
      <label className="sr-label mb-1.5 block">{label}</label>
      {children}
      {error && (
        <p className="mt-1.5 text-xs font-medium text-risk-high">{error}</p>
      )}
    </div>
  );
}
