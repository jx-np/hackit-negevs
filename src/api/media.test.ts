import { describe, expect, it } from 'vitest';
import { uploadMedia, validateMediaFile } from './media';

function makeFile(name: string, type: string, size = 100): File {
  const blob = new Blob(['x'.repeat(size)], { type });
  return new File([blob], name, { type });
}

describe('validateMediaFile', () => {
  it('accepts a small image', () => {
    expect(validateMediaFile(makeFile('a.png', 'image/png'))).toBeNull();
  });

  it('rejects a non-image', () => {
    expect(validateMediaFile(makeFile('a.pdf', 'application/pdf'))).toMatch(
      /image file/i,
    );
  });

  it('rejects an oversized image', () => {
    const big = makeFile('big.png', 'image/png', 6 * 1024 * 1024);
    expect(validateMediaFile(big)).toMatch(/too large/i);
  });
});

describe('uploadMedia (mock scaffold)', () => {
  it('returns an object URL and the file name', async () => {
    const media = await uploadMedia(makeFile('evidence.png', 'image/png'));
    expect(media.url).toBeTruthy();
    expect(media.name).toBe('evidence.png');
  });
});
