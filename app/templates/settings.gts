import { pageTitle } from 'ember-page-title';
import { on } from '@ember/modifier';
import Component from '@glimmer/component';
import ThemedPage from '#layout/themed-page.gts';
import { getDevicePreferences } from '#app/core/preferences.ts';
import { fn } from '@ember/helper';
import { not } from '#app/utils/comparison.ts';
import FaIcon from '#ui/fa-icon.gts';
import { faDownload, faCircleCheck } from '@fortawesome/free-solid-svg-icons';

class SettingsPage extends Component {
  preferences = getDevicePreferences();

  togglePWA = async () => {
    if (this.preferences.isProcessing) return;

    if (this.preferences.downloadForOffline) {
      await this.preferences.uninstallPWA();
    } else {
      await this.preferences.installPWA();
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
