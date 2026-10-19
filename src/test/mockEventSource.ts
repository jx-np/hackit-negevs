/**
 * A minimal `EventSource` stand-in for jsdom (which has no `EventSource`).
 *
 * Every instance registers itself in `MockEventSource.instances` so a test can
 * grab the last one and push server events into it.
 */
export class MockEventSource {
  static instances: MockEventSource[] = [];

  /** Ready state constants (mirroring the DOM `EventSource` ones). */
  static readonly CONNECTING = 0;
  static readonly OPEN = 1;
  static readonly CLOSED = 2;

  readonly url: string;
  readonly withCredentials = false;
  readyState: number = MockEventSource.CONNECTING;
  onerror: ((event: Event) => void) | null = null;
  onmessage: ((event: MessageEvent<string>) => void) | null = null;

  private listeners = new Map<string, Set<(event: Event) => void>>();

  constructor(url: string | URL) {
    this.url = String(url);
    MockEventSource.instances.push(this);
  }

  addEventListener(type: string, listener: (event: Event) => void) {
    const set = this.listeners.get(type) ?? new Set();
    set.add(listener);
    this.listeners.set(type, set);
  }

  removeEventListener(type: string, listener: (event: Event) => void) {
    this.listeners.get(type)?.delete(listener);
  }

  close() {
    this.readyState = MockEventSource.CLOSED;
  }

  /** Marks the stream as established (as the server's `ready` event would). */
  open() {
    this.readyState = MockEventSource.OPEN;
  }

  /** Pushes a named server event with a JSON payload into the stream. */
  emit(type: string, data?: unknown) {
    const event = new MessageEvent(type, {
      data: data === undefined ? '' : JSON.stringify(data),
    });
    for (const listener of this.listeners.get(type) ?? []) {
      listener(event);
    }
  }

  /** Pushes a transport-level error (the stream failed or is reconnecting). */
  emitError(closed = false) {
    if (closed) this.readyState = MockEventSource.CLOSED;
    const event = new Event('error');
    for (const listener of this.listeners.get('error') ?? []) {
      listener(event);
    }
  }

  /** Number of listeners registered for an event type (for assertions). */
  listenerCount(type: string): number {
    return this.listeners.get(type)?.size ?? 0;
  }
}

/** Removes every recorded instance (call between tests). */
export function resetEventSources() {
  MockEventSource.instances = [];
}

/** The most recently constructed `EventSource`. */
export function lastEventSource(): MockEventSource {
  const instance = MockEventSource.instances.at(-1);
  if (!instance) throw new Error('No EventSource was created');
  return instance;
}

/**
 * Installs the stub on `globalThis` (jsdom provides no `EventSource`).
 *
 * A plain assignment is used rather than `vi.stubGlobal` so that a test's
 * `vi.unstubAllGlobals()` doesn't remove the stub.
 */
export function installEventSourceStub() {
  (globalThis as { EventSource?: unknown }).EventSource = MockEventSource;
}
