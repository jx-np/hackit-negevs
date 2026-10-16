import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, type RenderOptions } from '@testing-library/react';
import type { ReactElement, ReactNode } from 'react';
import { MemoryRouter } from 'react-router-dom';
import { AppearanceProvider } from '../context/AppearanceContext';
import { AuthProvider } from '../context/AuthContext';
import { SavedFeedsProvider } from '../context/SavedFeedsContext';

/** Create a QueryClient with retries off for deterministic tests. */
export function makeQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: { retry: false },
    },
  });
}

interface WrapperProps {
  children: ReactNode;
  route?: string;
}

function AllProviders({ children, route = '/' }: WrapperProps) {
  const client = makeQueryClient();
  return (
    <QueryClientProvider client={client}>
      <AppearanceProvider>
        <AuthProvider>
          <SavedFeedsProvider>
            <MemoryRouter initialEntries={[route]}>{children}</MemoryRouter>
          </SavedFeedsProvider>
        </AuthProvider>
      </AppearanceProvider>
    </QueryClientProvider>
  );
}

/** Render with app providers (Router + React Query + Appearance). */
export function renderWithProviders(
  ui: ReactElement,
  options?: RenderOptions & { route?: string },
) {
  const { route, ...rest } = options ?? {};
  return render(ui, {
    wrapper: ({ children }) => (
      <AllProviders route={route}>{children}</AllProviders>
    ),
    ...rest,
  });
}
