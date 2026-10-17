import { afterEach, describe, expect, it, vi } from 'vitest';
import {
  deleteUpload,
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

function noContentResponse(): Response {
  return {
    ok: true,
    status: 204,
    headers: { get: () => '' },
    json: async () => {
      throw new Error('no body');
    },
    text: async () => '',
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
  it('polls the upload status and resolves once it reports ready', async () => {
    const statuses = ['processing', 'processing', 'ready'];
    let call = 0;
    const fetchMock = vi.fn(async () =>
      jsonResponse({
        upload_id: '12',
        media_type: 'image/png',
        status: statuses[Math.min(call++, statuses.length - 1)],
      }),
    );
    vi.stubGlobal('fetch', fetchMock);

    const upload = await waitForRedaction('12', { intervalMs: 1 });
    expect(upload.status).toBe('ready');
    expect(String(fetchMock.mock.calls[0][0])).toContain('/uploads/12');
  });

  it('rejects when the upload fails (redaction service unavailable)', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async () =>
        jsonResponse({
          upload_id: '12',
          media_type: 'image/png',
          status: 'failed',
        }),
      ),
    );
    await expect(waitForRedaction('12', { intervalMs: 1 })).rejects.toThrow(
      /could not redact/i,
    );
  });
});

describe('deleteUpload', () => {
  it('sends DELETE /uploads/{id} and resolves on 204', async () => {
    const fetchMock = vi.fn(async () => noContentResponse());
    vi.stubGlobal('fetch', fetchMock);

    await expect(deleteUpload('12')).resolves.toBeUndefined();

    const [url, init] = fetchMock.mock.calls[0] as unknown as [
      string,
      RequestInit,
    ];
    expect(url).toContain('/uploads/12');
    expect(init.method).toBe('DELETE');
  });

  it('treats a 404 as success (already gone or not ours)', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async () =>
        jsonResponse({ error: { code: 'not_found', message: 'nope' } }, 404),
      ),
    );
    await expect(deleteUpload('does-not-exist')).resolves.toBeUndefined();
  });

  it('rethrows other errors (e.g. 401 unauthenticated)', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async () =>
        jsonResponse(
          { error: { code: 'unauthorized', message: 'login required' } },
          401,
        ),
      ),
    );
    await expect(deleteUpload('12')).rejects.toThrow();
  });
});
