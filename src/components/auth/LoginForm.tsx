import { zodResolver } from '@hookform/resolvers/zod';
import { useForm } from 'react-hook-form';
import { Field } from './Field';
import { loginSchema, type LoginValues } from './schemas';

export function LoginForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting, isSubmitSuccessful },
  } = useForm<LoginValues>({ resolver: zodResolver(loginSchema) });

  // UI-only: simulate a submit. Wire to the real auth API later.
  const onSubmit = async (values: LoginValues) => {
    await new Promise((r) => setTimeout(r, 700));
    console.log('login submit', values);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4" noValidate>
      <Field
        id="login-email"
        label="Email"
        type="email"
        autoComplete="email"
        placeholder="you@example.com"
        error={errors.email?.message}
        {...register('email')}
      />
      <Field
        id="login-password"
        label="Password"
        type="password"
        autoComplete="current-password"
        placeholder="••••••••"
        error={errors.password?.message}
        {...register('password')}
      />

      {isSubmitSuccessful && (
        <p className="rounded-lg bg-green-50 px-3 py-2 text-sm text-green-600 dark:bg-green-950/30 dark:text-green-400">
          Signed in (demo). Hook up the real API to continue.
        </p>
      )}

      <button
        type="submit"
        disabled={isSubmitting}
        className="w-full rounded-xl bg-brand-600 py-3 font-semibold text-white transition hover:bg-brand-700 disabled:opacity-60"
      >
        {isSubmitting ? 'Signing in…' : 'Sign in'}
      </button>
    </form>
  );
}
