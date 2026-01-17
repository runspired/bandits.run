import { getDevice } from './device';
import { field, LocalResource } from './utils/storage-resource';
import { matchMedia } from './reactive/match-media';
import { cached, tracked } from '@glimmer/tracking';
import { registerSW } from 'virtual:pwa-register';

/**
 * Possible download statuses
 *
 * - 'unavailable': Service worker not supported
 * - 'offline': Device is offline
 * - 'available': Ready to download
 * - 'installing': Installation in progress
 * - 'installed': Installed but not yet activated
 * - 'activating': Activation in progress
 * - 'activated': Successfully activated
 * - 'error': Failed to download
 */
export type DownloadStatusType = 'unavailable' | 'offline' | 'available' | 'installing' | 'installed' | 'activating' | 'activated' | 'error';

const DEBUG = localStorage.getItem('debug-serviceWorker') === 'true';
function log(msg: string) {
  if (DEBUG) {
    console.log(`[ServiceWorker] ${msg}`);
  }
}

let devicePreferencesInstance: DevicePreferences | null = null;

export async function checkServiceWorker() {
  const shouldBeInstalled = getDevicePreferences().downloadForOffline;

  // if its not installed, but should be, install it.
  if (shouldBeInstalled && !('serviceWorker' in navigator)) {
    log('Service workers not supported in this browser. Cannot install offline mode.');
    // Service workers not supported
    return;
  }

  const registrations = await navigator.serviceWorker.getRegistrations();

  const isInstalled = registrations.length > 0;

  // Check if a service worker is currently installing or waiting
  const isInstalling = registrations.some(
    reg => reg.installing !== null || reg.waiting !== null
  );

  log(`Service worker installed: ${isInstalled}, installing: ${isInstalling}, User preference: ${shouldBeInstalled}`);

  if (shouldBeInstalled && !isInstalled) {
    void getDevicePreferences().installPWA();
    log('Service worker installed for offline use as per user preference.');
  } else if (!shouldBeInstalled && isInstalled) {
    // Uninstall the service worker
    for (const registration of registrations) {
      await registration.unregister();
      log('Service worker uninstalled as per user preference.');
    }
  } else {
    // No action needed
    log('Service worker status matches user preference. No action taken.');
  }
}

/**
 * Singleton accessor for DevicePreferences
 * providing reactive access to local user device preferences.
 *
 * See {@link DevicePreferences}
 * - {@link DevicePreferences.useMetricWeather | useMetricWeather}
 * - {@link DevicePreferences.useMetricDistance | useMetricDistance}
 * - {@link DevicePreferences.useCompactMode | useCompactMode}
 * - {@link DevicePreferences.showTimezoneDifferences | showTimezoneDifferences}
 */
export function getDevicePreferences(): DevicePreferences {
  if (!devicePreferencesInstance) {
    devicePreferencesInstance = new DevicePreferences();
  }
  return devicePreferencesInstance;
}

/**
 * Reactive user device preferences.
 *
 * This resource is persisted locally on the user's device
 *
 * - {@link DevicePreferences.useMetricWeather | useMetricWeather}
 * - {@link DevicePreferences.useMetricDistance | useMetricDistance}
 * - {@link DevicePreferences.useCompactMode | useCompactMode}
 * - {@link DevicePreferences.showTimezoneDifferences | showTimezoneDifferences}
 */
@LocalResource('device-preferences')
export class DevicePreferences {
  @field
  useMetricWeather: boolean = false;

  @field
  useMetricDistance: boolean = false;

  @field
  useCompactMode: boolean = false;

  @field
  showTimezoneDifferences: boolean = true;

  @field
  downloadForOffline: boolean = false;

  @field
  enableLocationServices: boolean = false;

  @field
  locationPermissionType: 'while-using' | 'always' | null = null;

  @matchMedia('(prefers-reduced-motion: reduce)')
  prefersReducedMotion: boolean = false;

  /**
   * Whether a registration/unregistration process is ongoing
   */
  @tracked
  isProcessing: boolean = false;

  /**
   * Installation state
   */
  @tracked
  installationState: 'installed' | 'activating' | 'activated' | null = null;

  @cached
  get downloadStatus(): DownloadStatusType {
    const device = getDevice();
    if (!device.supportsServiceWorker)
      return 'unavailable';

    if (!device.hasNetwork) {
      return 'offline';
    }

    if (!this.downloadForOffline)
      return 'available';

    if (this.isProcessing)
      return this.installationState ?? 'installing';

    return 'activated';
  }

  // eslint-disable-next-line @typescript-eslint/require-await
  async installPWA(): Promise<void> {
    if (this.isProcessing) return;

    this.isProcessing = true;
    this.downloadForOffline = true;

    try {
      if ('serviceWorker' in navigator) {
        log('Starting PWA installation process.');

        registerSW({
          immediate: true,
          onRegisteredSW: (_swScriptUrl: string, registration?: ServiceWorkerRegistration) => {
            log('PWA service worker registered successfully.');

            // Monitor the service worker installation and activation
            if (registration) {
              const sw = registration.installing || registration.waiting || registration.active;

              if (sw) {
                if (sw.state === 'activated') {
                  log('Service worker is already activated.');
                  this.installationState = 'activated';
                  this.isProcessing = false;
                } else {
                  log(`Service worker state: ${sw.state}. Waiting for activation...`);
                  sw.addEventListener('statechange', (e) => {
                    const target = e.target as ServiceWorker;
                    log(`Service worker state changed to: ${target.state}`);
                    this.installationState = target.state as 'installed' | 'activating' | 'activated';
                    if (target.state === 'activated') {
                      log('Service worker activated. Assets cached.');
                      this.isProcessing = false;
                    }
                  });
                }
              } else {
                this.isProcessing = false;
              }
            } else {
              log('No registration object available after service worker registration.');
              this.isProcessing = false;
            }
          },
          onRegisterError: (error: Error) => {
            console.error('Failed to install PWA:', error);
            alert('Failed to install offline mode. Please try again.');
            this.isProcessing = false;
            this.downloadForOffline = false;
          },
        });
      }
    } catch (error) {
      console.error('Failed to install PWA:', error);
      alert('Failed to install offline mode. Please try again.');
      this.isProcessing = false;
      this.downloadForOffline = false;
    }
  }

  async uninstallPWA(): Promise<void> {
    if (this.isProcessing) return;

    this.isProcessing = true;
    this.downloadForOffline = false;

    try {
      if ('serviceWorker' in navigator) {
        const registrations = await navigator.serviceWorker.getRegistrations();

        for (const registration of registrations) {
          await registration.unregister();
        }

        // Clear all caches
        if ('caches' in window) {
          const cacheNames = await caches.keys();
          await Promise.all(
            cacheNames.map(cacheName => caches.delete(cacheName))
          );
        }

        // Reload the page to complete uninstall
        // eslint-disable-next-line warp-drive/no-legacy-request-patterns
        window.location.reload();
      }
    } catch (error) {
      console.error('Failed to uninstall PWA:', error);
      alert('Failed to uninstall offline mode. Please try again.');
      this.isProcessing = false;
      this.downloadForOffline = true;
    }
  }

  static create() {
    return getDevicePreferences();
  }
}
