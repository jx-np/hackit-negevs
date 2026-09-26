import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it } from 'vitest';
import { renderWithProviders } from '../../test/utils';
import { CommentBox } from './CommentBox';

describe('CommentBox (auth gating)', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it('shows a "Log in to comment" prompt when logged out', () => {
    renderWithProviders(<CommentBox postId="post-1" />);
    expect(screen.getByText(/log in to comment/i)).toBeInTheDocument();
    // A link to the auth page should be present.
    const loginLink = screen.getByRole('link', { name: /log in/i });
    expect(loginLink).toHaveAttribute('href', '/auth');
    // No comment input while logged out.
    expect(screen.queryByRole('textbox')).not.toBeInTheDocument();
  });

  it('shows a comment input when logged in', () => {
    // Seed a persisted session so AuthProvider starts logged in.
    localStorage.setItem(
      'scamreg-auth',
      JSON.stringify({ id: 'u1', email: 'a@b.com', name: 'Alice' }),
    );
    renderWithProviders(<CommentBox postId="post-1" />);

    expect(screen.getByRole('textbox')).toBeInTheDocument();
    expect(screen.queryByText(/log in to comment/i)).not.toBeInTheDocument();
    expect(screen.getByText(/commenting as alice/i)).toBeInTheDocument();
  });

  it('disables the submit button until text is entered', async () => {
    const user = userEvent.setup();
    localStorage.setItem(
      'scamreg-auth',
      JSON.stringify({ id: 'u1', email: 'a@b.com', name: 'Alice' }),
    );
    renderWithProviders(<CommentBox postId="post-1" />);

    const submit = screen.getByRole('button', { name: /comment/i });
    expect(submit).toBeDisabled();

    await user.type(screen.getByRole('textbox'), 'Nice post!');
    expect(submit).toBeEnabled();
  });
});
