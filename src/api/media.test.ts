import { afterEach, describe, expect, it, vi } from 'vitest';
import { uploadMedia, validateMediaFile } from './media';

afterEach(() => {
  vi.unstubAllGlobals();
});

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

describe('uploadMedia', () => {
  it('returns the uploaded URL and the file name', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async () => ({
        ok: true,
        status: 200,
        json: async () => ({ url: 'https://cdn.example.com/evidence.png' }),
      })),
    );
    const media = await uploadMedia(makeFile('evidence.png', 'image/png'));
    expect(media.url).toBe('https://cdn.example.com/evidence.png');
    expect(media.name).toBe('evidence.png');
  });
});
