#!/usr/bin/env node

/**
 * Script to fetch route details and GPX data from Strava
 *
 * Usage:
 *   node scripts/fetch-strava-route.ts <routeId>
 *
 * Environment variables required:
 *   STRAVA_ACCESS_TOKEN - A Strava API access token with read permissions
 *
 * Example:
 *   node scripts/fetch-strava-route.ts 3147857
 */

interface StravaRoute {
  id: number;
  resource_state: number;
  athlete: {
    id: number;
    resource_state: number;
  };
  name: string;
  description: string | null;
  distance: number; // meters
  elevation_gain: number; // meters
  elevation_loss?: number; // meters (may not always be present)
  map: {
    id: string;
    summary_polyline: string;
    resource_state: number;
  };
  type: number; // 1 = ride, 2 = run
  sub_type: number; // 1 = road, 2 = mtb, 3 = cross, 4 = trail, 5 = mixed
  created_at: string;
  updated_at: string;
  estimated_moving_time: number; // seconds
  segments: any[];
  private: boolean;
  starred: boolean;
  timestamp: number;
  waypoints?: any[];
}

interface RouteStats {
  routeId: number;
  name: string;
  description: string | null;
  distance: {
    meters: number;
    miles: number;
    kilometers: number;
  };
  elevation: {
    gain: {
      meters: number;
      feet: number;
    };
    loss: {
      meters: number;
      feet: number;
    };
  };
  surfaceType: 'road' | 'mountain bike' | 'cross country' | 'trail' | 'mixed' | 'unknown';
  activityType: 'ride' | 'run' | 'unknown';
  estimatedMovingTime: {
    seconds: number;
    formatted: string;
  };
  isPrivate: boolean;
  createdAt: string;
  updatedAt: string;
  stravaUrl: string;
}

interface StravaErrorResponse {
  message: string;
  errors: Array<{
    resource: string;
    field: string;
    code: string;
  }>;
}

class StravaRouteFetcher {
  private accessToken: string;
  private baseUrl = 'https://www.strava.com/api/v3';

  constructor(accessToken: string) {
    this.accessToken = accessToken;
  }

  /**
   * Fetch route details from Strava
   */
  async fetchRoute(routeId: string): Promise<StravaRoute> {
    const response = await fetch(`${this.baseUrl}/routes/${routeId}`, {
      headers: {
        Authorization: `Bearer ${this.accessToken}`,
      },
    });

    if (!response.ok) {
      if (response.status === 404) {
        throw new Error(`Route ${routeId} not found. Make sure the route ID is correct and you have access to it.`);
      }
      const error = await response.json() as StravaErrorResponse;
      throw new Error(`Failed to fetch route: ${response.status} - ${error.message || 'Unknown error'}`);
    }

    return response.json();
  }

  /**
   * Fetch GPX data for a route
   * Note: The GPX export endpoint may require specific permissions
   */
  async fetchRouteGPX(routeId: string): Promise<string> {
    const response = await fetch(`${this.baseUrl}/routes/${routeId}/export_gpx`, {
      headers: {
        Authorization: `Bearer ${this.accessToken}`,
      },
    });

    if (!response.ok) {
      if (response.status === 404) {
        throw new Error(`GPX export not available for route ${routeId}`);
      }
      const error = await response.text();
      throw new Error(`Failed to fetch GPX: ${response.status} - ${error}`);
    }

    return response.text();
  }

  /**
   * Convert route data to a more readable format
   */
  formatRouteStats(route: StravaRoute): RouteStats {
    const metersToMiles = (meters: number) => meters * 0.000621371;
    const metersToKilometers = (meters: number) => meters / 1000;
    const metersToFeet = (meters: number) => meters * 3.28084;

    const formatTime = (seconds: number): string => {
      const hours = Math.floor(seconds / 3600);
      const minutes = Math.floor((seconds % 3600) / 60);
      const secs = seconds % 60;

      if (hours > 0) {
        return `${hours}h ${minutes}m ${secs}s`;
      } else if (minutes > 0) {
        return `${minutes}m ${secs}s`;
      } else {
        return `${secs}s`;
      }
    };

    const getSurfaceType = (subType: number): RouteStats['surfaceType'] => {
      switch (subType) {
        case 1: return 'road';
        case 2: return 'mountain bike';
        case 3: return 'cross country';
        case 4: return 'trail';
        case 5: return 'mixed';
        default: return 'unknown';
      }
    };

    const getActivityType = (type: number): RouteStats['activityType'] => {
      switch (type) {
        case 1: return 'ride';
        case 2: return 'run';
        default: return 'unknown';
      }
    };

    return {
      routeId: route.id,
      name: route.name,
      description: route.description,
      distance: {
        meters: route.distance,
        miles: metersToMiles(route.distance),
        kilometers: metersToKilometers(route.distance),
      },
      elevation: {
        gain: {
          meters: route.elevation_gain,
          feet: metersToFeet(route.elevation_gain),
        },
        loss: {
          meters: route.elevation_loss || 0,
          feet: metersToFeet(route.elevation_loss || 0),
        },
      },
      surfaceType: getSurfaceType(route.sub_type),
      activityType: getActivityType(route.type),
      estimatedMovingTime: {
        seconds: route.estimated_moving_time,
        formatted: formatTime(route.estimated_moving_time),
      },
      isPrivate: route.private,
      createdAt: route.created_at,
      updatedAt: route.updated_at,
      stravaUrl: `https://www.strava.com/routes/${route.id}`,
    };
  }

  /**
   * Pretty print route stats to console
   */
  printRouteStats(stats: RouteStats): void {
    console.log('\n' + '═'.repeat(80));
    console.log(`📍 ${stats.name}`);
    console.log('═'.repeat(80));

    if (stats.description) {
      console.log(`\n${stats.description}\n`);
    }

    console.log('📏 Distance:');
    console.log(`   ${stats.distance.miles.toFixed(2)} miles`);
    console.log(`   ${stats.distance.kilometers.toFixed(2)} km`);
    console.log(`   ${stats.distance.meters.toFixed(0)} meters`);

    console.log('\n⛰️  Elevation:');
    console.log(`   Gain:  ${stats.elevation.gain.feet.toFixed(0)} ft (${stats.elevation.gain.meters.toFixed(0)} m)`);
    if (stats.elevation.loss.meters > 0) {
      console.log(`   Loss:  ${stats.elevation.loss.feet.toFixed(0)} ft (${stats.elevation.loss.meters.toFixed(0)} m)`);
    }

    console.log(`\n🏃 Activity Type: ${stats.activityType}`);
    console.log(`🛤️  Surface Type: ${stats.surfaceType}`);
    console.log(`⏱️  Estimated Time: ${stats.estimatedMovingTime.formatted}`);
    console.log(`🔒 Private: ${stats.isPrivate ? 'Yes' : 'No'}`);

    console.log(`\n🔗 Strava URL: ${stats.stravaUrl}`);
    console.log(`📅 Created: ${new Date(stats.createdAt).toLocaleString()}`);
    console.log(`📅 Updated: ${new Date(stats.updatedAt).toLocaleString()}`);

    console.log('\n' + '═'.repeat(80) + '\n');
  }

  /**
   * Save GPX file to disk
   */
  async saveGPX(routeId: string, gpxData: string, outputDir = './downloads'): Promise<string> {
    const fs = await import('fs/promises');
    const path = await import('path');

    // Ensure output directory exists
    try {
      await fs.mkdir(outputDir, { recursive: true });
    } catch (error) {
      // Directory might already exist
    }

    const filename = `strava-route-${routeId}.gpx`;
    const filepath = path.join(outputDir, filename);

    await fs.writeFile(filepath, gpxData, 'utf-8');

    return filepath;
  }

  /**
   * Save route stats to JSON file
   */
  async saveStats(stats: RouteStats, outputDir = './downloads'): Promise<string> {
    const fs = await import('fs/promises');
    const path = await import('path');

    // Ensure output directory exists
    try {
      await fs.mkdir(outputDir, { recursive: true });
    } catch (error) {
      // Directory might already exist
    }

    const filename = `strava-route-${stats.routeId}-stats.json`;
    const filepath = path.join(outputDir, filename);

    await fs.writeFile(filepath, JSON.stringify(stats, null, 2), 'utf-8');

    return filepath;
  }
}

// Main execution
async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.error('Usage: node scripts/fetch-strava-route.ts <routeId> [options]');
    console.error('');
    console.error('Example: node scripts/fetch-strava-route.ts 3147857');
    console.error('');
    console.error('Options:');
    console.error('  --save-gpx     Save GPX file to downloads directory');
    console.error('  --save-stats   Save stats JSON to downloads directory');
    console.error('  --output-dir   Custom output directory (default: ./downloads)');
    console.error('');
    console.error('Environment variables required:');
    console.error('  STRAVA_ACCESS_TOKEN - Your Strava API access token');
    process.exit(1);
  }

  const routeId = args[0];
  const saveGpx = args.includes('--save-gpx');
  const saveStats = args.includes('--save-stats');
  const outputDirIndex = args.indexOf('--output-dir');
  const outputDir = outputDirIndex >= 0 && args[outputDirIndex + 1]
    ? args[outputDirIndex + 1]
    : './downloads';

  const accessToken = process.env.STRAVA_ACCESS_TOKEN;

  if (!accessToken) {
    console.error('Error: STRAVA_ACCESS_TOKEN environment variable is required');
    console.error('');
    console.error('To get an access token:');
    console.error('1. Run: node scripts/strava-auth.ts get-auth-url');
    console.error('2. Follow the authentication flow');
    console.error('3. Set the token: export STRAVA_ACCESS_TOKEN="your_token_here"');
    process.exit(1);
  }

  console.log(`Fetching route ${routeId}...`);

  const fetcher = new StravaRouteFetcher(accessToken);

  try {
    // Fetch route details
    const route = await fetcher.fetchRoute(routeId);
    const stats = fetcher.formatRouteStats(route);

    // Print stats
    fetcher.printRouteStats(stats);

    // Save stats if requested
    if (saveStats) {
      const statsPath = await fetcher.saveStats(stats, outputDir);
      console.log(`✅ Stats saved to ${statsPath}`);
    }

    // Fetch and save GPX if requested
    if (saveGpx) {
      console.log('\nFetching GPX data...');
      try {
        const gpxData = await fetcher.fetchRouteGPX(routeId);
        const gpxPath = await fetcher.saveGPX(routeId, gpxData, outputDir);
        console.log(`✅ GPX file saved to ${gpxPath}`);
      } catch (error) {
        console.error('⚠️  Could not fetch GPX data:', error instanceof Error ? error.message : error);
        console.error('   Note: GPX export may require the route to be created by the authenticated user');
      }
    }

    // Print usage suggestions
    if (!saveGpx && !saveStats) {
      console.log('💡 Tip: Use --save-gpx to download the GPX file');
      console.log('💡 Tip: Use --save-stats to save stats as JSON');
    }

  } catch (error) {
    console.error('❌ Error fetching route:', error);
    process.exit(1);
  }
}

main();
