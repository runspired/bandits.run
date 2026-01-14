import Service from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { preloadTilesForLocation, estimateTileCount, estimateDownloadSize } from '#app/utils/tile-preloader.ts';
import type { PreloadOptions, PolygonPoint } from '#app/utils/tile-preloader.ts';
import { getTheme } from '#app/core/site-theme.ts';
import type * as L from 'leaflet';

export type MapDownloadStatus = 'idle' | 'downloading' | 'completed' | 'error';

interface LocationCache {
  locationId: string;
  status: MapDownloadStatus;
  progress: number;
  totalTiles: number;
  estimatedSize: number;
  error?: string;
}

/**
 * Service for managing map tile caching for offline use
 *
 * This service coordinates with the service worker to preload map tiles
 * for specific locations, enabling offline map viewing.
 */
export default class MapTileCacheService extends Service {
  /**
   * Cache status for each location
   */
  @tracked
  private locationCaches: Map<string, LocationCache> = new Map();

  /**
   * Currently downloading location ID
   */
  @tracked
  currentlyDownloading: string | null = null;

  /**
   * Get cache status for a specific location
   */
  getCacheStatus(locationId: string): LocationCache | null {
    return this.locationCaches.get(locationId) ?? null;
  }

  /**
   * Check if a location is currently downloading
   */
  isDownloading(locationId: string): boolean {
    const cache = this.locationCaches.get(locationId);
    return cache?.status === 'downloading' || false;
  }

  /**
   * Check if a location has been cached
   */
  isCached(locationId: string): boolean {
    const cache = this.locationCaches.get(locationId);
    return cache?.status === 'completed' || false;
  }

  /**
   * Get current download progress for a location (0-100)
   */
  getProgress(locationId: string): number {
    const cache = this.locationCaches.get(locationId);
    return cache?.progress ?? 0;
  }

  /**
   * Estimate the number of tiles and download size for a location
   */
  estimateDownload(lat: number, lng: number, radiusMiles: number = 15): {
    tileCount: number;
    sizeMB: number;
  } {
    const options: PreloadOptions = {
      lat,
      lng,
      screenWidth: window.innerWidth,
      screenHeight: window.innerHeight,
      radiusMiles,
      tileUrl: this.getTileUrl(),
    };

    // Double the estimate since we download both light and dark tiles
    return {
      tileCount: estimateTileCount(options) * 2,
      sizeMB: estimateDownloadSize(options) * 2,
    };
  }

  /**
   * Estimate the number of tiles and download size for the visible area of a map
   */
  estimateDownloadForVisibleArea(map: L.Map): {
    tileCount: number;
    sizeMB: number;
  } {
    const bounds = map.getBounds();
    const center = bounds.getCenter();
    const currentZoom = map.getZoom();

    // Calculate radius from center to corner of visible area
    const ne = bounds.getNorthEast();
    const radiusMeters = center.distanceTo(ne);
    const radiusMiles = radiusMeters / 1609.34; // Convert meters to miles

    const options: PreloadOptions = {
      lat: center.lat,
      lng: center.lng,
      screenWidth: window.innerWidth,
      screenHeight: window.innerHeight,
      radiusMiles,
      minZoom: currentZoom,
      maxZoom: 18, // Download from current zoom to max zoom (18)
      tileUrl: this.getTileUrl(),
    };

    // Double the estimate since we download both light and dark tiles
    return {
      tileCount: estimateTileCount(options) * 2,
      sizeMB: estimateDownloadSize(options) * 2,
    };
  }

  /**
   * Estimate the number of tiles and download size for a polygon area
   */
  estimateDownloadForPolygon(
    polygon: PolygonPoint[],
    map: L.Map
  ): {
    tileCount: number;
    sizeMB: number;
  } {
    const bounds = map.getBounds();
    const center = bounds.getCenter();
    const currentZoom = map.getZoom();

    const options: PreloadOptions = {
      lat: center.lat,
      lng: center.lng,
      screenWidth: window.innerWidth,
      screenHeight: window.innerHeight,
      polygon,
      minZoom: currentZoom,
      maxZoom: 18,
      tileUrl: this.getTileUrl(),
    };

    // Double the estimate since we download both light and dark tiles
    return {
      tileCount: estimateTileCount(options) * 2,
      sizeMB: estimateDownloadSize(options) * 2,
    };
  }

  /**
   * Download and cache map tiles for a specific location
   *
   * @param locationId - Unique identifier for the location
   * @param lat - Latitude of the location
   * @param lng - Longitude of the location
   * @param radiusMiles - Radius to cache in miles (default: 15)
   * @param map - Optional Leaflet map for visible area mode
   * @param polygon - Optional polygon to constrain tile caching
   * @returns Promise that resolves when download is complete
   */
  async downloadTilesForLocation(
    locationId: string,
    lat: number,
    lng: number,
    radiusMiles: number = 15,
    map?: L.Map,
    polygon?: PolygonPoint[]
  ): Promise<void> {
    // Prevent concurrent downloads
    if (this.currentlyDownloading) {
      throw new Error('A download is already in progress');
    }

    // Check if service worker is available
    if (!('serviceWorker' in navigator)) {
      throw new Error('Service worker not supported. Cannot cache tiles offline.');
    }

    // Determine estimate based on mode
    let estimate: { tileCount: number; sizeMB: number };
    if (polygon && polygon.length >= 3 && map) {
      estimate = this.estimateDownloadForPolygon(polygon, map);
    } else if (map) {
      estimate = this.estimateDownloadForVisibleArea(map);
    } else {
      estimate = this.estimateDownload(lat, lng, radiusMiles);
    }

    // Initialize cache status
    const cacheStatus: LocationCache = {
      locationId,
      status: 'downloading',
      progress: 0,
      totalTiles: estimate.tileCount,
      estimatedSize: estimate.sizeMB,
    };

    this.locationCaches.set(locationId, cacheStatus);
    this.currentlyDownloading = locationId;

    // Build base options
    let baseOptions: Omit<PreloadOptions, 'tileUrl' | 'onProgress'>;

    if (polygon && polygon.length >= 3 && map) {
      // Polygon mode
      const bounds = map.getBounds();
      const center = bounds.getCenter();
      const currentZoom = map.getZoom();

      baseOptions = {
        lat: center.lat,
        lng: center.lng,
        screenWidth: window.innerWidth,
        screenHeight: window.innerHeight,
        polygon,
        minZoom: currentZoom,
        maxZoom: 18,
      };
    } else if (map) {
      // Visible area mode
      const bounds = map.getBounds();
      const center = bounds.getCenter();
      const currentZoom = map.getZoom();
      const ne = bounds.getNorthEast();
      const radiusMeters = center.distanceTo(ne);
      const calculatedRadiusMiles = radiusMeters / 1609.34;

      baseOptions = {
        lat: center.lat,
        lng: center.lng,
        screenWidth: window.innerWidth,
        screenHeight: window.innerHeight,
        radiusMiles: calculatedRadiusMiles,
        minZoom: currentZoom,
        maxZoom: 18,
      };
    } else {
      // Radius mode
      baseOptions = {
        lat,
        lng,
        screenWidth: window.innerWidth,
        screenHeight: window.innerHeight,
        radiusMiles,
      };
    }

    // Download both light and dark tiles
    const lightTileUrl = 'https://tiles.stadiamaps.com/tiles/outdoors/{z}/{x}/{y}{r}.png';
    const darkTileUrl = 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png';

    try {
      // Track progress for both tile sets
      let totalProgress = 0;

      // Download light mode tiles (first half of progress)
      await preloadTilesForLocation({
        ...baseOptions,
        tileUrl: lightTileUrl,
        onProgress: (current, total) => {
          const cache = this.locationCaches.get(locationId);
          if (cache) {
            // Light tiles account for first 50% of progress
            totalProgress = Math.round((current / total) * 50);
            cache.progress = totalProgress;
            // Trigger reactivity by reassigning
            this.locationCaches = new Map(this.locationCaches);
          }
        },
      });

      // Download dark mode tiles (second half of progress)
      await preloadTilesForLocation({
        ...baseOptions,
        tileUrl: darkTileUrl,
        onProgress: (current, total) => {
          const cache = this.locationCaches.get(locationId);
          if (cache) {
            // Dark tiles account for second 50% of progress
            totalProgress = 50 + Math.round((current / total) * 50);
            cache.progress = totalProgress;
            // Trigger reactivity by reassigning
            this.locationCaches = new Map(this.locationCaches);
          }
        },
      });

      // Update status to completed
      const cache = this.locationCaches.get(locationId);
      if (cache) {
        cache.status = 'completed';
        cache.progress = 100;
        this.locationCaches = new Map(this.locationCaches);
      }
    } catch (error) {
      const cache = this.locationCaches.get(locationId);
      if (cache) {
        cache.status = 'error';
        cache.error = error instanceof Error ? error.message : String(error);
        this.locationCaches = new Map(this.locationCaches);
      }
      throw error;
    } finally {
      this.currentlyDownloading = null;
    }
  }

  /**
   * Clear cache status for a specific location
   * Note: This only clears the tracking status, not the actual cached tiles
   */
  clearCacheStatus(locationId: string): void {
    this.locationCaches.delete(locationId);
    this.locationCaches = new Map(this.locationCaches);
  }

  /**
   * Clear all cache statuses
   * Note: This only clears the tracking status, not the actual cached tiles
   */
  clearAllCacheStatuses(): void {
    this.locationCaches.clear();
    this.locationCaches = new Map(this.locationCaches);
  }

  /**
   * Get the current tile URL based on theme
   */
  private getTileUrl(): string {
    const theme = getTheme();
    return theme.isDarkMode
      ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png'
      : 'https://tiles.stadiamaps.com/tiles/outdoors/{z}/{x}/{y}{r}.png';
  }
}

// DO NOT DELETE: this is how TypeScript knows how to look up your services.
declare module '@ember/service' {
  interface Registry {
    'map-tile-cache': MapTileCacheService;
  }
}
