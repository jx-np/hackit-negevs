import { zodResolver } from '@hookform/resolvers/zod';
import { useForm } from 'react-hook-form';
import { useNavigate } from 'react-router-dom';
import { ApiError } from '../../api/client';
import { useAuth } from '../../context/AuthContext';
import { Field } from './Field';
import { signupSchema, type SignupValues } from './schemas';

export function SignupForm() {
  const { register: registerUser } = useAuth();
  const navigate = useNavigate();
  const {
    register,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = useForm<SignupValues>({ resolver: zodResolver(signupSchema) });

  const onSubmit = async (values: SignupValues) => {
    try {
      await registerUser(values.email, values.password, values.name);
      navigate('/forum');
    } catch (err) {
      if (err instanceof ApiError) {
        // 409 → email taken; 422 → field validation errors.
        if (err.code === 'conflict') {
          setError('email', { message: 'This email is already registered.' });
        }
        if (err.fields.email) setError('email', { message: err.fields.email });
        if (err.fields.password)
          setError('password', { message: err.fields.password });
        if (err.fields.display_name)
          setError('name', { message: err.fields.display_name });
        setError('root', { message: err.message });
      } else {
        setError('root', { message: 'Something went wrong. Please try again.' });
      }
    }
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
        {isSubmitting ? 'Creating account…' : 'Create account'}
      </button>
    </form>
  );
}
