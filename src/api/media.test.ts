import { afterEach, describe, expect, it, vi } from 'vitest';
import {
  MAX_MEDIA_BYTES,
  uploadMedia,
  validateMediaFile,
  waitForRedaction,
} from './media';

afterEach(() => {
  vi.unstubAllGlobals();
});

function makeFile(name: string, type: string, size = 100): File {
  const blob = new Blob(['x'.repeat(size)], { type });
  return new File([blob], name, { type });
}

function jsonResponse(body: unknown, status = 200): Response {
  return {
    ok: status >= 200 && status < 300,
    status,
    headers: { get: () => '' },
    json: async () => body,
    text: async () => JSON.stringify(body),
    blob: async () => new Blob(),
  } as unknown as Response;
}

describe('validateMediaFile', () => {
  it('accepts a small image', () => {
    expect(validateMediaFile(makeFile('a.png', 'image/png'))).toBeNull();
    expect(validateMediaFile(makeFile('a.jpg', 'image/jpeg'))).toBeNull();
    expect(validateMediaFile(makeFile('a.webp', 'image/webp'))).toBeNull();
  });

  it('rejects a non-image', () => {
    expect(validateMediaFile(makeFile('a.pdf', 'application/pdf'))).toMatch(
      /jpeg, png, or webp/i,
    );
  });

  it('rejects an image type the backend does not accept', () => {
    expect(validateMediaFile(makeFile('a.gif', 'image/gif'))).toMatch(
      /jpeg, png, or webp/i,
    );
  });

  it('rejects an image over the 10 MiB backend limit', () => {
    const big = makeFile('big.png', 'image/png', MAX_MEDIA_BYTES + 1);
    expect(validateMediaFile(big)).toMatch(/too large/i);
  });
});

describe('uploadMedia', () => {
  it('POSTs multipart form data and maps the upload response', async () => {
    const fetchMock = vi.fn(async () =>
      jsonResponse(
        {
          upload_id: '12',
          media_type: 'image/png',
          check_id: '56',
          status: 'processing',
        },
        201,
      ),
    );
    vi.stubGlobal('fetch', fetchMock);

    const media = await uploadMedia(makeFile('evidence.png', 'image/png'));

    expect(media).toEqual({
      uploadId: '12',
      mediaType: 'image/png',
      checkId: '56',
      name: 'evidence.png',
    });

    const [url, init] = fetchMock.mock.calls[0] as unknown as [
      string,
      RequestInit,
    ];
    expect(url).toContain('/uploads');
    expect(init.method).toBe('POST');
    const form = init.body as FormData;
    expect(form.get('image')).toBeInstanceOf(File);
    expect(form.get('locale')).toBe('en-SG');
    // The browser must set the multipart boundary, so Content-Type is omitted.
    expect(
      (init.headers as Record<string, string>)['Content-Type'],
    ).toBeUndefined();
  });
});

describe('waitForRedaction', () => {
  it('resolves once the check reports ready', async () => {
    const statuses = ['processing', 'processing', 'ready'];
    let call = 0;
    vi.stubGlobal(
      'fetch',
      vi.fn(async () =>
        jsonResponse({
          check_id: '56',
          status: statuses[Math.min(call++, statuses.length - 1)],
        }),
      ),
    );

    const check = await waitForRedaction('56', { intervalMs: 1 });
    expect(check.status).toBe('ready');
  });

  it('rejects when the check fails (redaction service unavailable)', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async () => jsonResponse({ check_id: '56', status: 'failed' })),
    );
    await expect(waitForRedaction('56', { intervalMs: 1 })).rejects.toThrow(
      /could not redact/i,
    );
  });
});
