import { field, PersistedResource } from './persisted-resource';
import { matchMedia } from './reactive-match-media';

let devicePreferencesInstance: DevicePreferences | null = null;

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

  @matchMedia('(prefers-reduced-motion: reduce)')
  prefersReducedMotion: boolean = false;

  static create() {
    return getDevicePreferences();
  }
}
