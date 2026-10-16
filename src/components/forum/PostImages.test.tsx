import { fireEvent, render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { PostImages } from './PostImages';

const URLS = [
  '/api/v1/community/posts/12/images/0',
  '/api/v1/community/posts/12/images/1',
];

describe('PostImages', () => {
  it('renders nothing without images', () => {
    const { container } = render(<PostImages urls={[]} alt="Post" />);
    expect(container).toBeEmptyDOMElement();
  });

  it('renders each redacted screenshot', () => {
    render(<PostImages urls={URLS} alt="Fake bank SMS" />);
    expect(
      screen.getByAltText('Fake bank SMS — redacted screenshot 1'),
    ).toHaveAttribute('src', URLS[0]);
    expect(
      screen.getByAltText('Fake bank SMS — redacted screenshot 2'),
    ).toHaveAttribute('src', URLS[1]);
  });

  it('opens a lightbox when an image is clicked', () => {
    render(<PostImages urls={URLS} alt="Fake bank SMS" />);
    fireEvent.click(screen.getByLabelText('View image 1 of 2'));
    expect(screen.getByRole('dialog')).toBeInTheDocument();
    expect(screen.getByText(/redacted screenshot 1 of 2/i)).toBeInTheDocument();
  });

  it('steps between images and closes on Escape', () => {
    render(<PostImages urls={URLS} alt="Fake bank SMS" />);
    fireEvent.click(screen.getByLabelText('View image 2 of 2'));
    expect(screen.getByText(/redacted screenshot 2 of 2/i)).toBeInTheDocument();

    fireEvent.click(screen.getByLabelText('Next image'));
    expect(screen.getByText(/redacted screenshot 1 of 2/i)).toBeInTheDocument();

    fireEvent.keyDown(window, { key: 'Escape' });
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('hides navigation for a single image', () => {
    render(<PostImages urls={[URLS[0]]} alt="Fake bank SMS" />);
    fireEvent.click(screen.getByLabelText('View image 1 of 1'));
    expect(screen.queryByLabelText('Next image')).not.toBeInTheDocument();
  });

  it('blurs concealed evidence until it is revealed', () => {
    render(
      <PostImages urls={[URLS[0]]} alt="Fake bank SMS" concealUntilRevealed />,
    );
    const img = screen.getByAltText('Fake bank SMS — redacted screenshot 1');
    expect(img.className).toMatch(/blur-md/);

    fireEvent.click(screen.getByLabelText('Reveal image'));
    expect(
      screen.getByAltText('Fake bank SMS — redacted screenshot 1').className,
    ).not.toMatch(/blur-md/);
  });
});
