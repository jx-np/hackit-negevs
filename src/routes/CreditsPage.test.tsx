import { screen } from '@testing-library/react';
import { beforeEach, describe, expect, it } from 'vitest';
import { renderWithProviders } from '../test/utils';
import { CreditsPage } from './CreditsPage';

describe('CreditsPage', () => {
  beforeEach(() => localStorage.clear());

  it('renders the heading and hackathon', () => {
    renderWithProviders(<CreditsPage />, { route: '/credits' });
    expect(screen.getByRole('heading', { level: 1, name: 'Credits' })).toBeInTheDocument();
    expect(screen.getByText('Hackit 2026')).toBeInTheDocument();
  });

  it('lists every team member', () => {
    renderWithProviders(<CreditsPage />, { route: '/credits' });
    for (const name of ['Jia Xuan', 'Kenny', 'Wen Xuan', 'Jun Wen', 'Darren']) {
      expect(screen.getByRole('heading', { level: 3, name })).toBeInTheDocument();
    }
  });

  it('shows the tech stacks', () => {
    renderWithProviders(<CreditsPage />, { route: '/credits' });
    for (const title of ['Website', 'Mobile app', 'Backend']) {
      expect(screen.getByRole('heading', { level: 3, name: title })).toBeInTheDocument();
    }
    expect(screen.getByRole('link', { name: /llama\.cpp/i })).toHaveAttribute(
      'href',
      'https://github.com/ggml-org/llama.cpp',
    );
  });
});
