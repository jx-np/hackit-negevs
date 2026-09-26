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
          className="mb-1.5 block text-sm font-medium text-slate-700 dark:text-slate-300"
        >
          {label}
        </label>
        <input
          id={id}
          ref={ref}
          aria-invalid={!!error}
          className={`w-full rounded-xl border bg-white px-4 py-2.5 text-slate-900 outline-none transition placeholder:text-slate-400 focus:ring-4 dark:bg-slate-900 dark:text-slate-100 ${
            error
              ? 'border-red-400 focus:ring-red-100 dark:focus:ring-red-900/30'
              : 'border-slate-200 focus:border-brand-400 focus:ring-brand-100 dark:border-slate-700 dark:focus:ring-brand-900/40'
          }`}
          {...props}
        />
        {error && <p className="mt-1 text-sm text-red-500">{error}</p>}
      </div>
    );
  },
);

Field.displayName = 'Field';
