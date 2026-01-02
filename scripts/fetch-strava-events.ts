#!/usr/bin/env node

/**
 * Script to fetch upcoming events for a Strava club
 *
 * Usage:
 *   node scripts/fetch-strava-events.ts <clubId>
 *
 * Environment variables required:
 *   STRAVA_ACCESS_TOKEN - A Strava API access token with read permissions
 *
 * To get an access token:
 *   1. Create a Strava API application at https://www.strava.com/settings/api
 *   2. Use the OAuth flow to get an access token, or use the initial access token provided
 *   3. For long-lived tokens, implement a refresh token flow
 *
 * Note: Strava API requires authentication, but you don't need to authenticate
 * individual users - you can use a single service account token.
 */

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
  upcoming_occurrences: string[]; // ISO 8601 datetime strings
  address: string;
  // Additional fields that might be present
  visibility?: string;
  zone?: string;
}

interface StravaClubActivitiesOptions {
  clubId: string;
  page?: number;
  per_page?: number;
}

interface StravaErrorResponse {
  message: string;
  errors: Array<{
    resource: string;
    field: string;
    code: string;
  }>;
}

class StravaEventFetcher {
  private accessToken: string;
  private baseUrl = 'https://www.strava.com/api/v3';

  constructor(accessToken: string) {
    this.accessToken = accessToken;
  }

  /**
   * Fetch club events from Strava
   * Note: As of 2025, Strava's API v3 doesn't have a dedicated events endpoint.
   * This method attempts to use the club activities endpoint and filters for upcoming events.
   */
  async fetchClubEvents(clubId: string): Promise<StravaClubEvent[]> {
    try {
      // First, try to get club details to verify access
      const clubResponse = await fetch(`${this.baseUrl}/clubs/${clubId}`, {
        headers: {
          Authorization: `Bearer ${this.accessToken}`,
        },
      });

      if (!clubResponse.ok) {
        const error = await clubResponse.json() as StravaErrorResponse;
        throw new Error(`Failed to fetch club: ${clubResponse.status} - ${error.message || 'Unknown error'}`);
      }

      const club = await clubResponse.json();
      console.log(`Found club: ${club.name}`);

      // Attempt to fetch club group events (this endpoint may not be officially documented)
      const eventsResponse = await fetch(`${this.baseUrl}/clubs/${clubId}/group_events`, {
        headers: {
          Authorization: `Bearer ${this.accessToken}`,
        },
      });

      if (!eventsResponse.ok) {
        if (eventsResponse.status === 404) {
          console.warn('Group events endpoint not found. This may not be available for all clubs or API versions.');
          return [];
        }
        const error = await eventsResponse.json() as StravaErrorResponse;
        throw new Error(`Failed to fetch events: ${eventsResponse.status} - ${error.message || 'Unknown error'}`);
      }

      const events = await eventsResponse.json() as StravaClubEvent[];

      // Filter for upcoming events
      const now = new Date();
      const upcomingEvents = events.filter(event => {
        if (!event.upcoming_occurrences || event.upcoming_occurrences.length === 0) {
          return false;
        }
        // Check if any occurrence is in the future
        return event.upcoming_occurrences.some(occurrence => {
          const occurrenceDate = new Date(occurrence);
          return occurrenceDate > now;
        });
      });

      return upcomingEvents;
    } catch (error) {
      if (error instanceof Error) {
        throw error;
      }
      throw new Error(`Unknown error: ${String(error)}`);
    }
  }

  /**
   * Alternative method: Fetch recent club activities
   * This can be used if the events endpoint is not available
   */
  async fetchClubActivities(options: StravaClubActivitiesOptions): Promise<any[]> {
    const { clubId, page = 1, per_page = 30 } = options;

    const params = new URLSearchParams({
      page: String(page),
      per_page: String(per_page),
    });

    const response = await fetch(
      `${this.baseUrl}/clubs/${clubId}/activities?${params}`,
      {
        headers: {
          Authorization: `Bearer ${this.accessToken}`,
        },
      }
    );

    if (!response.ok) {
      const error = await response.json() as StravaErrorResponse;
      throw new Error(`Failed to fetch activities: ${response.status} - ${error.message || 'Unknown error'}`);
    }

    return response.json();
  }

  /**
   * Pretty print events to console
   */
  printEvents(events: StravaClubEvent[]): void {
    console.log(`\nFound ${events.length} upcoming events:\n`);

    events.forEach(event => {
      console.log('━'.repeat(80));
      console.log(`📅 ${event.title}`);
      console.log(`   ID: ${event.id}`);
      console.log(`   Type: ${event.activity_type}`);
      if (event.description) {
        console.log(`   Description: ${event.description}`);
      }
      if (event.address) {
        console.log(`   Location: ${event.address}`);
      }
      console.log(`   Upcoming occurrences:`);
      event.upcoming_occurrences.forEach(occurrence => {
        const date = new Date(occurrence);
        console.log(`     - ${date.toLocaleString()}`);
      });
      console.log('');
    });
  }
}

// Main execution
async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.error('Usage: pnpm tsx scripts/fetch-strava-events.ts <clubId>');
    console.error('');
    console.error('Example: pnpm tsx scripts/fetch-strava-events.ts 123456');
    console.error('');
    console.error('Environment variables required:');
    console.error('  STRAVA_ACCESS_TOKEN - Your Strava API access token');
    process.exit(1);
  }

  const clubId = args[0];
  const accessToken = process.env.STRAVA_ACCESS_TOKEN;

  if (!accessToken) {
    console.error('Error: STRAVA_ACCESS_TOKEN environment variable is required');
    console.error('');
    console.error('To get an access token:');
    console.error('1. Go to https://www.strava.com/settings/api');
    console.error('2. Create an application if you haven\'t already');
    console.error('3. Use the OAuth flow to generate an access token');
    console.error('4. Set the token: export STRAVA_ACCESS_TOKEN="your_token_here"');
    process.exit(1);
  }

  console.log(`Fetching events for club ${clubId}...`);

  const fetcher = new StravaEventFetcher(accessToken);

  try {
    const events = await fetcher.fetchClubEvents(clubId);
    fetcher.printEvents(events);

    // Optional: save to JSON file
    if (process.env.SAVE_TO_FILE === 'true') {
      const fs = await import('fs/promises');
      const outputPath = `./api/seeds/strava-events-${clubId}-${Date.now()}.json`;
      await fs.writeFile(outputPath, JSON.stringify(events, null, 2));
      console.log(`\n✅ Events saved to ${outputPath}`);
    }
  } catch (error) {
    console.error('❌ Error fetching events:', error);
    process.exit(1);
  }
}

main();
