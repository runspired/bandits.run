import { field, PersistedResource } from './persisted-resource';
import { matchMedia } from './reactive-match-media';
import { tracked } from '@glimmer/tracking';
import { registerSW } from 'virtual:pwa-register';

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
  log(`Service worker installed: ${isInstalled}, User preference: ${shouldBeInstalled}`);

  if (shouldBeInstalled && !isInstalled) {
    registerSW({
      immediate: true,
      onRegistered: () => {
        log('Reloading: Service worker registered for offline use as per user preference.');
        // Reload to activate the service worker
        // eslint-disable-next-line warp-drive/no-legacy-request-patterns
        window.location.reload();
      },
    });
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
@PersistedResource('device-preferences')
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

  @matchMedia('(prefers-reduced-motion: reduce)')
  prefersReducedMotion: boolean = false;

  @tracked
  isProcessing: boolean = false;

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
          onRegisteredSW: () => {
            log('PWA service worker registered successfully.');
            this.isProcessing = false;
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
