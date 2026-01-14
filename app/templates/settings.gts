import { pageTitle } from 'ember-page-title';
import { on } from '@ember/modifier';
import Component from '@glimmer/component';
import ThemedPage from '#layout/themed-page.gts';
import { getDevicePreferences } from '#app/core/preferences.ts';
import { fn } from '@ember/helper';
import { not } from '#app/utils/comparison.ts';
import FaIcon from '#ui/fa-icon.gts';
import { faDownload, faCircleCheck, faLocationDot } from '@fortawesome/free-solid-svg-icons';
import { getLocationServices } from '#app/core/location-services.ts';
import { getDevice } from '#app/core/device.ts';
import { tracked } from '@glimmer/tracking';

class SettingsPage extends Component {
  preferences = getDevicePreferences();
  locationServices = getLocationServices();
  device = getDevice();

  @tracked showLocationInstructions = false;
  @tracked isRequestingPermission = false;

  togglePWA = async () => {
    if (this.preferences.isProcessing) return;

    if (this.preferences.downloadForOffline) {
      await this.preferences.uninstallPWA();
    } else {
      await this.preferences.installPWA();
    }
  };

  toggleLocationServices = async () => {
    if (this.isRequestingPermission) return;

    if (this.preferences.enableLocationServices) {
      // User is turning off location services
      this.locationServices.disableLocationServices();
    } else {
      // Check if location services are available
      const permissionState = await this.locationServices.checkPermissionState();

      if (permissionState === 'unavailable') {
        // Show platform-specific instructions
        this.showLocationInstructions = true;
        return;
      }

      if (permissionState === 'denied') {
        // Permission was previously denied, show instructions to re-enable
        this.showLocationInstructions = true;
        return;
      }

      // Ask user for permission type preference
      const backgroundAccess = confirm(
        'Would you like to enable location access even when the app is in the background?\n\n' +
        'Click OK for "Always" or Cancel for "While Using the App"'
      );

      this.isRequestingPermission = true;
      const result = await this.locationServices.requestPermission(backgroundAccess);
      this.isRequestingPermission = false;

      if (result === 'denied' || result === 'unavailable') {
        // Show instructions if permission was denied
        this.showLocationInstructions = true;
      }
    }
  };

  closeInstructions = () => {
    this.showLocationInstructions = false;
  };

  <template>
    {{pageTitle "Settings | The Bandits"}}

    <ThemedPage>
      <div class="settings-page">
        <h1>Settings</h1>

        <section class="settings-section">
          <h2>Offline Mode</h2>

          <div class="offline-mode-toggle">
            <div class="offline-mode-info">
              <div class="offline-mode-icon">
                {{#if this.preferences.downloadForOffline}}
                  <FaIcon @icon={{faCircleCheck}} @class="icon-installed" />
                {{else}}
                  <FaIcon @icon={{faDownload}} @class="icon-not-installed" />
                {{/if}}
              </div>
              <div class="offline-mode-text">
                <h3>
                  {{#if this.preferences.downloadForOffline}}
                    Offline Mode Installed
                  {{else}}
                    Install for Offline Use
                  {{/if}}
                </h3>
                <p>
                  {{#if this.preferences.downloadForOffline}}
                    Access run info without an internet connection.
                    <br><br>
                    Maps for runs can be downloaded individually when this
                    mode is enabled.
                  {{else}}
                    Download the app to use it offline
                  {{/if}}
                </p>
              </div>
            </div>

            <label class="toggle-switch">
              <input
                type="checkbox"
                checked={{this.preferences.downloadForOffline}}
                {{on "change" this.togglePWA}}
                disabled={{this.preferences.isProcessing}}
              />
              <span class="toggle-slider"></span>
            </label>
          </div>
        </section>

        <section class="settings-section">
          <h2>Location Services</h2>

          <div class="offline-mode-toggle">
            <div class="offline-mode-info">
              <div class="offline-mode-icon">
                {{#if this.preferences.enableLocationServices}}
                  <FaIcon @icon={{faCircleCheck}} @class="icon-installed" />
                {{else}}
                  <FaIcon @icon={{faLocationDot}} @class="icon-not-installed" />
                {{/if}}
              </div>
              <div class="offline-mode-text">
                <h3>
                  {{#if this.preferences.enableLocationServices}}
                    Location Services Enabled
                  {{else}}
                    Enable Location Services
                  {{/if}}
                </h3>
                <p>
                  {{#if this.preferences.enableLocationServices}}
                    Location services are enabled for maps.
                    {{#if this.preferences.locationPermissionType}}
                      <br><br>
                      Permission: {{this.preferences.locationPermissionType}}
                    {{/if}}
                  {{else}}
                    Allow the app to access your location for map features.
                  {{/if}}
                </p>
              </div>
            </div>

            <label class="toggle-switch">
              <input
                type="checkbox"
                checked={{this.preferences.enableLocationServices}}
                {{on "change" this.toggleLocationServices}}
                disabled={{this.isRequestingPermission}}
              />
              <span class="toggle-slider"></span>
            </label>
          </div>
        </section>

        <section class="settings-section">
          <h2>Display Preferences</h2>

          <label class="settings-option">
            <input
              type="checkbox"
              checked={{this.preferences.useMetricWeather}}
              {{on "change" (fn (mut this.preferences.useMetricWeather) (not this.preferences.useMetricWeather))}}
            />
            <span>Use Metric for Weather (°C)</span>
          </label>

          <label class="settings-option">
            <input
              type="checkbox"
              checked={{this.preferences.useMetricDistance}}
              {{on "change" (fn (mut this.preferences.useMetricDistance) (not this.preferences.useMetricDistance))}}
            />
            <span>Use Metric for Distance (km)</span>
          </label>

          <label class="settings-option">
            <input
              type="checkbox"
              checked={{this.preferences.useCompactMode}}
              {{on "change" (fn (mut this.preferences.useCompactMode) (not this.preferences.useCompactMode))}}
            />
            <span>Use Compact Mode</span>
          </label>

          <label class="settings-option">
            <input
              type="checkbox"
              checked={{this.preferences.showTimezoneDifferences}}
              {{on "change" (fn (mut this.preferences.showTimezoneDifferences) (not this.preferences.showTimezoneDifferences))}}
            />
            <span>Show Timezone Differences</span>
          </label>
        </section>
      </div>

      {{! Platform Instructions Dialog }}
      {{#if this.showLocationInstructions}}
        <div class="location-instructions-overlay">
          <div class="location-instructions-panel">
            {{#let (this.locationServices.getPlatformInstructions) as |instructions|}}
              <h2>{{instructions.title}}</h2>
              <p>
                {{#if this.device.supportsGeolocation}}
                  Location services are currently blocked. Follow these steps to enable them:
                {{else}}
                  Location services are not available on this device. If you're using a supported device, follow these steps:
                {{/if}}
              </p>

              <ol class="instruction-steps">
                {{#each instructions.steps as |step|}}
                  <li>{{step}}</li>
                {{/each}}
              </ol>

              <button
                type="button"
                class="close-button"
                {{on "click" this.closeInstructions}}
              >
                Close
              </button>
            {{/let}}
          </div>
        </div>
      {{/if}}
    </ThemedPage>
  </template>
}

export default SettingsPage;
