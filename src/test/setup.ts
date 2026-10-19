import '@testing-library/jest-dom/vitest';
import { cleanup } from '@testing-library/react';
import { afterEach, vi } from 'vitest';
import { installEventSourceStub, resetEventSources } from './mockEventSource';

// jsdom doesn't implement EventSource; the live discussion stream needs one.
installEventSourceStub();

// Clean up the DOM after every test.
afterEach(() => {
  cleanup();
  resetEventSources();
});

// jsdom doesn't implement matchMedia; provide a stub for AppearanceContext.
if (!window.matchMedia) {
  window.matchMedia = vi.fn().mockImplementation((query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  }));
}

// jsdom doesn't implement IntersectionObserver; used by infinite scroll.
class MockIntersectionObserver {
  observe = vi.fn();
  unobserve = vi.fn();
  disconnect = vi.fn();
  takeRecords = vi.fn(() => []);
  root = null;
  rootMargin = '';
  thresholds = [];
}
globalThis.IntersectionObserver =
  MockIntersectionObserver as unknown as typeof IntersectionObserver;

// jsdom's object-URL support is unreliable with File/Blob internals; stub it
// deterministically for the media upload scaffold.
URL.createObjectURL = vi.fn(() => 'blob:mock-object-url');
URL.revokeObjectURL = vi.fn();
