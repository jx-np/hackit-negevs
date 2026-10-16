import { z } from 'zod';

/** Today's date as YYYY-MM-DD (local), used to block future incident dates. */
export function todayISO(): string {
  const d = new Date();
  const off = d.getTimezoneOffset();
  return new Date(d.getTime() - off * 60000).toISOString().slice(0, 10);
}

export const reportSchema = z.object({
  title: z
    .string()
    .min(8, 'Give a clear title (at least 8 characters)')
    .max(120, 'Keep the title under 120 characters'),
  incidentDate: z
    .string()
    .min(1, 'Select when it happened')
    .refine((d) => d <= todayISO(), 'The date cannot be in the future'),
  excerpt: z
    .string()
    .min(20, 'Describe what happened (at least 20 characters)')
    .max(600, 'Keep the summary under 600 characters'),
});

export type ReportValues = z.infer<typeof reportSchema>;
