import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { renderWithProviders } from '../../test/utils';
import { mockFetch } from '../../test/mockFetch';
import { TagPanel } from './TagPanel';

beforeEach(() => {
  mockFetch([
    {
      match: '/community/scam-types',
      json: {
        items: [
          { slug: 'phishing', name_key: 'category.phishing' },
          { slug: 'blackmail', name_key: 'category.blackmail' },
        ],
      },
    },
  ]);
});

afterEach(() => vi.unstubAllGlobals());

describe('TagPanel', () => {
  it('renders an "All records" row and loads tags', async () => {
    renderWithProviders(
      <TagPanel selected={null} onSelect={vi.fn()} side="right" onMove={vi.fn()} />,
    );
    expect(
      screen.getByRole('button', { name: /all records/i }),
    ).toBeInTheDocument();
    await waitFor(() => {
      expect(screen.getByRole('button', { name: /Phishing/ })).toBeInTheDocument();
    });
  });

  it('calls onSelect with a tag id, and deselects the active tag', async () => {
    const user = userEvent.setup();
    const onSelect = vi.fn();
    const { rerender } = renderWithProviders(
      <TagPanel selected={null} onSelect={onSelect} side="right" onMove={vi.fn()} />,
    );
    const phishingTag = await screen.findByRole('button', { name: /Phishing/ });
    await user.click(phishingTag);
    expect(onSelect).toHaveBeenCalledWith('phishing');

    rerender(
      <TagPanel
        selected="phishing"
        onSelect={onSelect}
        side="right"
        onMove={vi.fn()}
      />,
    );
    await user.click(await screen.findByRole('button', { name: /Phishing/ }));
    expect(onSelect).toHaveBeenCalledWith(null);
  });

  it('shows which side it is currently on', () => {
    renderWithProviders(
      <TagPanel selected={null} onSelect={vi.fn()} side="left" onMove={vi.fn()} />,
    );
    expect(screen.getByText(/now on left/i)).toBeInTheDocument();
  });
});
