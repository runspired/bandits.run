import Component from '@glimmer/component';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import type MapTileCacheService from '#app/services/map-tile-cache.ts';
import DownloadButton from '#ui/download-button.gts';
import FaIcon from '#ui/fa-icon.gts';
import { faMap, faDownload } from '@fortawesome/free-solid-svg-icons';
import type { DownloadStatusType } from '#app/core/preferences.ts';
import { getDevicePreferences } from '#app/core/preferences.ts';
import type * as L from 'leaflet';
import './map-download-button.css';

interface MapDownloadButtonSignature {
  Element: HTMLElement;
  Args: {
    /**
     * Unique identifier for this location
     */
    locationId: string;

    /**
     * Location name for user messaging
     */
    locationName: string;

    /**
     * Latitude of the location
     */
    lat: number;

    /**
     * Longitude of the location
     */
    lng: number;

    /**
     * Radius to cache in miles (default: 15)
     * Only used when map is not provided
     */
    radiusMiles?: number;

    /**
     * Optional Leaflet map instance for calculating visible area
     * If provided, will download tiles for the visible area instead of radius
     */
    getMap?: () => L.Map | null;
  };
}

/**
 * Download button for caching map tiles for a specific location
 *
 * This component provides a download button that allows users to preload
 * map tiles for offline use. It integrates with the MapTileCacheService
 * to manage the download process and with DevicePreferences to ensure
 * the service worker is installed.
 *
 * @example
 * ```gts
 * <MapDownloadButton
 *   @locationId={{@run.location.id}}
 *   @locationName={{@run.location.name}}
 *   @lat={{@run.location.latitude}}
 *   @lng={{@run.location.longitude}}
 *   @radiusMiles={{15}}
 * />
 * ```
 */
export default class MapDownloadButton extends Component<MapDownloadButtonSignature> {
  @service declare mapTileCache: MapTileCacheService;

  @tracked
  showEstimate: boolean = false;

  @tracked
  errorMessage: string | null = null;

  preferences = getDevicePreferences();

  get radiusMiles() {
    return this.args.radiusMiles ?? 15;
  }

  get downloadEstimate() {
    try {
      const map = this.args.getMap?.();
      if (map) {
        // Calculate for visible area
        return this.mapTileCache.estimateDownloadForVisibleArea(map);
      } else {
        // Calculate for radius
        return this.mapTileCache.estimateDownload(
          this.args.lat,
          this.args.lng,
          this.radiusMiles
        );
      }
    } catch {
      return null;
    }
  }

  get isVisibleAreaMode() {
    return !!this.args.getMap;
  }

  get cacheStatus() {
    return this.mapTileCache.getCacheStatus(this.args.locationId);
  }

  get isDownloading() {
    return this.mapTileCache.isDownloading(this.args.locationId);
  }

  get isCached() {
    return this.mapTileCache.isCached(this.args.locationId);
  }

  get progress() {
    return this.mapTileCache.getProgress(this.args.locationId);
  }

  get isOfflineSupportInstalled(): boolean {
    const swStatus = this.preferences.downloadStatus;
    return swStatus === 'activated' || swStatus === 'installed';
  }

  get downloadStatus(): DownloadStatusType {
    // First check if service worker is available/installed
    const swStatus = this.preferences.downloadStatus;

    // If SW is not ready, return its status
    if (swStatus !== 'activated' && swStatus !== 'available') {
      return swStatus;
    }

    // If SW is ready, show map-specific status
    if (this.isDownloading) {
      return 'installing';
    }

    if (this.isCached) {
      return 'activated';
    }

    if (this.cacheStatus?.status === 'error') {
      return 'error';
    }

    return 'available';
  }

  get ariaLabel(): string {
    if (this.downloadStatus === 'activated' && this.isCached) {
      return `Map tiles for ${this.args.locationName} are cached for offline use`;
    }

    if (this.isDownloading) {
      return `Downloading map tiles for ${this.args.locationName}: ${this.progress}%`;
    }

    const areaText = this.isVisibleAreaMode ? 'visible area' : `${this.radiusMiles} mile radius`;
    return `Download map tiles for ${areaText} (${this.downloadEstimate?.sizeMB.toFixed(1)} MB)`;
  }

  handleClick = async () => {
    // If service worker is not installed, install it first
    if (this.preferences.downloadStatus === 'available') {
      try {
        await this.preferences.installPWA();
        // Wait a moment for SW to be ready
        await new Promise(resolve => setTimeout(resolve, 1000));
      } catch (error) {
        console.error('Failed to install service worker:', error);
        this.errorMessage = 'Failed to enable offline mode. Please try again.';
        return;
      }
    }

    // If already cached, show info
    if (this.isCached) {
      const estimate = this.downloadEstimate;
      const areaText = this.isVisibleAreaMode
        ? 'the visible area on screen'
        : `${this.radiusMiles} miles in all directions`;

      alert(
        `Map tiles for ${this.args.locationName} are already cached!\n\n` +
        `${estimate?.tileCount ?? 'Unknown'} tiles (${estimate?.sizeMB.toFixed(1) ?? 'Unknown'} MB) covering ${areaText}.`
      );
      return;
    }

    // Start download
    try {
      this.errorMessage = null;
      const map = this.args.getMap?.();
      const estimate = this.downloadEstimate;
      const areaText = this.isVisibleAreaMode
        ? 'the visible area on screen'
        : `${this.radiusMiles} miles in all directions`;
      const zoomText = this.isVisibleAreaMode && map
        ? ` at all zoom levels from ${map.getZoom()} to 18`
        : '';

      const confirmed = window.confirm(
        `Download map tiles for the visible area?\n\n` +
        `This will download approximately ${estimate?.sizeMB.toFixed(1) ?? 'Unknown'} MB ` +
        `(${estimate?.tileCount ?? 'Unknown'} tiles) covering ${areaText}${zoomText}.\n\n` +
        `The tiles will be cached for offline use.`
      );

      if (!confirmed) {
        return;
      }

      await this.mapTileCache.downloadTilesForLocation(
        this.args.locationId,
        this.args.lat,
        this.args.lng,
        this.radiusMiles,
        map ?? undefined
      );

      // Show success message

      alert(`Successfully cached map tiles for ${this.args.locationName}!`);
    } catch (error) {
      console.error('Failed to download map tiles:', error);
      this.errorMessage =
        error instanceof Error ? error.message : 'Failed to download map tiles. Please try again.';

      alert(this.errorMessage);
    }
  };

  <template>
    {{#if this.isOfflineSupportInstalled}}
      <div class="map-download-button-wrapper" ...attributes>
        <div class="map-download-background"></div>
        <DownloadButton
          @status={{this.downloadStatus}}
          @onClick={{this.handleClick}}
          @icon={{faMap}}
          @ariaLabel={{this.ariaLabel}}
        />
        {{#unless this.isCached}}
          <span class="map-download-secondary-icon">
            <FaIcon @icon={{faDownload}} />
          </span>
        {{/unless}}
      </div>
    {{/if}}
  </template>
}
