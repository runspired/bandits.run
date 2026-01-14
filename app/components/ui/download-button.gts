import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import FaIcon from '#ui/fa-icon.gts';
import { faDownload, faCheck, faX, faBan, faWifi, faHourglass } from '@fortawesome/free-solid-svg-icons';
import type { IconDefinition } from '@fortawesome/fontawesome-svg-core';
import { eq, not } from '#app/utils/comparison.ts';
import { scopedClass } from 'ember-scoped-css';
import './download-button.css';
import type { DownloadStatusType } from '#app/core/preferences.ts';

interface DownloadButtonSignature {
  Args: {
    /**
     * Current download/installation status
     * - 'offline': Device is offline
     * - 'unavailable': Service worker not supported (hidden)
     * - 'available': Ready to download (grey glow, clickable)
     * - 'installing': Installation in progress (rotating glow, not clickable)
     * - 'installed': Installed but not yet activated (green glow with checkmark, clickable)
     * - 'activating': Activation in progress (rotating glow, not clickable)
     * - 'activated': Successfully activated (green glow with checkmark, clickable)
     * - 'error': Failed to download (red glow, not clickable)
     */
    status: DownloadStatusType;

    /**
     * Download progress from 0-100 (only relevant when status is 'downloading')
     */
    progress?: number;

    /**
     * Callback when the button is clicked
     */
    onClick?: () => void;

    /**
     * Custom icon to use instead of the default download icon
     */
    icon?: IconDefinition;

    /**
     * Whether the button is disabled
     */
    disabled?: boolean;

    /**
     * Accessible label for screen readers
     */
    ariaLabel?: string;
  };
}

export default class DownloadButton extends Component<DownloadButtonSignature> {
  get icon() {
    return this.args.icon ?? faDownload;
  }

  get ariaLabel() {
    const status = this.args.status;
    const defaultLabels = {
      offline: 'Device is offline',
      unavailable: 'Offline download unavailable',
      available: 'Download for offline use',
      installing: 'Installing for offline use',
      installed: 'Installed for offline use',
      activating: 'Downloading additional assets for offline use',
      activated: 'Ready for offline use',
      error: 'Download failed',
    };

    return this.args.ariaLabel ?? defaultLabels[status];
  }

  get isClickable() {
    return (this.args.status === 'available' || this.args.status === 'activated') && !this.args.disabled;
  }

  get statusClass() {
    switch (this.args.status) {
      case 'offline':
        return scopedClass('download-button-status-offline');
      case 'unavailable':
        return scopedClass('download-button-status-unavailable');
      case 'available':
        return scopedClass('download-button-status-available');
      case 'installing':
        return scopedClass('download-button-status-installing');
      case 'installed':
        return scopedClass('download-button-status-installed');
      case 'activating':
        return scopedClass('download-button-status-activating');
      case 'activated':
        return scopedClass('download-button-status-activated');
      case 'error':
      default:
        return scopedClass('download-button-status-error');
    }
  }

  handleClick = (event: MouseEvent) => {
    if (this.isClickable && this.args.onClick) {
      event.preventDefault();
      this.args.onClick();
    }
  };

  <template>
    <button
      type="button"
      class="download-button {{this.statusClass}}"
      aria-label={{this.ariaLabel}}
      disabled={{not this.isClickable}}
      {{on "click" this.handleClick}}
      ...attributes
    >
      <span class="download-button-circle">
        <span class="download-button-icon">
          <FaIcon @icon={{this.icon}} />
        </span>
        {{#if (eq @status "installing")}}
          <span class="download-button-checkmark">
            <FaIcon @icon={{faHourglass}} />
          </span>
        {{else if (eq @status "installed")}}
          <span class="download-button-checkmark">
            <FaIcon @icon={{faCheck}} />
          </span>
        {{else if (eq @status "activating")}}
          <span class="download-button-checkmark">
            <FaIcon @icon={{faHourglass}} />
          </span>
        {{else if (eq @status "activated")}}
          <span class="download-button-checkmark">
            <FaIcon @icon={{faCheck}} />
          </span>
        {{else if (eq @status "error")}}
          <span class="download-button-checkmark">
            <FaIcon @icon={{faX}} />
          </span>
        {{else if (eq @status "unavailable")}}
          <span class="download-button-checkmark">
            <FaIcon @icon={{faBan}} />
          </span>
        {{else if (eq @status "offline")}}
          <span class="download-button-checkmark">
            <FaIcon @icon={{faWifi}} />
          </span>
        {{/if}}
      </span>
    </button>
  </template>
}
