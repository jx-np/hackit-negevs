import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { renderWithProviders } from '../../test/utils';
import { TagFilter } from './TagFilter';

describe('TagFilter', () => {
  it('renders an "All" chip', async () => {
    renderWithProviders(<TagFilter selected={null} onSelect={vi.fn()} />);
    expect(screen.getByRole('button', { name: /^all$/i })).toBeInTheDocument();
  });

  it('loads and renders tags from the API', async () => {
    renderWithProviders(<TagFilter selected={null} onSelect={vi.fn()} />);
    await waitFor(() => {
      expect(screen.getByRole('button', { name: /React/ })).toBeInTheDocument();
    });
  });

  it('calls onSelect with the tag id when a tag is clicked', async () => {
    const user = userEvent.setup();
    const onSelect = vi.fn();
    renderWithProviders(<TagFilter selected={null} onSelect={onSelect} />);

    const reactTag = await screen.findByRole('button', { name: /React/ });
    await user.click(reactTag);
    expect(onSelect).toHaveBeenCalledWith('t-react');
  });

  it('deselects (calls onSelect(null)) when the active tag is clicked', async () => {
    const user = userEvent.setup();
    const onSelect = vi.fn();
    renderWithProviders(
      <TagFilter selected="t-react" onSelect={onSelect} />,
    );

    const reactTag = await screen.findByRole('button', { name: /React/ });
    await user.click(reactTag);
    expect(onSelect).toHaveBeenCalledWith(null);
  });

  it('marks the selected tag as pressed', async () => {
    renderWithProviders(<TagFilter selected="t-react" onSelect={vi.fn()} />);
    const reactTag = await screen.findByRole('button', { name: /React/ });
    expect(reactTag).toHaveAttribute('aria-pressed', 'true');
  });
});
