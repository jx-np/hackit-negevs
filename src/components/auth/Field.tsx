import { forwardRef, type InputHTMLAttributes } from 'react';

interface FieldProps extends InputHTMLAttributes<HTMLInputElement> {
  label: string;
  error?: string;
}

export const Field = forwardRef<HTMLInputElement, FieldProps>(
  ({ label, error, id, ...props }, ref) => {
    return (
      <div>
        <label
          htmlFor={id}
          className="mb-1.5 block font-display text-xs font-medium uppercase tracking-wider text-ink-600 dark:text-ink-400"
        >
          {label}
        </label>
        <input
          id={id}
          ref={ref}
          aria-invalid={!!error}
          className={`w-full rounded-md border bg-white px-4 py-2.5 text-ink-900 outline-none transition placeholder:text-ink-400 focus:ring-2 dark:bg-ink-900 dark:text-white ${
            error
              ? 'border-risk-500 focus:ring-risk-500/30'
              : 'border-ink-300 focus:border-safe-500 focus:ring-safe-500/30 dark:border-ink-700'
          }`}
          {...props}
        />
        {error && (
          <p className="mt-1 text-xs text-risk-600 dark:text-risk-500">
            {error}
          </p>
        )}
      </div>
    );
  },
);

Field.displayName = 'Field';
