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

export interface PolygonPoint {
  lat: number;
  lng: number;
}

export interface TileSource {
  /** URL template for tiles */
  url: string;
  /** Minimum zoom for this source */
  minZoom?: number;
  /** Maximum zoom for this source */
  maxZoom?: number;
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
  /** Custom polygon boundary (takes precedence over radiusMiles) */
  polygon?: PolygonPoint[];
  /** Minimum zoom level (default: 1) */
  minZoom?: number;
  /** Maximum zoom level (default: 18) */
  maxZoom?: number;
  /** Tile size in pixels (default: 256) */
  tileSize?: number;
  /** Tile URL template (e.g., 'https://tiles.stadiamaps.com/tiles/outdoors/{z}/{x}/{y}{r}.png') - for raster tiles */
  tileUrl?: string;
  /** MapLibre style URL (e.g., '/map-styles/openstreetmap-us-vector.json') - for vector tiles */
  styleUrl?: string;
  /** Callback for progress updates (current, total) */
  onProgress?: (current: number, total: number) => void;
  /** Callback for individual tile load success */
  onTileLoaded?: (tile: TileCoordinate) => void;
  /** Callback for individual tile load error */
  onTileError?: (tile: TileCoordinate, error: Error) => void;
}

/**
 * Extract tile sources from a MapLibre style JSON
 */
export async function extractTileSourcesFromStyle(styleUrl: string): Promise<TileSource[]> {
  try {
    const response = await fetch(styleUrl);
    if (!response.ok) {
      throw new Error(`Failed to fetch style: ${response.status}`);
    }
    const style = await response.json();

    const sources: TileSource[] = [];

    if (style.sources) {
      for (const [_sourceName, source] of Object.entries(style.sources as Record<string, any>)) {
        if (source.tiles && Array.isArray(source.tiles) && source.tiles.length > 0) {
          sources.push({
            url: source.tiles[0],
            minZoom: source.minzoom,
            maxZoom: source.maxzoom,
          });
        }
      }
    }

    return sources;
  } catch (error) {
    console.error('Failed to extract tile sources from style:', error);
    return [];
  }
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
 * Get the bounding box of a polygon
 */
export function getPolygonBounds(polygon: PolygonPoint[]): {
  north: number;
  south: number;
  east: number;
  west: number;
} {
  if (polygon.length === 0) {
    return { north: 0, south: 0, east: 0, west: 0 };
  }

  let north = polygon[0]!.lat;
  let south = polygon[0]!.lat;
  let east = polygon[0]!.lng;
  let west = polygon[0]!.lng;

  for (const point of polygon) {
    north = Math.max(north, point.lat);
    south = Math.min(south, point.lat);
    east = Math.max(east, point.lng);
    west = Math.min(west, point.lng);
  }

  return { north, south, east, west };
}

/**
 * Check if a point is inside a polygon using ray casting algorithm
 */
export function isPointInPolygon(lat: number, lng: number, polygon: PolygonPoint[]): boolean {
  if (polygon.length < 3) return false;

  let inside = false;
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const pi = polygon[i]!;
    const pj = polygon[j]!;

    const intersect =
      pi.lat > lat !== pj.lat > lat &&
      lng < ((pj.lng - pi.lng) * (lat - pi.lat)) / (pj.lat - pi.lat) + pi.lng;

    if (intersect) inside = !inside;
  }

  return inside;
}

/**
 * Calculate tile bounds for a polygon at a specific zoom level
 */
export function getTileBoundsForPolygon(
  polygon: PolygonPoint[],
  zoom: number
): { minX: number; maxX: number; minY: number; maxY: number } {
  const bounds = getPolygonBounds(polygon);
  const nw = latLngToTile(bounds.north, bounds.west, zoom);
  const se = latLngToTile(bounds.south, bounds.east, zoom);

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
    polygon,
    minZoom = 1,
    maxZoom = 18,
  } = options;

  const tiles: TileCoordinate[] = [];

  // Calculate tiles for each zoom level
  for (let z = minZoom; z <= maxZoom; z++) {
    let bounds: { minX: number; maxX: number; minY: number; maxY: number };

    if (polygon && polygon.length >= 3) {
      // Use polygon bounds
      bounds = getTileBoundsForPolygon(polygon, z);
    } else {
      // Use radius bounds
      bounds = getTileBounds(lat, lng, radiusMiles, z);
    }

    // Add all tiles within the bounds
    for (let x = bounds.minX; x <= bounds.maxX; x++) {
      for (let y = bounds.minY; y <= bounds.maxY; y++) {
        // If using polygon, check if tile center is inside polygon
        if (polygon && polygon.length >= 3) {
          const tileCenter = tileToLatLng(x + 0.5, y + 0.5, z);
          if (isPointInPolygon(tileCenter.lat, tileCenter.lng, polygon)) {
            tiles.push({ x, y, z });
          }
        } else {
          tiles.push({ x, y, z });
        }
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
  // If styleUrl is provided, extract tile sources and preload for each source
  if (options.styleUrl) {
    const sources = await extractTileSourcesFromStyle(options.styleUrl);

    if (sources.length === 0) {
      throw new Error('No tile sources found in style');
    }

    // Preload tiles for each source
    for (const source of sources) {
      const sourceOptions: PreloadOptions & { tileUrl: string } = {
        ...options,
        tileUrl: source.url,
        styleUrl: undefined,
        minZoom: Math.max(options.minZoom ?? 1, source.minZoom ?? 1),
        maxZoom: Math.min(options.maxZoom ?? 18, source.maxZoom ?? 18),
      };
      await preloadTilesForSingleSource(sourceOptions);
    }
    return;
  }

  // Otherwise use the tileUrl directly
  if (!options.tileUrl) {
    throw new Error('Either tileUrl or styleUrl must be provided');
  }

  await preloadTilesForSingleSource(options as PreloadOptions & { tileUrl: string });
}

/**
 * Preload tiles for a single tile source
 */
async function preloadTilesForSingleSource(options: PreloadOptions & { tileUrl: string }): Promise<void> {
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
