import { screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { renderWithProviders } from '../../test/utils';
import type { Post } from '../../types';
import { PostCard } from './PostCard';

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
    expect(screen.getByText('88')).toBeInTheDocument();
  });
});
