import './cache-progress.css';
import Component from '@glimmer/component';
import { getCacheManager } from '#app/utils/cache-manager.ts';
import { htmlSafe } from '@ember/template';

interface CacheProgressSignature {
  Args: {
    /**
     * Whether to show detailed tier-by-tier progress
     * Default: false (shows only overall progress)
     */
    showDetails?: boolean;
    /**
     * Whether to hide the component when caching is complete
     * Default: false
     */
    hideWhenComplete?: boolean;
  };
}

/**
 * Cache Progress Component
 *
 * Displays the progress of service worker asset caching.
 * Shows simplified progress for default Workbox service worker.
 *
 * @example
 * Basic usage:
 * ```gts
 * <CacheProgress />
 * ```
 *
 * @example
 * With auto-hide:
 * ```gts
 * <CacheProgress @hideWhenComplete={{true}} />
 * ```
 */
export default class CacheProgress extends Component<CacheProgressSignature> {
  cacheManager = getCacheManager();

  get shouldShow(): boolean {
    if (this.args.hideWhenComplete && this.cacheManager.progress.isComplete) {
      return false;
    }
    // Show if the service worker is active or completed
    return this.cacheManager.progress.isActive || this.cacheManager.progress.isComplete;
  }

  get statusMessage(): string {
    const { state, isFirstInstall } = this.cacheManager.progress;

    switch (state) {
      case 'installing':
        return 'Installing app...';
      case 'updating':
        return 'Updating app...';
      case 'installed':
        return isFirstInstall ? 'App installed ✓' : 'App ready ✓';
      case 'updated':
        return 'App updated ✓';
      default:
        return 'Preparing...';
    }
  }

  get progressBarStyle() {
    return htmlSafe(`width: ${this.cacheManager.progress.percentage}%`);
  }

  <template>
    {{#if this.shouldShow}}
      <div class="cache-progress">
        {{#if this.cacheManager.progress.isComplete}}
          <div class="cache-progress-complete">
            <span class="cache-progress-label">
              {{this.statusMessage}}
            </span>
          </div>
        {{else}}
          <div class="cache-progress-header">
            <span class="cache-progress-label">
              {{this.statusMessage}}
            </span>
            <span class="cache-progress-percentage">
              {{this.cacheManager.progress.percentage}}%
            </span>
          </div>

          <div class="progress-bar">
            <div
              class="progress-bar-fill"
              style={{this.progressBarStyle}}
            ></div>
          </div>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
