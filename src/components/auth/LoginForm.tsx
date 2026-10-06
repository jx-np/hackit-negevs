import { zodResolver } from '@hookform/resolvers/zod';
import { useForm } from 'react-hook-form';
import { useNavigate } from 'react-router-dom';
import { ApiError } from '../../api/client';
import { useAuth } from '../../context/AuthContext';
import { Field } from './Field';
import { loginSchema, type LoginValues } from './schemas';

export function LoginForm() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const {
    register,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = useForm<LoginValues>({ resolver: zodResolver(loginSchema) });

  const onSubmit = async (values: LoginValues) => {
    try {
      await login(values.email, values.password);
      navigate('/forum');
    } catch (err) {
      if (err instanceof ApiError) {
        // 401 → generic invalid credentials; 422 → field errors.
        if (err.fields.email) setError('email', { message: err.fields.email });
        if (err.fields.password)
          setError('password', { message: err.fields.password });
        setError('root', {
          message:
            err.status === 401
              ? 'Incorrect email or password.'
              : err.message,
        });
      } else {
        setError('root', { message: 'Something went wrong. Please try again.' });
      }
    }
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

      {errors.root && (
        <p className="border border-risk-500 bg-risk-50 px-3 py-2 text-xs text-risk-700 dark:bg-risk-500/10 dark:text-risk-500">
          {errors.root.message}
        </p>
      )}

      <button
        type="submit"
        disabled={isSubmitting}
        className="w-full border border-ink-900 bg-ink-900 py-3 font-semibold text-white transition hover:bg-ink-800 disabled:opacity-60 dark:border-white dark:bg-white dark:text-ink-900 dark:hover:bg-ink-100"
      >
        {isSubmitting ? 'Signing in…' : 'Sign in'}
      </button>
    </form>
  );
}
