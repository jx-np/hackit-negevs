import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { SortControl } from './SortControl';

describe('SortControl', () => {
  it('renders the three sort options', () => {
    render(<SortControl value="new" onChange={vi.fn()} />);
    expect(screen.getByRole('button', { name: /newest/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /comments/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /likes/i })).toBeInTheDocument();
  });

  it('marks the active option as pressed', () => {
    render(<SortControl value="likes" onChange={vi.fn()} />);
    expect(screen.getByRole('button', { name: /likes/i })).toHaveAttribute(
      'aria-pressed',
      'true',
    );
    expect(screen.getByRole('button', { name: /newest/i })).toHaveAttribute(
      'aria-pressed',
      'false',
    );
  });

  it('calls onChange with the chosen sort key', async () => {
    const user = userEvent.setup();
    const onChange = vi.fn();
    render(<SortControl value="new" onChange={onChange} />);
    await user.click(screen.getByRole('button', { name: /comments/i }));
    expect(onChange).toHaveBeenCalledWith('comments');
  });
});
