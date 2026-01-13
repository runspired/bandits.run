import { pageTitle } from 'ember-page-title';
import { on } from '@ember/modifier';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import ThemedPage from '#layout/themed-page.gts';
import { getDevicePreferences } from '#app/core/preferences.ts';
import { fn } from '@ember/helper';
import { not } from '#app/utils/comparison.ts';
import FaIcon from '#ui/fa-icon.gts';
import { faDownload, faCircleCheck } from '@fortawesome/free-solid-svg-icons';

class SettingsPage extends Component {
  preferences = getDevicePreferences();

  @tracked isProcessing = false;

  togglePWA = async () => {
    if (this.isProcessing) return;

    if (this.preferences.pwaInstalled) {
      // Uninstall
      if (confirm('Are you sure you want to uninstall offline mode? This will remove cached data and require an internet connection to use the app.')) {
        this.isProcessing = true;
        await this.uninstallPWA();
      }
    } else {
      // Install
      this.isProcessing = true;
      await this.installPWA();
    }
  };

  installPWA = async () => {
    try {
      if ('serviceWorker' in navigator) {
        // @ts-expect-error virtual module
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const { registerSW } = await import('virtual:pwa-register') as { registerSW: (options: any) => Promise<void> };

        await registerSW({
          immediate: true,
          onRegistered: () => {
            this.preferences.pwaInstalled = true;
            this.isProcessing = false;
            // Reload to activate the service worker
            // eslint-disable-next-line warp-drive/no-legacy-request-patterns
            window.location.reload();
          },
          onRegisterError: (error: Error) => {
            console.error('Failed to install PWA:', error);
            alert('Failed to install offline mode. Please try again.');
            this.isProcessing = false;
          },
        });
      }
    } catch (error) {
      console.error('Failed to install PWA:', error);
      alert('Failed to install offline mode. Please try again.');
      this.isProcessing = false;
    }
  };

  uninstallPWA = async () => {
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

        // Update preference
        this.preferences.pwaInstalled = false;

        // Reload the page to complete uninstall
        // eslint-disable-next-line warp-drive/no-legacy-request-patterns
        window.location.reload();
      }
    } catch (error) {
      console.error('Failed to uninstall PWA:', error);
      alert('Failed to uninstall offline mode. Please try again.');
      this.isProcessing = false;
    }
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
                {{#if this.preferences.pwaInstalled}}
                  <FaIcon @icon={{faCircleCheck}} @class="icon-installed" />
                {{else}}
                  <FaIcon @icon={{faDownload}} @class="icon-not-installed" />
                {{/if}}
              </div>
              <div class="offline-mode-text">
                <h3>
                  {{#if this.preferences.pwaInstalled}}
                    Offline Mode Installed
                  {{else}}
                    Install for Offline Use
                  {{/if}}
                </h3>
                <p>
                  {{#if this.preferences.pwaInstalled}}
                    Access trail runs without an internet connection
                  {{else}}
                    Download the app to use it offline
                  {{/if}}
                </p>
              </div>
            </div>

            <label class="toggle-switch">
              <input
                type="checkbox"
                checked={{this.preferences.pwaInstalled}}
                {{on "change" this.togglePWA}}
                disabled={{this.isProcessing}}
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
    </ThemedPage>
  </template>
}

export default SettingsPage;
