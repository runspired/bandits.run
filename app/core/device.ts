import { FIVE_MINUTES_MS, FIVE_SECONDS_MS } from '#app/utils/consts.ts';
import { tracked } from '@glimmer/tracking';

const host = location.protocol+'//'+location.hostname+(location.port ? ':'+location.port: '');

function detectRequestStatus(entry: PerformanceResourceTiming): boolean | null {
  // Skip our own network check requests to avoid feedback loops
  if (entry.name.includes('offline-check-px.png')) {
    return null;
  }

  // skip cached responses
  if ('deliveryType' in Response && Response.deliveryType === 'cache') {
    return null;
  }

  // if the request has a duration but no responseEnd,
  // it likely failed due to interruption, network loss, etc.
  if (entry.duration > 0 && entry.responseEnd === 0) {
    return false;
  }

  // request timeout indicates network issues
  if (entry.responseStatus === 408) {
    return false;
  }

  // filter out cors requests that we can't get timing info for
  if (!entry.name.startsWith(host) && entry.responseStart === 0 && entry.transferSize === 0 && entry.decodedBodySize === 0) {
    return null;
  }

  // A resource with zero transferSize and zero decodedBodySize
  // that isn't from cache (responseStart === 0) indicates a failed load
  const durationIndicatesFailure = (
    entry.responseStart === 0 ||
    entry.responseEnd === 0
  ) && entry.duration > 0;
  const contentSizeIndicatesFailure = (
    entry.transferSize === 0 &&
    entry.decodedBodySize === 0
  );

  if (durationIndicatesFailure && contentSizeIndicatesFailure) {
    return false;
  }

  // A resource with a valid responseStart and content size indicates success
  if (entry.responseEnd > 0 && entry.responseStart > 0 && (entry.transferSize > 0 || entry.decodedBodySize > 0)) {
    return true;
  }

  // otherwise, we can't determine
  return null;
}

let deviceInstance: ReactiveDevice | null = null;

/**
 * Get the singleton {@link ReactiveDevice} instance.
 *
 * If the instance does not already exist, it is created.
 */
export function getDevice(): ReactiveDevice {
  if (!deviceInstance) {
    deviceInstance = new ReactiveDevice();
  }
  return deviceInstance;
}

export class ReactiveDevice {
  /**
   * A reactive version of `navigator.onLine`
   *
   * This does not guarantee network reachability, it only
   * indicates if the device is online according to the browser
   * which may mean you are connected to a local network
   * without internet access.
   *
   * @returns {boolean} true if the browser is online, false if offline
   */
  @tracked hasLocalNetwork: boolean = navigator.onLine;

  /**
   * A reactive property indicating if the device has
   * the ability to reach beyond the local network.
   */
  @tracked hasNetwork: boolean = navigator.onLine;
  /**
   * A reactive version of `document.visibilityState === 'hidden'`
   *
   * @returns {boolean} true if the document is hidden, false if visible
   */
  @tracked isHidden: boolean = document.visibilityState === 'hidden';

  constructor() {
    window.addEventListener('online', () => { this.hasLocalNetwork = true; void this.#monitorNetworkStatus(); }, { passive: true, capture: true });
    window.addEventListener('offline', () => { this.hasLocalNetwork = false; this.hasNetwork = false; }, { passive: true, capture: true });
    document.addEventListener('visibilitychange', () => { this.isHidden = document.visibilityState === 'hidden'; }, { passive: true, capture: true });

    const observer = new PerformanceObserver((list: PerformanceObserverEntryList) => {
      const entries = list.getEntries() as PerformanceResourceTiming[];
      for (const entry of entries) {
        const status = detectRequestStatus(entry);

        if (status === null) {
          continue;
        }

        if (status === false) {
          // begin monitoring network status on failure
          this.hasNetwork = false;
          void this.#monitorNetworkStatus();
          return;
        }

        if (status === true) {
          // we may have recovered network access
          this.hasNetwork = true;
          void this.forceNetworkCheck();
          return;
        }
      }
    });
    observer.observe({ entryTypes: ["resource"] });
  }

  /**
   * Tracks the number of consecutive failed network checks
   * to determine when to back off on further checks.
   */
  #attempts: number = 0;
  /**
   * Holds the timeout ID for the next network check attempt.
   */
  #nextAttempt: number | null = null;

  /**
   * Perform a network check by fetching a small resource
   * to determine if the network is truly reachable.
   *
   * @returns true if the network is reachable, false otherwise
   */
  async #performNetworkCheck(): Promise<boolean> {
    try {
      const base = location.protocol+'//'+location.hostname+(location.port ? ':'+location.port: '');
      // eslint-disable-next-line warp-drive/no-external-request-patterns
      const result = await fetch(`${base}/offline-check-px.png`);
      return result.status >= 200 && result.status < 300;
    } catch {
      // browser blocked the request or similar network error
      return false;
    }
  }

  /**
   * Uses a progressive backoff strategy of network checks to monitor
   * the true online/offline status of the application.
   *
   * This is useful because `navigator.onLine` status of `true` does not
   * always mean that the network is actually reachable.
   */
  async #monitorNetworkStatus() {
    // no point in checking if we are offline locally
    if (!this.hasLocalNetwork) {
      if (this.#nextAttempt !== null) {
        clearTimeout(this.#nextAttempt);
        this.#nextAttempt = null;
      }
      this.hasNetwork = false;
      this.#attempts = 0;
      return;
    }

    // if we already have a next attempt scheduled, do nothing
    if (this.#nextAttempt !== null) {
      return;
    }

    const isAvailable = await this.#performNetworkCheck();

    // reset attempts on success
    if (isAvailable) {
      this.hasNetwork = true;
      this.#attempts = 0;

    // increase attempts on failure & retry
    } else {
      if (this.hasNetwork) {
        this.hasNetwork = false;
      }
      this.#attempts++;
      this.#nextAttempt = setTimeout(
        () => { this.#nextAttempt = null; void this.#monitorNetworkStatus() },
        Math.max(this.#attempts * FIVE_SECONDS_MS, FIVE_MINUTES_MS)
      );
    }
  }

  /**
   * Trigger an immediate network check
   */
  forceNetworkCheck: () => Promise<boolean> = async () => {
    if (this.#nextAttempt !== null) {
      clearTimeout(this.#nextAttempt);
      this.#nextAttempt = null;
    }
    await this.#monitorNetworkStatus();
    return this.hasNetwork;
  }

  static create(): ReactiveDevice {
    return getDevice();
  }
}
