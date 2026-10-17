import { motion } from 'framer-motion';
import {
  BookOpen,
  CreditCard,
  Eye,
  Link2,
  Lock,
  PhoneOff,
  ShieldCheck,
  UserCheck,
  type LucideIcon,
} from 'lucide-react';

interface Tip {
  icon: LucideIcon;
  title: string;
  body: string;
}

const TIPS: Tip[] = [
  {
    icon: PhoneOff,
    title: 'Treat unexpected contact with suspicion',
    body: 'Banks, government agencies and delivery firms will never cold-call or text you asking for passwords, OTPs or payment to "release" a parcel. If in doubt, hang up and call the official number yourself.',
  },
  {
    icon: Link2,
    title: 'Check links before you tap',
    body: 'Hover or long-press a link to preview the real destination. Watch for look-alike domains (paypa1.com, dbs-secure.net). When unsure, type the address in manually instead of clicking.',
  },
  {
    icon: CreditCard,
    title: 'Never pay to receive money',
    body: 'No legitimate prize, job, loan or refund requires you to pay a "fee", "tax" or "deposit" first. Requests for gift cards, crypto or bank transfers to strangers are almost always a scam.',
  },
  {
    icon: Lock,
    title: 'Guard your OTPs and passwords',
    body: 'One-time passwords are the last line of defence on your account. No real staff member will ever ask for them. Use a unique password per site and turn on two-factor authentication.',
  },
  {
    icon: Eye,
    title: 'Slow down when you feel rushed',
    body: 'Scammers manufacture urgency: "act now", "account suspended", "final warning". Pressure is the tell. Take a breath, step away, and verify through an independent channel.',
  },
  {
    icon: UserCheck,
    title: 'Verify who you are dealing with',
    body: 'For marketplace deals, meet in person in a safe spot and avoid paying in advance. For "friends" messaging from a new number, confirm their identity with a question only they would know.',
  },
];

const RED_FLAGS = [
  'Unsolicited calls, texts or emails asking for personal or banking details',
  'Pressure to act immediately or keep the matter secret',
  'Requests for payment via gift cards, crypto, or transfers to a personal account',
  'Deals, prizes or returns that seem too good to be true',
  'Poor spelling, odd phrasing, or an email address that doesn\u2019t match the sender',
  'Links to log-in pages that arrive out of the blue',
];

function TipCard({ tip }: { tip: Tip }) {
  const Icon = tip.icon;
  return (
    <motion.article
      initial={{ opacity: 0, y: 12 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-40px' }}
      transition={{ duration: 0.35, ease: 'easeOut' }}
      className="rounded-2xl border border-scam-line bg-scam-800 shadow-card p-5"
    >
      <span className="sr-tile h-10 w-10">
        <Icon size={20} />
      </span>
      <h3 className="mt-3 text-base font-semibold text-scam-text">
        {tip.title}
      </h3>
      <p className="mt-2 text-sm leading-relaxed text-scam-muted">{tip.body}</p>
    </motion.article>
  );
}

export function StaySafeContent() {
  return (
    <>
      <motion.div
        initial={{ opacity: 0, y: -12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="mb-8 flex items-center gap-3 border-b border-scam-line pb-6"
        >
          <span className="sr-tile h-12 w-12">
            <BookOpen size={24} />
          </span>
          <div>
            <span className="sr-eyebrow">Guides</span>
            <h1 className="mt-1 text-2xl font-bold tracking-tight text-scam-text sm:text-3xl">
              How to Stay Safe
            </h1>
            <p className="mt-1 text-sm text-scam-muted">
              Simple habits that stop most scams before they start.
            </p>
          </div>
        </motion.div>

        <section className="mb-12">
          <h2 className="sr-label mb-4">Core habits</h2>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            {TIPS.map((tip) => (
              <TipCard key={tip.title} tip={tip} />
            ))}
          </div>
        </section>

        <section>
          <h2 className="sr-label mb-4">Common red flags</h2>
          <motion.div
            initial={{ opacity: 0, y: 12 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: '-40px' }}
            transition={{ duration: 0.35, ease: 'easeOut' }}
            className="rounded-lg border border-risk-high/40 bg-risk-high/10 p-5"
          >
            <ul className="flex flex-col gap-3">
              {RED_FLAGS.map((flag) => (
                <li key={flag} className="flex items-start gap-3 text-sm">
                  <ShieldCheck
                    size={16}
                    className="mt-0.5 shrink-0 text-risk-high"
                  />
                  <span className="text-scam-text">{flag}</span>
                </li>
              ))}
            </ul>
          </motion.div>
        </section>
    </>
  );
}

export function StaySafePage() {
  return (
    <div
      className="min-h-screen bg-scam-950 text-scam-text"
    >
      <div className="mx-auto w-full max-w-[900px] px-5 py-10 lg:px-8">
        <StaySafeContent />
      </div>
    </div>
  );
}
