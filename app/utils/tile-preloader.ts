/**
 * Tile Preloading Utility
 *
 * Calculates and preloads map tiles for a given location to ensure they're
 * cached by the service worker for offline access.
 */

export interface TileCoordinate {
  x: number;
  y: number;
  z: number;
}

export interface PreloadOptions {
  /** Center latitude of the location */
  lat: number;
  /** Center longitude of the location */
  lng: number;
  /** Screen width in pixels */
  screenWidth: number;
  /** Screen height in pixels */
  screenHeight: number;
  /** Radius to preload in miles (default: 15) */
  radiusMiles?: number;
  /** Minimum zoom level (default: 1) */
  minZoom?: number;
  /** Maximum zoom level (default: 18) */
  maxZoom?: number;
  /** Tile size in pixels (default: 256) */
  tileSize?: number;
  /** Tile URL template (e.g., 'https://tiles.stadiamaps.com/tiles/outdoors/{z}/{x}/{y}{r}.png') */
  tileUrl: string;
  /** Callback for progress updates (current, total) */
  onProgress?: (current: number, total: number) => void;
  /** Callback for individual tile load success */
  onTileLoaded?: (tile: TileCoordinate) => void;
  /** Callback for individual tile load error */
  onTileError?: (tile: TileCoordinate, error: Error) => void;
}

/**
 * Convert latitude/longitude to tile coordinates at a given zoom level
 */
export function latLngToTile(lat: number, lng: number, zoom: number): TileCoordinate {
  const latRad = (lat * Math.PI) / 180;
  const n = Math.pow(2, zoom);

  const x = Math.floor(((lng + 180) / 360) * n);
  const y = Math.floor(
    ((1 - Math.log(Math.tan(latRad) + 1 / Math.cos(latRad)) / Math.PI) / 2) * n
  );

  return { x, y, z: zoom };
}

/**
 * Convert tile coordinates to latitude/longitude (northwest corner)
 */
export function tileToLatLng(x: number, y: number, zoom: number): { lat: number; lng: number } {
  const n = Math.pow(2, zoom);
  const lng = (x / n) * 360 - 180;
  const latRad = Math.atan(Math.sinh(Math.PI * (1 - (2 * y) / n)));
  const lat = (latRad * 180) / Math.PI;

  return { lat, lng };
}

/**
 * Calculate the bounding box of tiles needed to cover a radius around a point
 */
export function getTileBounds(
  centerLat: number,
  centerLng: number,
  radiusMiles: number,
  zoom: number
): { minX: number; maxX: number; minY: number; maxY: number } {
  // Calculate approximate degree offset for the radius
  // At the equator, 1 degree of latitude ≈ 69 miles
  // Longitude varies by latitude: 1 degree ≈ 69 * cos(lat) miles
  const latOffset = radiusMiles / 69;
  const lngOffset = radiusMiles / (69 * Math.cos((centerLat * Math.PI) / 180));

  // Calculate bounding box corners
  const north = centerLat + latOffset;
  const south = centerLat - latOffset;
  const east = centerLng + lngOffset;
  const west = centerLng - lngOffset;

  // Convert corners to tile coordinates
  const nw = latLngToTile(north, west, zoom);
  const se = latLngToTile(south, east, zoom);

  return {
    minX: Math.min(nw.x, se.x),
    maxX: Math.max(nw.x, se.x),
    minY: Math.min(nw.y, se.y),
    maxY: Math.max(nw.y, se.y),
  };
}

/**
 * Get all tile coordinates needed for the given options
 */
export function calculateRequiredTiles(options: PreloadOptions): TileCoordinate[] {
  const {
    lat,
    lng,
    radiusMiles = 15,
    minZoom = 1,
    maxZoom = 18,
  } = options;

  const tiles: TileCoordinate[] = [];

  // Calculate tiles for each zoom level
  for (let z = minZoom; z <= maxZoom; z++) {
    const bounds = getTileBounds(lat, lng, radiusMiles, z);

    // Add all tiles within the bounds
    for (let x = bounds.minX; x <= bounds.maxX; x++) {
      for (let y = bounds.minY; y <= bounds.maxY; y++) {
        tiles.push({ x, y, z });
      }
    }
  }

  return tiles;
}

/**
 * Format a tile URL by replacing placeholders
 */
export function formatTileUrl(template: string, tile: TileCoordinate): string {
  // Handle subdomain rotation for load balancing
  const subdomains = ['a', 'b', 'c'];
  const subdomain = subdomains[(tile.x + tile.y) % subdomains.length] ?? 'a';

  return template
    .replaceAll('{z}', tile.z.toString())
    .replaceAll('{x}', tile.x.toString())
    .replaceAll('{y}', tile.y.toString())
    .replaceAll('{s}', subdomain)
    .replaceAll('{r}', ''); // Remove retina indicator for standard tiles
}

/**
 * Preload a single tile by fetching it
 */
async function preloadTile(url: string, _tile: TileCoordinate): Promise<void> {
  const response = await fetch(url, {
    mode: 'cors',
    cache: 'default', // Use browser cache, triggering service worker
  });

  if (!response.ok) {
    throw new Error(`Failed to load tile: ${response.status} ${response.statusText}`);
  }

  // Read the response to ensure it's fully cached
  await response.blob();
}

/**
 * Preload all necessary tiles for a route location
 *
 * This function calculates all tiles needed to cover a radius around a point
 * at all zoom levels, then fetches them to trigger service worker caching.
 *
 * @param options - Configuration for tile preloading
 * @returns Promise that resolves when all tiles are loaded
 *
 * @example
 * ```typescript
 * await preloadTilesForLocation({
 *   lat: 40.7128,
 *   lng: -74.0060,
 *   screenWidth: window.innerWidth,
 *   screenHeight: window.innerHeight,
 *   tileUrl: 'https://tiles.stadiamaps.com/tiles/outdoors/{z}/{x}/{y}{r}.png',
 *   radiusMiles: 15,
 *   onProgress: (current, total) => {
 *     console.log(`Loading tiles: ${current}/${total}`);
 *   }
 * });
 * ```
 */
export async function preloadTilesForLocation(options: PreloadOptions): Promise<void> {
  const tiles = calculateRequiredTiles(options);
  const total = tiles.length;
  let current = 0;

  console.log(`Preloading ${total} tiles for location (${options.lat}, ${options.lng})`);

  // Batch tile loading to avoid overwhelming the browser
  const BATCH_SIZE = 10;
  const batches: TileCoordinate[][] = [];

  for (let i = 0; i < tiles.length; i += BATCH_SIZE) {
    batches.push(tiles.slice(i, i + BATCH_SIZE));
  }

  // Process batches sequentially, tiles within a batch in parallel
  for (const batch of batches) {
    await Promise.all(
      batch.map(async (tile) => {
        try {
          const url = formatTileUrl(options.tileUrl, tile);
          await preloadTile(url, tile);
          current++;

          options.onTileLoaded?.(tile);
          options.onProgress?.(current, total);
        } catch (error) {
          const err = error instanceof Error ? error : new Error(String(error));
          console.warn(`Failed to preload tile (${tile.z}/${tile.x}/${tile.y}):`, err);
          options.onTileError?.(tile, err);

          // Still increment counter for progress tracking
          current++;
          options.onProgress?.(current, total);
        }
      })
    );
  }

  console.log(`Finished preloading ${total} tiles`);
}

/**
 * Calculate the total number of tiles that would be preloaded
 *
 * Useful for showing estimated download size or time before starting
 *
 * @param options - Configuration for tile preloading
 * @returns Total number of tiles
 */
export function estimateTileCount(options: PreloadOptions): number {
  return calculateRequiredTiles(options).length;
}

/**
 * Estimate download size in megabytes
 *
 * Assumes average tile size of 25KB (typical for PNG map tiles)
 *
 * @param options - Configuration for tile preloading
 * @returns Estimated size in MB
 */
export function estimateDownloadSize(options: PreloadOptions): number {
  const tileCount = estimateTileCount(options);
  const AVERAGE_TILE_SIZE_KB = 25;
  return (tileCount * AVERAGE_TILE_SIZE_KB) / 1024;
}
