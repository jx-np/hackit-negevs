import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { SearchBar } from './SearchBar';

describe('SearchBar', () => {
  it('renders the search input', () => {
    render(<SearchBar value="" onChange={vi.fn()} />);
    expect(
      screen.getByPlaceholderText(/search posts/i),
    ).toBeInTheDocument();
  });

  it('calls onChange as the user types', async () => {
    const user = userEvent.setup();
    const onChange = vi.fn();
    render(<SearchBar value="" onChange={onChange} />);

    await user.type(screen.getByPlaceholderText(/search posts/i), 'hi');
    expect(onChange).toHaveBeenCalled();
  });

  it('shows a clear button only when there is a value', async () => {
    const user = userEvent.setup();
    const onChange = vi.fn();
    const { rerender } = render(
      <SearchBar value="" onChange={onChange} />,
    );
    expect(screen.queryByLabelText(/clear search/i)).not.toBeInTheDocument();

    rerender(<SearchBar value="react" onChange={onChange} />);
    const clearBtn = screen.getByLabelText(/clear search/i);
    expect(clearBtn).toBeInTheDocument();

    await user.click(clearBtn);
    expect(onChange).toHaveBeenCalledWith('');
  });
});
