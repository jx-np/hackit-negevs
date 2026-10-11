import { motion } from 'framer-motion';
import {
  AlertTriangle,
  ExternalLink,
  LifeBuoy,
  ShieldCheck,
} from 'lucide-react';
import { useGuidance, useResources } from '../hooks/useGuidance';
import type { GuidanceItem, GuidanceUrgency, Resource } from '../types';

const URGENCY_META: Record<
  GuidanceUrgency,
  { label: string; strip: string; badge: string }
> = {
  emergency: {
    label: 'Emergency',
    strip: 'bg-risk-high',
    badge: 'border-risk-high/40 bg-risk-high/10 text-risk-high',
  },
  urgent: {
    label: 'Act now',
    strip: 'bg-risk-med',
    badge: 'border-risk-med/40 bg-risk-med/10 text-risk-med',
  },
  normal: {
    label: 'Next steps',
    strip: 'bg-scam-muted',
    badge: 'border-scam-line bg-scam-800 text-scam-muted',
  },
};

const URGENCY_ORDER: GuidanceUrgency[] = ['emergency', 'urgent', 'normal'];

function GuidanceCard({ item }: { item: GuidanceItem }) {
  const meta = URGENCY_META[item.urgency] ?? URGENCY_META.normal;
  return (
    <motion.article
      initial={{ opacity: 0, y: 12 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-40px' }}
      transition={{ duration: 0.35, ease: 'easeOut' }}
      className="relative overflow-hidden rounded-lg border border-scam-line bg-scam-800 p-5"
    >
      <span className={`absolute inset-y-0 left-0 w-1 ${meta.strip}`} aria-hidden />
      <div className="flex items-center gap-2">
        <span
          className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold ${meta.badge}`}
        >
          {meta.label}
        </span>
      </div>
      <h3 className="mt-3 text-lg font-semibold text-scam-text">{item.title}</h3>
      <p className="mt-2 whitespace-pre-line text-sm leading-relaxed text-scam-muted">
        {item.body}
      </p>
    </motion.article>
  );
}

function ResourceCard({ resource }: { resource: Resource }) {
  return (
    <motion.a
      href={resource.url}
      target="_blank"
      rel="noopener noreferrer"
      initial={{ opacity: 0, y: 12 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-40px' }}
      transition={{ duration: 0.35, ease: 'easeOut' }}
      className="group flex flex-col rounded-lg border border-scam-line bg-scam-800 p-5 transition hover:border-scam-muted/60 hover:bg-scam-750"
    >
      <div className="flex items-start justify-between gap-3">
        <h3 className="font-semibold text-scam-text group-hover:text-white">
          {resource.name}
        </h3>
        <ExternalLink
          size={16}
          className="shrink-0 text-scam-muted group-hover:text-scam-text"
        />
      </div>
      {resource.description && (
        <p className="mt-2 text-sm leading-relaxed text-scam-muted">
          {resource.description}
        </p>
      )}
      {resource.contactInstructions && (
        <p className="mt-3 rounded-md border border-scam-line bg-scam-850 px-3 py-2 text-sm text-scam-text">
          {resource.contactInstructions}
        </p>
      )}
      <div className="mt-3 flex items-center gap-2 text-xs text-scam-dim">
        <ShieldCheck size={13} />
        <span>
          {resource.ownerName} · {resource.countryCode}
        </span>
      </div>
    </motion.a>
  );
}

function SectionError({ message }: { message: string }) {
  return (
    <div className="rounded-lg border border-risk-high/40 bg-risk-high/10 p-5 text-sm text-risk-high">
      <p className="flex items-center gap-2 font-medium">
        <AlertTriangle size={16} /> Could not load this section.
      </p>
      <p className="mt-1 text-scam-muted">{message}</p>
    </div>
  );
}

function CardSkeleton() {
  return (
    <div className="rounded-lg border border-scam-line bg-scam-800 p-5">
      <div className="h-4 w-24 animate-pulse rounded bg-scam-750" />
      <div className="mt-3 h-5 w-2/3 animate-pulse rounded bg-scam-750" />
      <div className="mt-3 space-y-2">
        <div className="h-3 w-full animate-pulse rounded bg-scam-750" />
        <div className="h-3 w-5/6 animate-pulse rounded bg-scam-750" />
      </div>
    </div>
  );
}

export function HelpPage() {
  const guidance = useGuidance();
  const resources = useResources();

  const guidanceItems = guidance.data ?? [];
  const orderedGuidance = [...guidanceItems].sort(
    (a, b) =>
      URGENCY_ORDER.indexOf(a.urgency) - URGENCY_ORDER.indexOf(b.urgency),
  );

  return (
    <div
      className="min-h-screen bg-scam-950 text-scam-text"
      style={{ fontFamily: "'Inter', system-ui, -apple-system, sans-serif" }}
    >
      <div className="mx-auto w-full max-w-[900px] px-5 py-10 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: -12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="mb-8 flex items-center gap-3 border-b border-scam-line pb-6"
        >
          <span className="sr-tile h-12 w-12">
            <LifeBuoy size={24} />
          </span>
          <div>
            <span className="sr-eyebrow">Get help now</span>
            <h1 className="mt-1 text-2xl font-bold tracking-tight text-scam-text sm:text-3xl">
              If you&rsquo;ve been scammed
            </h1>
            <p className="mt-1 text-sm text-scam-muted">
              Take these steps right away, then reach out to the official
              resources below.
            </p>
          </div>
        </motion.div>

        {/* Guidance */}
        <section className="mb-12">
          <h2 className="sr-label mb-4">Next steps</h2>
          {guidance.isLoading ? (
            <div className="flex flex-col gap-4">
              <CardSkeleton />
              <CardSkeleton />
            </div>
          ) : guidance.isError ? (
            <SectionError message={(guidance.error as Error).message} />
          ) : orderedGuidance.length === 0 ? (
            <p className="rounded-lg border border-dashed border-scam-line p-8 text-center text-scam-muted">
              No guidance available right now.
            </p>
          ) : (
            <div className="flex flex-col gap-4">
              {orderedGuidance.map((item) => (
                <GuidanceCard key={item.id} item={item} />
              ))}
            </div>
          )}
        </section>

        {/* Resources */}
        <section>
          <h2 className="sr-label mb-4">Official resources</h2>
          {resources.isLoading ? (
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <CardSkeleton />
              <CardSkeleton />
            </div>
          ) : resources.isError ? (
            <SectionError message={(resources.error as Error).message} />
          ) : (resources.data ?? []).length === 0 ? (
            <p className="rounded-lg border border-dashed border-scam-line p-8 text-center text-scam-muted">
              No resources available right now.
            </p>
          ) : (
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              {(resources.data ?? []).map((resource) => (
                <ResourceCard key={resource.id} resource={resource} />
              ))}
            </div>
          )}
        </section>
      </div>
    </div>
  );
}
