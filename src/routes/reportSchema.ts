import { z } from 'zod';

export const reportSchema = z.object({
  title: z
    .string()
    .min(8, 'Give a clear title (at least 8 characters)')
    .max(120, 'Keep the title under 120 characters'),
  excerpt: z
    .string()
    .min(20, 'Describe what happened (at least 20 characters)')
    .max(600, 'Keep the summary under 600 characters'),
  tagId: z.string().min(1, 'Choose a category'),
  risk: z.enum(['high', 'medium', 'none']),
  imageUrl: z
    .string()
    .url('Enter a valid image URL')
    .or(z.literal(''))
    .optional(),
});

export type ReportValues = z.infer<typeof reportSchema>;
