import { motion } from 'framer-motion';
import {
  AlertTriangle,
  ArrowLeft,
  Ban,
  Flag,
  Megaphone,
  MessageSquareWarning,
  ShieldAlert,
  UserX,
} from 'lucide-react';
import { Link } from 'react-router-dom';

/**
 * Report a User — moderation on ScamWatch is content-based: reports are raised
 * against the specific post or comment that broke the rules, not against an
 * account in the abstract. This page explains that real workflow and routes
 * people to the forum where the per-post / per-comment flag action lives,
 * rather than presenting a fake account-report form with no backend behind it.
 */
const REASONS: { icon: typeof Flag; label: string; hint: string }[] = [
  {
    icon: Megaphone,
    label: 'Spam',
    hint: 'Repeated, bulk, or promotional content that clutters the forum.',
  },
  {
    icon: ShieldAlert,
    label: 'Harmful',
    hint: 'Harassment, threats, or content that puts someone at risk.',
  },
  {
    icon: MessageSquareWarning,
    label: 'Misinformation',
    hint: 'False or misleading claims presented as fact.',
  },
  {
    icon: UserX,
    label: 'Personal information',
    hint: 'Private details shared without consent (doxxing).',
  },
  {
    icon: Ban,
    label: 'Other',
    hint: 'Anything else that breaks the community rules.',
  },
];

const STEPS = [
  'Open the post or comment from the user you want to report.',
  'Use the \u22ef menu on that post or comment and choose \u201cReport\u201d.',
  'Pick the reason that best fits, then submit.',
  'Our moderators review every flag and act on the account if needed.',
];

export function ReportUserPage() {
  return (
    <div
      className="min-h-screen bg-scam-950 text-scam-text"
    >
      <div className="mx-auto w-full max-w-[900px] px-5 py-10 lg:px-8">
        <ReportUserContent />
      </div>
    </div>
  );
}

/**
 * Inner content for the Report a User page, without the full-page wrapper, so
 * it can also be rendered inline inside the forum feed panel.
 */
export function ReportUserContent() {
  return (
    <>
      <motion.div
          initial={{ opacity: 0, y: -12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="mb-8 flex items-center gap-3 border-b border-scam-line pb-6"
        >
          <span className="sr-tile h-12 w-12">
            <UserX size={24} />
          </span>
          <div className="min-w-0">
            <span className="sr-eyebrow">Community</span>
            <h1 className="mt-1 text-2xl font-bold tracking-tight text-scam-text sm:text-3xl">
              Report a User
            </h1>
            <p className="mt-1 text-sm text-scam-muted">
              Flag an account for abuse, spam, or impersonation.
            </p>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.35, ease: 'easeOut' }}
          className="mb-6 flex items-start gap-3 rounded-lg border border-trust-500/30 bg-trust-500/5 px-4 py-4 text-sm leading-relaxed text-trust-100"
        >
          <AlertTriangle size={18} className="mt-0.5 shrink-0 text-trust-300" />
          <p>
            Reports on ScamWatch are tied to a specific post or comment, which
            gives moderators the exact context they need to act. To report
            someone, flag the content where the behaviour happened &mdash;
            repeated or serious flags lead to action on the account.
          </p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.35, ease: 'easeOut', delay: 0.05 }}
          className="mb-6 rounded-2xl border border-scam-line bg-scam-800 shadow-card p-6"
        >
          <h2 className="flex items-center gap-2 text-base font-semibold text-scam-text">
            <Flag size={18} className="text-trust-400" /> How to report someone
          </h2>
          <ol className="mt-4 space-y-3">
            {STEPS.map((step, i) => (
              <li key={i} className="flex gap-3 text-sm text-scam-muted">
                <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full border border-trust-500/40 bg-trust-500/10 text-xs font-semibold text-trust-300">
                  {i + 1}
                </span>
                <span className="pt-0.5">{step}</span>
              </li>
            ))}
          </ol>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.35, ease: 'easeOut', delay: 0.1 }}
          className="mb-8 rounded-2xl border border-scam-line bg-scam-800 shadow-card p-6"
        >
          <h2 className="text-base font-semibold text-scam-text">
            What you can report
          </h2>
          <p className="mt-1 text-sm text-scam-muted">
            These are the reasons moderators recognise when reviewing a flag.
          </p>
          <ul className="mt-4 grid gap-3 sm:grid-cols-2">
            {REASONS.map(({ icon: Icon, label, hint }) => (
              <li
                key={label}
                className="flex items-start gap-3 rounded-md border border-scam-line bg-scam-750 p-3"
              >
                <span className="sr-tile h-9 w-9 shrink-0">
                  <Icon size={18} />
                </span>
                <div className="min-w-0">
                  <p className="text-sm font-semibold text-scam-text">{label}</p>
                  <p className="mt-0.5 text-xs leading-relaxed text-scam-muted">
                    {hint}
                  </p>
                </div>
              </li>
            ))}
          </ul>
        </motion.div>

        <div className="flex flex-wrap items-center gap-3">
          <Link
            to="/forum"
            className="inline-flex items-center gap-2 rounded-md bg-trust-500 px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-trust-600"
          >
            <ArrowLeft size={16} /> Go to the forum
          </Link>
          <Link
            to="/help"
            className="inline-flex items-center gap-2 rounded-md border border-scam-line px-5 py-2.5 text-sm font-semibold text-scam-text transition hover:border-trust-500/50 hover:text-trust-400"
          >
            Visit the Help Center
          </Link>
        </div>
    </>
  );
}
