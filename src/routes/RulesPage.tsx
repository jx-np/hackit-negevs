import { motion } from 'framer-motion';
import {
  Ban,
  CheckCircle2,
  EyeOff,
  Heart,
  MessageSquare,
  ScrollText,
  ShieldAlert,
  XCircle,
  type LucideIcon,
} from 'lucide-react';

interface Rule {
  icon: LucideIcon;
  title: string;
  body: string;
}

const RULES: Rule[] = [
  {
    icon: Heart,
    title: 'Be respectful',
    body: 'Treat other members with courtesy, especially victims sharing a painful experience. No harassment, hate speech, personal attacks or blaming people for being scammed.',
  },
  {
    icon: ShieldAlert,
    title: 'Report scams, not people',
    body: 'This forum is for documenting scams and tactics. Do not post accusations against named private individuals without evidence. Use "Report a User" for members who break the rules.',
  },
  {
    icon: EyeOff,
    title: 'Protect personal information',
    body: 'Never share your own or anyone else\u2019s private data: full names, home addresses, ID numbers, bank details or phone numbers. Redact screenshots before posting.',
  },
  {
    icon: MessageSquare,
    title: 'Keep posts clear and on-topic',
    body: 'Give your post a descriptive title, explain what happened, and tag it with the right category so others can find and learn from it.',
  },
];

interface DoDont {
  label: string;
  good: boolean;
}

const DOS_AND_DONTS: DoDont[] = [
  { label: 'Describe the scam tactic, channel and amount involved', good: true },
  { label: 'Blur names, numbers and account details in screenshots', good: true },
  { label: 'Add the correct category tag to your report', good: true },
  { label: 'Search first to avoid duplicate reports', good: true },
  { label: 'Post real contact details of a suspected scammer', good: false },
  { label: 'Share referral links, ads or promotional spam', good: false },
  { label: 'Give financial, legal or medical advice as fact', good: false },
  { label: 'Repost the same scam across many categories', good: false },
];

function RuleCard({ rule }: { rule: Rule }) {
  const Icon = rule.icon;
  return (
    <motion.article
      initial={{ opacity: 0, y: 12 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-40px' }}
      transition={{ duration: 0.35, ease: 'easeOut' }}
      className="rounded-lg border border-scam-line bg-scam-800 p-5"
    >
      <span className="sr-tile h-10 w-10">
        <Icon size={20} />
      </span>
      <h3 className="mt-3 text-base font-semibold text-scam-text">
        {rule.title}
      </h3>
      <p className="mt-2 text-sm leading-relaxed text-scam-muted">{rule.body}</p>
    </motion.article>
  );
}

export function RulesContent() {
  return (
    <>
      <motion.div
          initial={{ opacity: 0, y: -12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="mb-8 flex items-center gap-3 border-b border-scam-line pb-6"
        >
          <span className="sr-tile h-12 w-12">
            <ScrollText size={24} />
          </span>
          <div>
            <span className="sr-eyebrow">Community</span>
            <h1 className="mt-1 text-2xl font-bold tracking-tight text-scam-text sm:text-3xl">
              Rules &amp; Posting Guidelines
            </h1>
            <p className="mt-1 text-sm text-scam-muted">
              A few ground rules keep this a safe, useful place to warn each
              other about scams.
            </p>
          </div>
        </motion.div>

        <section className="mb-12">
          <h2 className="sr-label mb-4">The rules</h2>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            {RULES.map((rule) => (
              <RuleCard key={rule.title} rule={rule} />
            ))}
          </div>
        </section>

        <section className="mb-12">
          <h2 className="sr-label mb-4">Do &amp; don&rsquo;t</h2>
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
            {DOS_AND_DONTS.map((item) => (
              <motion.div
                key={item.label}
                initial={{ opacity: 0, y: 8 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: '-40px' }}
                transition={{ duration: 0.3, ease: 'easeOut' }}
                className="flex items-start gap-3 rounded-lg border border-scam-line bg-scam-800 px-4 py-3 text-sm"
              >
                {item.good ? (
                  <CheckCircle2
                    size={18}
                    className="mt-0.5 shrink-0 text-trust-400"
                  />
                ) : (
                  <XCircle
                    size={18}
                    className="mt-0.5 shrink-0 text-risk-high"
                  />
                )}
                <span className="text-scam-text">{item.label}</span>
              </motion.div>
            ))}
          </div>
        </section>

        <section>
          <motion.div
            initial={{ opacity: 0, y: 12 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: '-40px' }}
            transition={{ duration: 0.35, ease: 'easeOut' }}
            className="flex items-start gap-3 rounded-lg border border-risk-med/40 bg-risk-med/10 p-5"
          >
            <Ban size={18} className="mt-0.5 shrink-0 text-risk-med" />
            <div>
              <h3 className="text-base font-semibold text-scam-text">
                Breaking the rules
              </h3>
              <p className="mt-1 text-sm leading-relaxed text-scam-muted">
                Posts that break these guidelines may be removed, and repeat
                offenders can be suspended. If you see something that breaks the
                rules, report the post or user so a moderator can take a look.
              </p>
            </div>
          </motion.div>
        </section>
    </>
  );
}

export function RulesPage() {
  return (
    <div
      className="min-h-screen bg-scam-950 text-scam-text"
      style={{ fontFamily: "'Inter', system-ui, -apple-system, sans-serif" }}
    >
      <div className="mx-auto w-full max-w-[900px] px-5 py-10 lg:px-8">
        <RulesContent />
      </div>
    </div>
  );
}
