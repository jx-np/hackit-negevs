import { fireEvent, screen } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { clearTokens } from '../../api/tokenStore';
import { mockFetch } from '../../test/mockFetch';
import { renderWithProviders } from '../../test/utils';
import type { Post } from '../../types';
import { PostCard } from './PostCard';

beforeEach(() => {
  localStorage.clear();
  clearTokens();
});
afterEach(() => {
  vi.unstubAllGlobals();
  localStorage.clear();
});

const post: Post = {
  id: 'post-1',
  title: 'A test post title',
  excerpt: 'A short excerpt for the post.',
  author: { id: 'u1', name: 'Ada Lovelace' },
  tags: [
    { id: 't-phishing', name: 'Phishing' },
    { id: 't-blackmail', name: 'Blackmail' },
  ],
  createdAt: '2026-01-15T12:00:00.000Z',
  replyCount: 12,
  likeCount: 88,
};

describe('PostCard', () => {
  it('renders the title, excerpt, and author', () => {
    renderWithProviders(<PostCard post={post} />);
    expect(screen.getByText('A test post title')).toBeInTheDocument();
    expect(screen.getByText('A short excerpt for the post.')).toBeInTheDocument();
    expect(screen.getByText('Ada Lovelace')).toBeInTheDocument();
  });

  it('renders the author initials in the avatar', () => {
    renderWithProviders(<PostCard post={post} />);
    expect(screen.getByText('AL')).toBeInTheDocument();
  });

  it('renders each tag with a # prefix', () => {
    renderWithProviders(<PostCard post={post} />);
    expect(screen.getByText('#Phishing')).toBeInTheDocument();
    expect(screen.getByText('#Blackmail')).toBeInTheDocument();
  });

  it('renders reply and like counts', () => {
    renderWithProviders(<PostCard post={post} />);
    expect(screen.getByText('12')).toBeInTheDocument();
    expect(screen.getAllByText('88').length).toBeGreaterThan(0);
  });

  it('renders redacted screenshots with a click-to-reveal blur', () => {
    renderWithProviders(
      <PostCard
        post={{
          ...post,
          imageUrls: ['/api/v1/community/posts/post-1/images/0'],
        }}
      />,
    );
    const img = screen.getByAltText(
      'A test post title — redacted screenshot 1',
    );
    expect(img).toHaveAttribute(
      'src',
      '/api/v1/community/posts/post-1/images/0',
    );
    expect(img.className).toMatch(/blur-md/);
    expect(
      screen.getByText(/sensitive evidence · click to reveal/i),
    ).toBeInTheDocument();
  });

  it('shows a screenshot count chip when several images are attached', () => {
    renderWithProviders(
      <PostCard
        post={{
          ...post,
          imageUrls: [
            '/api/v1/community/posts/post-1/images/0',
            '/api/v1/community/posts/post-1/images/1',
          ],
        }}
      />,
    );
    expect(screen.getByText(/2 screenshots/i)).toBeInTheDocument();
  });

  it('shows the first-image preview between the title and body', () => {
    renderWithProviders(<PostCard post={post} />);
    const preview = screen.getByAltText('Preview for A test post title');
    expect(preview).toHaveAttribute(
      'src',
      '/api/v1/community/posts/post-1/images/0',
    );
  });

  it('hides the preview when the first image fails to load', () => {
    renderWithProviders(<PostCard post={post} />);
    const preview = screen.getByAltText('Preview for A test post title');
    fireEvent.error(preview);
    expect(
      screen.queryByAltText('Preview for A test post title'),
    ).not.toBeInTheDocument();
  });

  it('opens a zoom lightbox when the preview is clicked', () => {
    renderWithProviders(<PostCard post={post} />);
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
    fireEvent.click(
      screen.getByRole('button', { name: 'Zoom Preview for A test post title' }),
    );
    expect(screen.getByRole('dialog')).toBeInTheDocument();
  });

  it('offers delete to staff on posts they do not own', () => {
    localStorage.setItem(
      'scamreg-user',
      JSON.stringify({
        id: 'mod-1',
        email: 'mod@scamwatch.app',
        name: 'Moderator',
        role: 'moderator',
      }),
    );
    mockFetch([
      { match: '/me/posts', json: { items: [], next_cursor: null } },
    ]);
    renderWithProviders(<PostCard post={post} />);
    fireEvent.click(screen.getByRole('button', { name: 'Post options' }));
    expect(
      screen.getByRole('menuitem', { name: /delete post/i }),
    ).toBeInTheDocument();
  });
});
