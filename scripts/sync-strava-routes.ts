#!/usr/bin/env node

/**
 * Script to sync Strava routes from event links to seed files
 *
 * This script:
 * 1. Scans all seed files for runs with stravaEventLink URLs
 * 2. Fetches each Strava event to get its route_id
 * 3. Updates the seed file with the stravaRouteLink if found
 *
 * Usage:
 *   pnpm tsx scripts/sync-strava-routes.ts [--dry-run]
 *
 * Environment variables required:
 *   STRAVA_ACCESS_TOKEN - A Strava API access token with read permissions
 *
 * Options:
 *   --dry-run    Show what would be updated without making changes
 */

import { readdir, readFile, writeFile, stat } from 'fs/promises';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

interface StravaClubEvent {
  id: number;
  resource_state: number;
  title: string;
  description: string;
  club_id: number;
  organization_name: string;
  activity_type: string;
  created_at: string;
  route_id: number | null;
  woman_only: boolean;
  private: boolean;
  skill_levels: number;
  terrain: number;
  upcoming_occurrences: string[];
  address: string;
}

interface StravaErrorResponse {
  message: string;
  errors: Array<{
    resource: string;
    field: string;
    code: string;
  }>;
}

interface RunOption {
  name: string | null;
  stravaEventLink: string | null;
  stravaRouteLink: string | null;
  [key: string]: unknown;
}

interface TrailRunSeed {
  title: string;
  stravaEventLink: string | null;
  runs: RunOption[];
  [key: string]: unknown;
}

interface UpdateResult {
  file: string;
  runTitle: string;
  optionName: string | null;
  eventId: string;
  routeId: number;
  routeLink: string;
  updated: boolean;
}

class StravaRouteSyncer {
  private accessToken: string;
  private baseUrl = 'https://www.strava.com/api/v3';
  private dryRun: boolean;
  private requestCount = 0;
  private rateLimitDelay = 1500; // 1.5 seconds between requests to avoid rate limits

  constructor(accessToken: string, dryRun: boolean = false) {
    this.accessToken = accessToken;
    this.dryRun = dryRun;
  }

  /**
   * Parse a Strava event URL to extract club ID and event ID
   */
  parseStravaEventUrl(url: string): { clubId: string; eventId: string } | null {
    // Format: https://www.strava.com/clubs/{clubId}/group_events/{eventId}
    const match = url.match(/strava\.com\/clubs\/(\d+)\/group_events\/(\d+)/);
    if (!match) {
      return null;
    }
    return {
      clubId: match[1]!,
      eventId: match[2]!,
    };
  }

  /**
   * Fetch a single Strava event by club ID and event ID
   */
  async fetchEvent(clubId: string, eventId: string): Promise<StravaClubEvent | null> {
    // Rate limiting
    this.requestCount++;
    if (this.requestCount > 1) {
      await this.sleep(this.rateLimitDelay);
    }

    try {
      const response = await fetch(
        `${this.baseUrl}/clubs/${clubId}/group_events/${eventId}`,
        {
          headers: {
            Authorization: `Bearer ${this.accessToken}`,
          },
        }
      );

      if (!response.ok) {
        if (response.status === 404) {
          console.warn(`  Event ${eventId} not found`);
          return null;
        }
        if (response.status === 429) {
          console.warn(`  Rate limited, waiting 60 seconds...`);
          await this.sleep(60000);
          return this.fetchEvent(clubId, eventId);
        }
        const error = (await response.json()) as StravaErrorResponse;
        console.error(`  Failed to fetch event: ${response.status} - ${error.message}`);
        return null;
      }

      return (await response.json()) as StravaClubEvent;
    } catch (error) {
      console.error(`  Error fetching event ${eventId}:`, error);
      return null;
    }
  }

  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  /**
   * Scan all seed files and collect strava event links
   */
  async collectStravaEventLinks(): Promise<
    Array<{
      file: string;
      runTitle: string;
      optionIndex: number;
      optionName: string | null;
      stravaEventLink: string;
      currentRouteLink: string | null;
    }>
  > {
    const runsDir = join(__dirname, '..', 'api', 'seeds', 'runs');
    const results: Array<{
      file: string;
      runTitle: string;
      optionIndex: number;
      optionName: string | null;
      stravaEventLink: string;
      currentRouteLink: string | null;
    }> = [];

    const orgDirs = await readdir(runsDir);

    for (const orgDir of orgDirs) {
      const orgPath = join(runsDir, orgDir);
      const orgStat = await stat(orgPath);

      if (!orgStat.isDirectory()) continue;

      const files = await readdir(orgPath);

      for (const file of files) {
        if (!file.endsWith('.ts')) continue;

        const filePath = join(orgPath, file);
        const content = await readFile(filePath, 'utf-8');

        // Import the module to get the data
        try {
          const module = await import(filePath);
          const data = module.data as TrailRunSeed;

          if (!data || !data.runs) continue;

          // Check each run option for strava event links
          for (let i = 0; i < data.runs.length; i++) {
            const option = data.runs[i]!;
            if (option.stravaEventLink) {
              results.push({
                file: filePath,
                runTitle: data.title,
                optionIndex: i,
                optionName: option.name,
                stravaEventLink: option.stravaEventLink,
                currentRouteLink: option.stravaRouteLink,
              });
            }
          }

          // Also check top-level strava event link
          if (data.stravaEventLink) {
            results.push({
              file: filePath,
              runTitle: data.title,
              optionIndex: -1, // Indicates top-level
              optionName: null,
              stravaEventLink: data.stravaEventLink,
              currentRouteLink: null,
            });
          }
        } catch (error) {
          console.error(`Error loading ${filePath}:`, error);
        }
      }
    }

    return results;
  }

  /**
   * Update a seed file with a new route link
   */
  async updateSeedFile(
    filePath: string,
    optionIndex: number,
    routeLink: string
  ): Promise<boolean> {
    if (this.dryRun) {
      return true;
    }

    try {
      let content = await readFile(filePath, 'utf-8');

      if (optionIndex === -1) {
        // Update top-level stravaRouteLink (not currently in interface, but could be added)
        console.warn(`  Top-level stravaRouteLink not supported yet`);
        return false;
      }

      // Find and update the stravaRouteLink for the specific run option
      // This is a simple approach - find the nth occurrence of stravaRouteLink: null
      // and replace it with the route link

      // Parse the runs array more carefully
      const runsMatch = content.match(/runs:\s*\[/);
      if (!runsMatch) {
        console.error(`  Could not find runs array in ${filePath}`);
        return false;
      }

      // Find all stravaRouteLink occurrences within runs
      let runOptionCount = -1;
      let updatedContent = content.replace(
        /stravaRouteLink:\s*null/g,
        (match, offset) => {
          // Check if this occurrence is after the runs: [ start
          if (offset > runsMatch.index!) {
            runOptionCount++;
            if (runOptionCount === optionIndex) {
              return `stravaRouteLink: "${routeLink}"`;
            }
          }
          return match;
        }
      );

      if (updatedContent === content) {
        console.warn(`  No stravaRouteLink: null found at option index ${optionIndex}`);
        return false;
      }

      await writeFile(filePath, updatedContent, 'utf-8');
      return true;
    } catch (error) {
      console.error(`  Error updating ${filePath}:`, error);
      return false;
    }
  }

  /**
   * Main sync function
   */
  async sync(): Promise<UpdateResult[]> {
    console.log('Collecting Strava event links from seed files...\n');

    const eventLinks = await this.collectStravaEventLinks();
    console.log(`Found ${eventLinks.length} Strava event links\n`);

    const results: UpdateResult[] = [];

    for (const link of eventLinks) {
      const parsed = this.parseStravaEventUrl(link.stravaEventLink);
      if (!parsed) {
        console.log(`Skipping invalid URL: ${link.stravaEventLink}`);
        continue;
      }

      // Skip if already has a route link
      if (link.currentRouteLink) {
        console.log(
          `Skipping ${link.runTitle} - ${link.optionName || 'main'}: already has route link`
        );
        continue;
      }

      console.log(
        `Fetching event for ${link.runTitle} - ${link.optionName || 'main'}...`
      );

      const event = await this.fetchEvent(parsed.clubId, parsed.eventId);

      if (!event) {
        console.log(`  No event data found`);
        continue;
      }

      if (!event.route_id) {
        console.log(`  No route attached to event "${event.title}"`);
        continue;
      }

      const routeLink = `https://www.strava.com/routes/${event.route_id}`;
      console.log(`  Found route: ${routeLink}`);

      let updated = false;
      if (link.optionIndex >= 0) {
        updated = await this.updateSeedFile(link.file, link.optionIndex, routeLink);
        if (updated) {
          console.log(
            this.dryRun ? `  Would update seed file` : `  Updated seed file`
          );
        }
      }

      results.push({
        file: link.file,
        runTitle: link.runTitle,
        optionName: link.optionName,
        eventId: parsed.eventId,
        routeId: event.route_id,
        routeLink,
        updated,
      });
    }

    return results;
  }
}

async function main() {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run');

  const accessToken = process.env.STRAVA_ACCESS_TOKEN;

  if (!accessToken) {
    console.error('Error: STRAVA_ACCESS_TOKEN environment variable is required');
    console.error('');
    console.error('To get an access token:');
    console.error('1. Run: pnpm tsx scripts/strava-auth.ts get-auth-url');
    console.error('2. Follow the authentication flow');
    console.error('3. Set the token: export STRAVA_ACCESS_TOKEN="your_token_here"');
    process.exit(1);
  }

  if (dryRun) {
    console.log('Running in dry-run mode - no files will be modified\n');
  }

  console.log('Starting Strava route sync...\n');

  const syncer = new StravaRouteSyncer(accessToken, dryRun);

  try {
    const results = await syncer.sync();

    console.log('\n' + '═'.repeat(80));
    console.log('SYNC SUMMARY');
    console.log('═'.repeat(80));

    const updated = results.filter((r) => r.updated);
    const withRoutes = results.filter((r) => r.routeId);

    console.log(`Total events processed: ${results.length}`);
    console.log(`Events with routes: ${withRoutes.length}`);
    console.log(`Seed files updated: ${updated.length}`);

    if (withRoutes.length > 0) {
      console.log('\nRoutes found:');
      for (const result of withRoutes) {
        const status = result.updated
          ? dryRun
            ? '[would update]'
            : '[updated]'
          : '[skipped]';
        console.log(
          `  ${result.runTitle} - ${result.optionName || 'main'}: ${result.routeLink} ${status}`
        );
      }
    }

    if (dryRun && updated.length > 0) {
      console.log('\nRun without --dry-run to apply changes.');
    }
  } catch (error) {
    console.error('Error during sync:', error);
    process.exit(1);
  }
}

main();
