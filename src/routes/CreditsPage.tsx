import { motion } from 'framer-motion';
import {
  ArrowDown,
  ArrowUpRight,
  BrainCircuit,
  Database,
  Globe,
  Heart,
  Server,
  ShieldCheck,
  Smartphone,
  Trophy,
  Users,
  type LucideIcon,
} from 'lucide-react';

interface Member {
  name: string;
  roles: string[];
  /** Optional image path, e.g. '/team/jia-xuan.jpg' (files live in /public/team). */
  photo?: string;
  /** Avatar shape. Circles by default. */
  shape?: 'circle' | 'rounded';
}

interface Stack {
  icon: LucideIcon;
  title: string;
  items: { name: string; detail: string }[];
}

interface Thanks {
  name: string;
  url: string;
  note: string;
}

const TEAM_NAME = 'NegevsInParis';

const MEMBERS: Member[] = [
  {
    name: 'Jia Xuan',
    roles: ['Website', 'Backend', 'Backend AI services'],
    photo: '/jiaxuan.webp',
    shape: 'rounded',
  },
  { name: 'Kenny', roles: ['Website', 'Mobile app', 'AI services'], photo: '/kenny.png' },
  { name: 'Wen Xuan', roles: ['Website', 'Mobile app'], photo: '/wx.jpeg' },
  { name: 'Jun Wen', roles: ['Website', 'Mobile app'], photo: '/junwen.png' },
  { name: 'Darren', roles: ['Website', 'Mobile app'], photo: '/darren.png' },
];

const STACKS: Stack[] = [
  {
    icon: Globe,
    title: 'Website',
    items: [
      { name: 'React', detail: 'UI library' },
      { name: 'TypeScript', detail: 'Language' },
      { name: 'Vite', detail: 'Build tool' },
      { name: 'Tailwind CSS', detail: 'Styling' },
    ],
  },
  {
    icon: Smartphone,
    title: 'Mobile app',
    items: [
      { name: 'Flutter', detail: 'Cross-platform app' },
      { name: 'llama.cpp', detail: 'Local, on-device AI' },
    ],
  },
  {
    icon: Server,
    title: 'Backend',
    items: [
      { name: 'Go', detail: 'API layer' },
      { name: 'Python', detail: 'AI processing layer' },
      { name: 'PostgreSQL', detail: 'Database' },
    ],
  },
];

const THANKS: Thanks[] = [
  { name: 'Flutter', url: 'https://flutter.dev', note: 'Mobile UI toolkit' },
  { name: 'llama.cpp', url: 'https://github.com/ggml-org/llama.cpp', note: 'On-device LLM inference' },
  { name: 'Go', url: 'https://go.dev', note: 'API server' },
  { name: 'Python', url: 'https://www.python.org', note: 'AI processing' },
  { name: 'PostgreSQL', url: 'https://www.postgresql.org', note: 'Database' },
  { name: 'React', url: 'https://react.dev', note: 'Web UI' },
  { name: 'Vite', url: 'https://vite.dev', note: 'Web tooling' },
  { name: 'Tailwind CSS', url: 'https://tailwindcss.com', note: 'Styling' },
  { name: 'Framer Motion', url: 'https://motion.dev', note: 'Animation' },
  { name: 'Lucide', url: 'https://lucide.dev', note: 'Icons' },
  { name: 'Google Fonts', url: 'https://fonts.google.com', note: 'Space Grotesk, Inter, Atkinson Hyperlegible' },
];

const reveal = {
  initial: { opacity: 0, y: 12 },
  whileInView: { opacity: 1, y: 0 },
  viewport: { once: true, margin: '-40px' },
  transition: { duration: 0.35, ease: 'easeOut' as const },
};

function initials(name: string) {
  return name
    .split(/\s+/)
    .map((part) => part[0])
    .join('')
    .slice(0, 2)
    .toUpperCase();
}

function SectionHeader({ id, title, hint }: { id: string; title: string; hint: string }) {
  return (
    <div className="mb-5 flex flex-col gap-1">
      <h2 id={id} className="sr-label">{title}</h2>
      <p className="text-pretty text-sm text-scam-muted">{hint}</p>
    </div>
  );
}

function MemberCard({ member }: { member: Member }) {
  const radius = member.shape === 'rounded' ? 'rounded-2xl' : 'rounded-full';
  return (
    <motion.li {...reveal} className="sr-card flex h-full flex-col items-center p-6 text-center">
      {member.photo ? (
        <img
          src={member.photo}
          alt={`Photo of ${member.name}`}
          className={`h-20 w-20 border border-scam-line object-cover shadow-card ${radius}`}
        />
      ) : (
        <span
          aria-hidden
          className={`grid h-20 w-20 place-items-center bg-gradient-to-b from-trust-500 to-trust-700 font-display text-2xl font-bold text-white shadow-button ${radius}`}
        >
          {initials(member.name)}
        </span>
      )}
      <h3 className="mt-4 font-display text-lg font-semibold tracking-tight text-scam-text">
        {member.name}
      </h3>
      <ul className="mt-3 flex flex-wrap justify-center gap-1.5" aria-label={`${member.name}'s roles`}>
        {member.roles.map((role) => (
          <li
            key={role}
            className="rounded-full border border-scam-line bg-scam-750 px-2.5 py-0.5 text-xs font-medium text-scam-muted"
          >
            {role}
          </li>
        ))}
      </ul>
    </motion.li>
  );
}

function StackCard({ stack }: { stack: Stack }) {
  const Icon = stack.icon;
  return (
    <motion.article {...reveal} className="sr-surface flex h-full flex-col p-5">
      <div className="flex items-center gap-3">
        <span className="sr-tile h-10 w-10 rounded-xl">
          <Icon size={20} aria-hidden />
        </span>
        <h3 className="font-display text-base font-semibold tracking-tight text-scam-text">
          {stack.title}
        </h3>
      </div>
      <ul className="mt-4 divide-y divide-scam-line border-t border-scam-line">
        {stack.items.map((item) => (
          <li key={item.name} className="flex items-baseline justify-between gap-3 py-2.5">
            <span className="text-sm font-semibold text-scam-text">{item.name}</span>
            <span className="text-right text-xs text-scam-muted">{item.detail}</span>
          </li>
        ))}
      </ul>
    </motion.article>
  );
}

function DiagramNode({
  icon: Icon,
  title,
  tech,
  note,
}: {
  icon: LucideIcon;
  title: string;
  tech: string;
  note: string;
}) {
  return (
    <div className="flex items-start gap-3 rounded-xl border border-scam-line bg-scam-800 p-4 shadow-card">
      <span className="grid h-9 w-9 shrink-0 place-items-center rounded-lg bg-gradient-to-b from-trust-500 to-trust-700 text-white shadow-button">
        <Icon size={18} aria-hidden />
      </span>
      <div className="min-w-0">
        <p className="font-display text-sm font-semibold text-scam-text">{title}</p>
        <p className="text-xs font-medium text-trust-600 dark:text-trust-400">{tech}</p>
        <p className="mt-1 text-pretty text-xs leading-relaxed text-scam-muted">{note}</p>
      </div>
    </div>
  );
}

function Connector({ label }: { label: string }) {
  return (
    <div className="flex items-center justify-center gap-2 py-2 text-scam-dim" aria-hidden>
      <ArrowDown size={16} />
      <span className="text-[11px] font-semibold uppercase tracking-[0.14em]">{label}</span>
      <ArrowDown size={16} />
    </div>
  );
}

function ArchitectureDiagram() {
  return (
    <motion.figure
      {...reveal}
      className="sr-surface relative overflow-hidden p-5 sm:p-8"
      aria-describedby="arch-caption"
    >
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 sw-dots opacity-70 [mask-image:radial-gradient(ellipse_at_50%_40%,black_20%,transparent_75%)]"
      />
      <div className="relative">
        <p className="sr-label mb-3">Clients</p>
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <DiagramNode
            icon={Smartphone}
            title="Mobile app"
            tech="Flutter + llama.cpp"
            note="Scans messages and calls with a local model. Nothing leaves the phone to be analysed."
          />
          <DiagramNode
            icon={Globe}
            title="Website"
            tech="React + TypeScript"
            note="Community forum, number checks and scam reports."
          />
        </div>

        <Connector label="HTTPS / REST" />

        <p className="sr-label mb-3">Backend</p>
        <DiagramNode
          icon={Server}
          title="API layer"
          tech="Go"
          note="Auth, reports, forum and the shared scam registry."
        />

        <div className="grid grid-cols-1 sm:grid-cols-2 sm:gap-3">
          <div>
            <Connector label="AI jobs" />
            <DiagramNode
              icon={BrainCircuit}
              title="AI processing"
              tech="Python"
              note="Analyses reports and powers the community AI helper."
            />
          </div>
          <div>
            <Connector label="SQL" />
            <DiagramNode
              icon={Database}
              title="Database"
              tech="PostgreSQL"
              note="Stores users, posts, reports and verified scam data."
            />
          </div>
        </div>
      </div>
      <figcaption id="arch-caption" className="sr-only">
        The Flutter mobile app, which runs AI locally with llama.cpp, and the React website both
        talk to a Go API over HTTPS. The Go API sends AI jobs to a Python processing layer and
        stores data in PostgreSQL.
      </figcaption>
    </motion.figure>
  );
}

function HackathonBanner() {
  return (
    <motion.header
      initial={{ opacity: 0, y: -12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
      className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-trust-700 via-trust-600 to-trust-700 px-6 py-10 text-white shadow-device sm:px-10 sm:py-12"
    >
      <div className="pointer-events-none absolute inset-0 opacity-25 [background-image:radial-gradient(rgba(255,255,255,0.5)_1px,transparent_1px)] [background-size:22px_22px] [mask-image:linear-gradient(to_left,black,transparent_70%)]" />
      <ShieldCheck
        aria-hidden
        strokeWidth={1}
        className="pointer-events-none absolute -bottom-14 -right-8 h-64 w-64 text-white/10"
      />
      <div className="relative max-w-2xl">
        <span className="inline-flex items-center gap-1.5 rounded-full border border-white/30 bg-white/10 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-trust-50">
          <Trophy size={13} aria-hidden /> Hackit 2026
        </span>
        <h1 className="mt-4 text-balance font-display text-3xl font-bold leading-tight tracking-tight sm:text-5xl sm:leading-[1.05]">
          Credits
        </h1>
        <p className="mt-4 text-pretty text-lg leading-relaxed text-trust-50/90">
          ScamWatch was built for Hackit 2026 by team{' '}
          <span className="font-semibold text-white">{TEAM_NAME}</span>. Here&rsquo;s who made it
          and what it runs on.
        </p>
      </div>
    </motion.header>
  );
}

export function CreditsContent() {
  return (
    <div className="flex flex-col gap-12 sm:gap-14">
      <HackathonBanner />

      <section aria-labelledby="credits-team">
        <div className="mb-5 flex flex-col gap-1">
          <div className="flex items-center gap-2">
            <Users size={14} className="text-trust-600 dark:text-trust-400" aria-hidden />
            <h2 id="credits-team" className="sr-label">The team</h2>
            <span className="rounded-full border border-scam-line bg-scam-800 px-2 py-px text-[11px] font-semibold tabular-nums text-scam-muted">
              {MEMBERS.length}
            </span>
          </div>
          <p className="text-pretty text-sm text-scam-muted">
            {TEAM_NAME}: five people, one app, one website and a backend.
          </p>
        </div>
        <ul className="grid auto-rows-fr grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {MEMBERS.map((member) => (
            <MemberCard key={member.name} member={member} />
          ))}
        </ul>
      </section>

      <section aria-labelledby="credits-stack">
        <SectionHeader
          id="credits-stack"
          title="Tech stack"
          hint="What each part of ScamWatch is built with."
        />
        <div className="grid grid-cols-1 gap-3 md:grid-cols-3">
          {STACKS.map((stack) => (
            <StackCard key={stack.title} stack={stack} />
          ))}
        </div>
      </section>

      <section aria-labelledby="credits-architecture">
        <SectionHeader
          id="credits-architecture"
          title="Architecture"
          hint="How the pieces fit together."
        />
        <ArchitectureDiagram />
      </section>

      <section aria-labelledby="credits-thanks">
        <SectionHeader
          id="credits-thanks"
          title="Open-source thanks"
          hint="ScamWatch stands on these projects. Links open in a new tab."
        />
        <ul className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {THANKS.map((item) => (
            <motion.li {...reveal} key={item.name}>
              <a
                href={item.url}
                target="_blank"
                rel="noopener noreferrer"
                className="sr-card sr-focus group flex h-full items-start justify-between gap-3 p-4"
              >
                <span className="min-w-0">
                  <span className="block font-display text-sm font-semibold text-scam-text transition group-hover:text-trust-600 dark:group-hover:text-trust-400">
                    {item.name}
                  </span>
                  <span className="mt-0.5 block text-pretty text-xs text-scam-muted">
                    {item.note}
                  </span>
                </span>
                <ArrowUpRight
                  size={15}
                  aria-hidden
                  className="mt-0.5 shrink-0 text-scam-dim transition group-hover:text-trust-600 dark:group-hover:text-trust-400"
                />
                <span className="sr-only">(opens in a new tab)</span>
              </a>
            </motion.li>
          ))}
        </ul>
        <p className="mt-8 flex items-center justify-center gap-1.5 text-sm text-scam-dim">
          Made with <Heart size={14} className="text-risk-high" aria-label="love" /> by {TEAM_NAME}
        </p>
      </section>
    </div>
  );
}

export function CreditsPage() {
  return (
    <div className="min-h-screen bg-scam-950 text-scam-text">
      <div className="mx-auto w-full max-w-[1000px] px-5 py-10 lg:px-8 lg:py-14">
        <CreditsContent />
      </div>
    </div>
  );
}
