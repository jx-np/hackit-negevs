import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { useState } from 'react';
import { afterEach, beforeAll, describe, expect, it, vi } from 'vitest';
import { MediaPicker, type PickedImage } from './MediaPicker';

beforeAll(() => {
  // jsdom does not implement object URLs.
  Object.defineProperty(URL, 'createObjectURL', {
    writable: true,
    value: vi.fn(() => 'blob:redacted-preview'),
  });
  Object.defineProperty(URL, 'revokeObjectURL', {
    writable: true,
    value: vi.fn(),
  });
});

afterEach(() => {
  vi.unstubAllGlobals();
});

/** Harness that owns the picked-image state, mirroring the report form. */
function Harness() {
  const [images, setImages] = useState<PickedImage[]>([]);
  return (
    <>
      <MediaPicker value={images} onChange={setImages} />
      <output data-testid="upload-ids">
        {images
          .filter((i) => i.status === 'ready')
          .map((i) => i.uploadId)
          .join(',')}
      </output>
    </>
  );
}

function pngFile(name = 'evidence.png') {
  return new File([new Blob(['x'], { type: 'image/png' })], name, {
    type: 'image/png',
  });
}

/**
 * Stub fetch for the upload flow: POST /uploads schedules a check, the poll
 * returns `checkStatus`, and the redacted image endpoint returns bytes.
 */
function stubUploadFlow(checkStatus: 'processing' | 'ready' | 'failed') {
  const fetchMock = vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = typeof input === 'string' ? input : input.toString();
    const method = (init?.method ?? 'GET').toUpperCase();

    if (url.includes('/uploads') && method === 'POST') {
      return {
        ok: true,
        status: 201,
        headers: { get: () => '' },
        json: async () => ({
          upload_id: '12',
          media_type: 'image/png',
          check_id: '56',
          status: 'processing',
        }),
      } as unknown as Response;
    }
    if (url.includes('/detection/56/redacted-image')) {
      return {
        ok: true,
        status: 200,
        headers: { get: () => '' },
        blob: async () => new Blob(['redacted'], { type: 'image/png' }),
      } as unknown as Response;
    }
    if (url.includes('/detection/56')) {
      return {
        ok: true,
        status: 200,
        headers: { get: () => '' },
        json: async () => ({ check_id: '56', status: checkStatus }),
      } as unknown as Response;
    }
    return {
      ok: false,
      status: 404,
      headers: { get: () => '' },
      json: async () => ({ error: { code: 'not_found', message: 'no route' } }),
    } as unknown as Response;
  });

  vi.stubGlobal('fetch', fetchMock);
  return fetchMock;
}

async function pick(file: File) {
  // `user.upload` respects the input's `accept` attribute, which would mask the
  // validation path under test, so dispatch the change event directly.
  fireEvent.change(screen.getByLabelText(/upload evidence image/i), {
    target: { files: [file] },
  });
  await waitFor(() => expect(screen.getByLabelText(/upload evidence image/i)).toBeInTheDocument());
}

describe('MediaPicker', () => {
  it('uploads the screenshot, polls redaction, and previews the redacted copy', async () => {
    const fetchMock = stubUploadFlow('ready');
    render(<Harness />);

    await pick(pngFile());

    await waitFor(() =>
      expect(screen.getByTestId('upload-ids')).toHaveTextContent('12'),
    );

    // The preview is the redacted derivative, never the local raw file.
    const img = screen.getByAltText('Redacted evidence: evidence.png');
    expect(img).toHaveAttribute('src', 'blob:redacted-preview');
    expect(screen.getByText(/redacted preview/i)).toBeInTheDocument();

    const urls = fetchMock.mock.calls.map((c) => String(c[0]));
    expect(urls.some((u) => u.includes('/uploads'))).toBe(true);
    expect(urls.some((u) => u.includes('/detection/56/redacted-image'))).toBe(
      true,
    );
  });

  it('rejects a file type the backend does not accept without uploading', async () => {
    const fetchMock = stubUploadFlow('ready');
    render(<Harness />);

    await pick(new File([new Blob(['x'])], 'note.pdf', { type: 'application/pdf' }));

    expect(await screen.findByText(/jpeg, png, or webp/i)).toBeInTheDocument();
    expect(fetchMock).not.toHaveBeenCalled();
    expect(screen.getByTestId('upload-ids')).toBeEmptyDOMElement();
  });

  it('surfaces an error and stays unpublishable when redaction fails', async () => {
    stubUploadFlow('failed');
    render(<Harness />);

    await pick(pngFile());

    expect(await screen.findByText(/could not redact/i)).toBeInTheDocument();
    expect(screen.getByTestId('upload-ids')).toBeEmptyDOMElement();
  });

  it('stays publishable when the owner-only preview cannot be fetched', async () => {
    // An anonymous (demo) upload has no owner to fetch the redacted image for.
    const base = stubUploadFlow('ready');
    vi.stubGlobal(
      'fetch',
      vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
        const url = String(input);
        if (url.includes('/redacted-image')) {
          return {
            ok: false,
            status: 404,
            headers: { get: () => '' },
            json: async () => ({
              error: { code: 'not_found', message: 'Not found' },
            }),
          } as unknown as Response;
        }
        return base(input, init);
      }),
    );

    render(<Harness />);
    await pick(pngFile());

    await waitFor(() =>
      expect(screen.getByTestId('upload-ids')).toHaveTextContent('12'),
    );
    expect(
      screen.getByText(/preview unavailable/i),
    ).toBeInTheDocument();
  });
});
