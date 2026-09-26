import { QueryClientProvider } from '@tanstack/react-query';
import { render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { describe, expect, it } from 'vitest';
import { AppearanceProvider } from '../context/AppearanceContext';
import { AuthProvider } from '../context/AuthContext';
import { makeQueryClient } from '../test/utils';
import { PostDetailPage } from './PostDetailPage';

function renderAt(path: string) {
  const client = makeQueryClient();
  return render(
    <QueryClientProvider client={client}>
      <AppearanceProvider>
        <AuthProvider>
          <MemoryRouter initialEntries={[path]}>
            <Routes>
              <Route path="/forum/:id" element={<PostDetailPage />} />
            </Routes>
          </MemoryRouter>
        </AuthProvider>
      </AppearanceProvider>
    </QueryClientProvider>,
  );
}

describe('PostDetailPage', () => {
  it('renders the full post for a valid id', async () => {
    renderAt('/forum/post-1');
    await waitFor(() =>
      expect(
        screen.getByRole('heading', { level: 1 }),
      ).toBeInTheDocument(),
    );
    // Discussion heading + back link are present.
    expect(
      screen.getByRole('heading', { name: /discussion ·/i }),
    ).toBeInTheDocument();
    expect(screen.getByText(/back to forum/i)).toBeInTheDocument();
  });

  it('shows an error for an unknown id', async () => {
    renderAt('/forum/does-not-exist');
    await waitFor(() =>
      expect(screen.getByText(/post not found/i)).toBeInTheDocument(),
    );
    expect(
      screen.getByRole('link', { name: /return to the forum/i }),
    ).toBeInTheDocument();
  });
});
