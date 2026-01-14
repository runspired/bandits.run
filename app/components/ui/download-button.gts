import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import FaIcon from '#ui/fa-icon.gts';
import { faDownload, faCheck } from '@fortawesome/free-solid-svg-icons';
import type { IconDefinition } from '@fortawesome/fontawesome-svg-core';
import { eq, not } from '#app/utils/comparison.ts';
import './download-button.css';

export type DownloadStatus = 'available' | 'downloading' | 'complete' | 'error';

interface DownloadButtonSignature {
  Args: {
    /**
     * Current download/installation status
     * - 'available': Ready to download (grey glow)
     * - 'downloading': In progress with completion percentage (rotating glow)
     * - 'complete': Successfully downloaded (green glow with checkmark)
     * - 'error': Failed to download (red glow)
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
      available: 'Download for offline use',
      downloading: `Downloading: ${this.progress}% complete`,
      complete: 'Downloaded successfully',
      error: 'Download failed',
    };

    return this.args.ariaLabel ?? defaultLabels[status];
  }

  get isClickable() {
    return this.args.status === 'available' && !this.args.disabled;
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
      class="download-button download-button--{{@status}}"
      aria-label={{this.ariaLabel}}
      disabled={{not this.isClickable}}
      {{on "click" this.handleClick}}
      ...attributes
    >
      <span class="download-button__circle" data-progress={{this.progress}}>
        <span class="download-button__icon">
          <FaIcon @icon={{this.icon}} />
        </span>
        {{#if (eq @status "complete")}}
          <span class="download-button__checkmark">
            <FaIcon @icon={{faCheck}} />
          </span>
        {{/if}}
      </span>
    </button>
  </template>
}
