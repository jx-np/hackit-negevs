import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { renderWithProviders } from '../../test/utils';
import { TagPanel } from './TagPanel';

describe('TagPanel', () => {
  it('renders an "All records" row and loads tags', async () => {
    renderWithProviders(
      <TagPanel selected={null} onSelect={vi.fn()} side="right" onMove={vi.fn()} />,
    );
    expect(
      screen.getByRole('button', { name: /all records/i }),
    ).toBeInTheDocument();
    await waitFor(() => {
      expect(screen.getByRole('button', { name: /React/ })).toBeInTheDocument();
    });
  });

  it('calls onSelect with a tag id, and deselects the active tag', async () => {
    const user = userEvent.setup();
    const onSelect = vi.fn();
    const { rerender } = renderWithProviders(
      <TagPanel selected={null} onSelect={onSelect} side="right" onMove={vi.fn()} />,
    );
    const reactTag = await screen.findByRole('button', { name: /React/ });
    await user.click(reactTag);
    expect(onSelect).toHaveBeenCalledWith('t-react');

    rerender(
      <TagPanel
        selected="t-react"
        onSelect={onSelect}
        side="right"
        onMove={vi.fn()}
      />,
    );
    await user.click(await screen.findByRole('button', { name: /React/ }));
    expect(onSelect).toHaveBeenCalledWith(null);
  });

  it('shows which side it is currently on', () => {
    renderWithProviders(
      <TagPanel selected={null} onSelect={vi.fn()} side="left" onMove={vi.fn()} />,
    );
    expect(screen.getByText(/now on left/i)).toBeInTheDocument();
  });
});
