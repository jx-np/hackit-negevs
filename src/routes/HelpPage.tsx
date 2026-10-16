import { motion } from 'framer-motion';
import {
  AlertTriangle,
  ArrowUpRight,
  Clock,
  LifeBuoy,
  ListChecks,
  PhoneCall,
  ShieldCheck,
  Siren,
} from 'lucide-react';
import { useGuidance, useResources } from '../hooks/useGuidance';
import { FALLBACK_GUIDANCE, FALLBACK_RESOURCES } from '../data/helpFallback';
import type { GuidanceItem, GuidanceUrgency, Resource } from '../types';

/**
 * Urgency uses the traffic-light risk colors only. Every level pairs color
 * with an icon and a text label so meaning never relies on color alone.
 */
const URGENCY_META: Record<
  GuidanceUrgency,
  { label: string; Icon: typeof Siren; badge: string; step: string }
> = {
  emergency: {
    label: 'Emergency',
    Icon: Siren,
    badge: 'border-risk-high/40 bg-risk-high/10 text-risk-high',
    step: 'border-risk-high/50 bg-risk-high/10 text-risk-high',
  },
  urgent: {
    label: 'Act now',
    Icon: Clock,
    badge: 'border-risk-med/40 bg-risk-med/10 text-risk-med',
    step: 'border-risk-med/50 bg-risk-med/10 text-risk-med',
  },
  normal: {
    label: 'Next steps',
    Icon: ListChecks,
    badge: 'border-scam-line bg-scam-750 text-scam-muted',
    step: 'border-scam-line bg-scam-750 text-scam-text',
  },
};

const URGENCY_ORDER: GuidanceUrgency[] = ['emergency', 'urgent', 'normal'];

const reveal = {
  initial: { opacity: 0, y: 10 },
  whileInView: { opacity: 1, y: 0 },
  viewport: { once: true, margin: '-40px' },
  transition: { duration: 0.35, ease: 'easeOut' as const },
};

/** Section heading: small label, optional count, and one muted line. */
function SectionHeader({
  id,
  title,
  count,
  hint,
}: {
  id: string;
  title: string;
  count?: number;
  hint: string;
}) {
  return (
    <div className="mb-5 flex flex-col gap-1">
      <div className="flex items-center gap-2">
        <h2 id={id} className="sr-label">{title}</h2>
        {typeof count === 'number' && (
          <span className="rounded-full border border-scam-line bg-scam-800 px-2 py-px text-[11px] font-semibold tabular-nums text-scam-muted">
            {count}
          </span>
        )}
      </div>
      <p className="text-pretty text-sm text-scam-muted">{hint}</p>
    </div>
  );
}

function GuidanceCard({ item, index }: { item: GuidanceItem; index: number }) {
  const meta = URGENCY_META[item.urgency] ?? URGENCY_META.normal;
  const { Icon } = meta;
  return (
    <motion.li {...reveal} className="sr-surface flex gap-4 p-5 sm:gap-5 sm:p-6">
      {/* Step number, tinted by urgency */}
      <span
        className={`grid h-9 w-9 shrink-0 place-items-center rounded-xl border font-display text-sm font-bold tabular-nums ${meta.step}`}
        aria-hidden
      >
        {index + 1}
      </span>
      <div className="min-w-0 flex-1">
        <div className="flex flex-wrap items-start justify-between gap-x-3 gap-y-2">
          <h3 className="text-pretty font-display text-lg font-semibold leading-snug tracking-tight text-scam-text">
            {item.title}
          </h3>
          <span
            className={`inline-flex shrink-0 items-center gap-1.5 rounded-full border px-2.5 py-0.5 text-xs font-semibold ${meta.badge}`}
          >
            <Icon size={12} aria-hidden />
            {meta.label}
          </span>
        </div>
        <p className="mt-2 whitespace-pre-line text-pretty text-[0.95rem] leading-relaxed text-scam-muted">
          {item.body}
        </p>
      </div>
    </motion.li>
  );
}

function ResourceCard({ resource }: { resource: Resource }) {
  return (
    <motion.a
      href={resource.url}
      target="_blank"
      rel="noopener noreferrer"
      {...reveal}
      className="sr-card sr-focus group flex h-full flex-col p-5"
    >
      <div className="flex-1">
        <div className="flex items-start justify-between gap-3">
          <h3 className="text-pretty font-display text-base font-semibold leading-snug tracking-tight text-scam-text transition group-hover:text-trust-600 dark:group-hover:text-trust-400">
            {resource.name}
          </h3>
          <span className="grid h-7 w-7 shrink-0 place-items-center rounded-lg border border-scam-line text-scam-muted transition group-hover:border-trust-500/50 group-hover:text-trust-600 dark:group-hover:text-trust-400">
            <ArrowUpRight size={15} aria-hidden />
          </span>
        </div>

        {resource.description && (
          <p className="mt-2 text-pretty text-sm leading-relaxed text-scam-muted">
            {resource.description}
          </p>
        )}

        {resource.contactInstructions && (
          <p className="mt-4 flex items-start gap-2.5 rounded-lg border border-scam-line bg-scam-750 px-3 py-2.5 text-sm leading-snug text-scam-text">
            <PhoneCall
              size={15}
              className="mt-0.5 shrink-0 text-trust-600 dark:text-trust-400"
              aria-hidden
            />
            <span>{resource.contactInstructions}</span>
          </p>
        )}
      </div>

      {/* Footer pinned to the bottom (body is flex-1) so cards in a row line up */}
      <div className="mt-4 flex items-center gap-2 border-t border-scam-line pt-3 text-xs text-scam-dim">
        <ShieldCheck size={13} className="shrink-0" aria-hidden />
        <span className="truncate">{resource.ownerName}</span>
        <span className="ml-auto shrink-0 rounded border border-scam-line px-1.5 py-px font-mono text-[10px] font-semibold text-scam-muted">
          {resource.countryCode}
        </span>
        <span className="sr-only">(opens in a new tab)</span>
      </div>
    </motion.a>
  );
}

function SectionError({ message }: { message: string }) {
  return (
    <div className="rounded-2xl border border-risk-high/40 bg-risk-high/10 p-5 text-sm text-risk-high">
      <p className="flex items-center gap-2 font-medium">
        <AlertTriangle size={16} aria-hidden /> Could not load this section.
      </p>
      <p className="mt-1 text-scam-muted">{message}</p>
    </div>
  );
}

function CardSkeleton() {
  return (
    <div className="sr-surface flex gap-4 p-5">
      <div className="h-9 w-9 shrink-0 animate-pulse rounded-xl bg-scam-750" />
      <div className="flex-1">
        <div className="h-5 w-2/3 animate-pulse rounded bg-scam-750" />
        <div className="mt-3 space-y-2">
          <div className="h-3 w-full animate-pulse rounded bg-scam-750" />
          <div className="h-3 w-5/6 animate-pulse rounded bg-scam-750" />
        </div>
      </div>
    </div>
  );
}

export function HelpContent() {
  const guidance = useGuidance();
  const resources = useResources();

  const liveGuidance = guidance.data ?? [];
  const guidanceItems =
    liveGuidance.length > 0 ? liveGuidance : FALLBACK_GUIDANCE;
  const orderedGuidance = [...guidanceItems].sort(
    (a, b) =>
      URGENCY_ORDER.indexOf(a.urgency) - URGENCY_ORDER.indexOf(b.urgency),
  );

  const liveResources = resources.data ?? [];
  const resourceItems =
    liveResources.length > 0 ? liveResources : FALLBACK_RESOURCES;

  return (
    <div className="flex flex-col gap-10 sm:gap-12">
      {/* Header */}
      <motion.header
        initial={{ opacity: 0, y: -12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="sr-surface relative overflow-hidden p-6 sm:p-8"
      >
        <div
          aria-hidden
          className="pointer-events-none absolute -right-24 -top-24 h-64 w-64 sw-halo"
        />
        <div className="relative flex flex-col gap-4 sm:flex-row sm:items-start sm:gap-5">
          <span className="sr-tile h-12 w-12 shrink-0 rounded-xl">
            <LifeBuoy size={24} aria-hidden />
          </span>
          <div className="min-w-0">
            <span className="sr-eyebrow">Get help now</span>
            <h1 className="mt-1.5 text-balance font-display text-3xl font-bold leading-tight tracking-tight text-scam-text sm:text-[2.25rem]">
              If you&rsquo;ve been scammed
            </h1>
            <p className="mt-3 max-w-xl text-pretty text-base leading-relaxed text-scam-muted">
              Take these steps right away, then reach out to the official
              resources below.
            </p>
          </div>
        </div>
      </motion.header>

      {/* Guidance */}
      <section aria-labelledby="help-steps">
        <SectionHeader
          id="help-steps"
          title="Next steps"
          count={guidance.isLoading || guidance.isError ? undefined : orderedGuidance.length}
          hint="Ordered by urgency. Start at the top."
        />
        {guidance.isLoading ? (
          <div className="flex flex-col gap-3">
            <CardSkeleton />
            <CardSkeleton />
          </div>
        ) : guidance.isError ? (
          <SectionError message={(guidance.error as Error).message} />
        ) : (
          <ol className="flex flex-col gap-3">
            {orderedGuidance.map((item, i) => (
              <GuidanceCard key={item.id} item={item} index={i} />
            ))}
          </ol>
        )}
      </section>

      {/* Resources */}
      <section aria-labelledby="help-resources">
        <SectionHeader
          id="help-resources"
          title="Official resources"
          count={resources.isLoading || resources.isError ? undefined : resourceItems.length}
          hint="Verified hotlines and services. Links open in a new tab."
        />
        {resources.isLoading ? (
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
            <CardSkeleton />
            <CardSkeleton />
          </div>
        ) : resources.isError ? (
          <SectionError message={(resources.error as Error).message} />
        ) : (
          <div className="grid auto-rows-fr grid-cols-1 gap-3 sm:grid-cols-2">
            {resourceItems.map((resource) => (
              <ResourceCard key={resource.id} resource={resource} />
            ))}
          </div>
        )}
      </section>
    </div>
  );
}

export function HelpPage() {
  return (
    <div className="min-h-screen bg-scam-950 text-scam-text">
      <div className="mx-auto w-full max-w-[900px] px-5 py-10 lg:px-8 lg:py-14">
        <HelpContent />
      </div>
    </div>
  );
}
