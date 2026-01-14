import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import FaIcon from '#ui/fa-icon.gts';
import { faDownload, faCheck, faX, faBan, faWifi } from '@fortawesome/free-solid-svg-icons';
import type { IconDefinition } from '@fortawesome/fontawesome-svg-core';
import { eq, not } from '#app/utils/comparison.ts';
import { scopedClass } from 'ember-scoped-css';
import './download-button.css';

export type DownloadStatus = 'offline' | 'unavailable' | 'available' | 'downloading' | 'downloaded' | 'error';

interface DownloadButtonSignature {
  Args: {
    /**
     * Current download/installation status
     * - 'offline': Device is offline
     * - 'unavailable': Service worker not supported (hidden)
     * - 'available': Ready to download (grey glow, clickable)
     * - 'downloading': In progress with completion percentage (rotating glow, not clickable)
     * - 'downloaded': Successfully downloaded (green glow with checkmark, clickable)
     * - 'error': Failed to download (red glow, not clickable)
     */
    status: DownloadStatus;

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

  get progress() {
    return this.args.progress ?? 0;
  }

  get ariaLabel() {
    const status = this.args.status;
    const defaultLabels = {
      offline: 'Device is offline',
      unavailable: 'Offline download unavailable',
      available: 'Download for offline use',
      downloading: `Downloading: ${this.progress}% complete`,
      downloaded: 'Downloaded successfully',
      error: 'Download failed',
    };

    return this.args.ariaLabel ?? defaultLabels[status];
  }

  get isClickable() {
    return (this.args.status === 'available' || this.args.status === 'downloaded') && !this.args.disabled;
  }

  get statusClass() {
    switch (this.args.status) {
      case 'offline':
        return scopedClass('download-button-status-offline');
      case 'unavailable':
        return scopedClass('download-button-status-unavailable');
      case 'available':
        return scopedClass('download-button-status-available');
      case 'downloading':
        return scopedClass('download-button-status-downloading');
      case 'downloaded':
        return scopedClass('download-button-status-downloaded');
      case 'error':
        return scopedClass('download-button-status-error');
    }
    return 'unknown';
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
      <span class="download-button-circle" data-progress={{this.progress}}>
        <span class="download-button-icon">
          <FaIcon @icon={{this.icon}} />
        </span>
        {{#if (eq @status "downloaded")}}
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
