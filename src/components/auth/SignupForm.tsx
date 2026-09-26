import { zodResolver } from '@hookform/resolvers/zod';
import { useForm } from 'react-hook-form';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { Field } from './Field';
import { signupSchema, type SignupValues } from './schemas';

export function SignupForm() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting, isSubmitSuccessful },
  } = useForm<SignupValues>({ resolver: zodResolver(signupSchema) });

  // Scaffolded: simulate a request, then flip the fake auth state.
  const onSubmit = async (values: SignupValues) => {
    await new Promise((r) => setTimeout(r, 700));
    login({ email: values.email, name: values.name });
    navigate('/forum');
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4" noValidate>
      <Field
        id="signup-name"
        label="Name"
        autoComplete="name"
        placeholder="Ada Lovelace"
        error={errors.name?.message}
        {...register('name')}
      />
      <Field
        id="signup-email"
        label="Email"
        type="email"
        autoComplete="email"
        placeholder="you@example.com"
        error={errors.email?.message}
        {...register('email')}
      />
      <Field
        id="signup-password"
        label="Password"
        type="password"
        autoComplete="new-password"
        placeholder="At least 8 characters"
        error={errors.password?.message}
        {...register('password')}
      />
      <Field
        id="signup-confirm"
        label="Confirm password"
        type="password"
        autoComplete="new-password"
        placeholder="Re-enter your password"
        error={errors.confirmPassword?.message}
        {...register('confirmPassword')}
      />

      {isSubmitSuccessful && (
        <p className="border border-safe-500 bg-safe-50 px-3 py-2 font-mono text-xs text-safe-700 dark:bg-safe-500/10 dark:text-safe-400">
          Account created (demo). Hook up the real API to continue.
        </p>
      )}

      <button
        type="submit"
        disabled={isSubmitting}
        className="w-full border border-ink-900 bg-ink-900 py-3 font-semibold text-white transition hover:bg-ink-800 disabled:opacity-60 dark:border-white dark:bg-white dark:text-ink-900 dark:hover:bg-ink-100"
      >
        {isSubmitting ? 'Creating account…' : 'Create account'}
      </button>
    </form>
  );
}
