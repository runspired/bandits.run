import { getDevice } from './device';
import { getDevicePreferences } from './preferences';

export type LocationPermissionState = 'granted' | 'denied' | 'prompt' | 'unavailable';

/**
 * Manager for location services and permissions
 */
export class LocationServicesManager {
  /**
   * Check the current permission state for geolocation
   */
  async checkPermissionState(): Promise<LocationPermissionState> {
    const device = getDevice();

    if (!device.supportsGeolocation) {
      return 'unavailable';
    }

    // Check Permissions API if available
    if ('permissions' in navigator) {
      try {
        const result = await navigator.permissions.query({ name: 'geolocation' });
        return result.state as LocationPermissionState;
      } catch {
        // Permissions API might not be fully supported
        // Fall back to attempting to get location
      }
    }

    // Fallback: we can't know without asking
    return 'prompt';
  }

  /**
   * Request location permission
   * @param backgroundAccess - Whether to request background location access (always vs while-using)
   */
  async requestPermission(backgroundAccess: boolean = false): Promise<LocationPermissionState> {
    const device = getDevice();

    if (!device.supportsGeolocation) {
      return 'unavailable';
    }

    return new Promise((resolve) => {
      navigator.geolocation.getCurrentPosition(
        () => {
          // Success - permission granted
          const preferences = getDevicePreferences();
          preferences.enableLocationServices = true;
          preferences.locationPermissionType = backgroundAccess ? 'always' : 'while-using';
          resolve('granted');
        },
        (error) => {
          // Error - permission denied or unavailable
          if (error.code === error.PERMISSION_DENIED) {
            resolve('denied');
          } else {
            resolve('unavailable');
          }
        },
        {
          enableHighAccuracy: false,
          timeout: 5000,
        }
      );
    });
  }

  /**
   * Disable location services
   */
  disableLocationServices(): void {
    const preferences = getDevicePreferences();
    preferences.enableLocationServices = false;
    preferences.locationPermissionType = null;
  }

  /**
   * Get platform-specific instructions for enabling location services
   */
  getPlatformInstructions(): { title: string; steps: string[] } {
    const device = getDevice();

    switch (device.platform) {
      case 'ios':
        return {
          title: 'Enable Location Services on iOS',
          steps: [
            'Open the Settings app',
            'Scroll down and tap on your browser (Safari, Chrome, etc.)',
            'Tap on "Location"',
            'Select "While Using the App" or "Always"',
          ],
        };
      case 'android':
        return {
          title: 'Enable Location Services on Android',
          steps: [
            'Open the Settings app',
            'Tap on "Apps" or "Applications"',
            'Find and tap on your browser (Chrome, Firefox, etc.)',
            'Tap on "Permissions"',
            'Tap on "Location"',
            'Select "Allow only while using the app" or "Allow all the time"',
          ],
        };
      default:
        return {
          title: 'Enable Location Services',
          steps: [
            'Click on the location icon in your browser\'s address bar',
            'Select "Allow" for location access',
            'If blocked, you may need to reset permissions in browser settings',
          ],
        };
    }
  }
}

let locationServicesInstance: LocationServicesManager | null = null;

/**
 * Get the singleton LocationServicesManager instance
 */
export function getLocationServices(): LocationServicesManager {
  if (!locationServicesInstance) {
    locationServicesInstance = new LocationServicesManager();
  }
  return locationServicesInstance;
}
