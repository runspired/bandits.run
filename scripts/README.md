# Strava Event Fetcher Scripts

Scripts to fetch upcoming events from Strava clubs using the Strava API.

## Setup

### 1. Create a Strava API Application

1. Go to [https://www.strava.com/settings/api](https://www.strava.com/settings/api)
2. Create a new application
3. Note your **Client ID** and **Client Secret**
4. Set the **Authorization Callback Domain** to `localhost`

### 2. Set Environment Variables

Create a `.env.local` file in the project root (this file is gitignored):

```bash
# Strava API Credentials
STRAVA_CLIENT_ID=your_client_id_here
STRAVA_CLIENT_SECRET=your_client_secret_here

# These will be obtained through the auth flow
STRAVA_ACCESS_TOKEN=your_access_token_here
STRAVA_REFRESH_TOKEN=your_refresh_token_here
STRAVA_TOKEN_EXPIRES_AT=1234567890
```

### 3. Install tsx (if not already installed)

```bash
pnpm add -D tsx
```

## Usage

### Getting Your First Access Token

**Step 1: Generate the authorization URL**

```bash
pnpm tsx scripts/strava-auth.ts get-auth-url
```

This will output a URL. Open it in your browser.

**Step 2: Authorize the application**

You'll be redirected to a URL like: `http://localhost/?code=AUTHORIZATION_CODE&scope=read,activity:read`

Copy the `code` parameter from the URL.

**Step 3: Exchange the code for tokens**

```bash
pnpm tsx scripts/strava-auth.ts exchange-token <code>
```

This will output your access token and refresh token. Add these to your `.env.local` file.

### Fetching Club Events

Once you have an access token, you can fetch events for a club:

```bash
pnpm strava:fetch-events <clubId>
```

Example:

```bash
pnpm strava:fetch-events 123456
```

To save the events to a JSON file:

```bash
SAVE_TO_FILE=true pnpm strava:fetch-events 123456
```

### Fetching Route Details and GPX

You can fetch detailed stats and GPX data for any Strava route:

```bash
pnpm strava:fetch-route <routeId>
```

This will display:
- Distance (miles, kilometers, meters)
- Elevation gain and loss
- Surface type (road, trail, mountain bike, etc.)
- Activity type (run, ride)
- Estimated moving time
- Route URL and metadata

**To save the GPX file:**

```bash
pnpm strava:fetch-route <routeId> --save-gpx
```

**To save the stats as JSON:**

```bash
pnpm strava:fetch-route <routeId> --save-stats
```

**To save both and specify a custom output directory:**

```bash
pnpm strava:fetch-route <routeId> --save-gpx --save-stats --output-dir ./api/seeds/routes
```

Example:

```bash
# Just view stats
pnpm strava:fetch-route 3147857

# Download GPX and stats
pnpm strava:fetch-route 3147857 --save-gpx --save-stats
```

### Refreshing Your Access Token

Strava access tokens expire after 6 hours. To get a new one:

```bash
pnpm tsx scripts/strava-auth.ts refresh-token
```

This will use the `STRAVA_REFRESH_TOKEN` from your environment and generate a new access token.

## Finding IDs on Strava

### Club ID

To find a Strava club ID:

1. Go to the club page on Strava
2. Look at the URL: `https://www.strava.com/clubs/123456`
3. The number at the end (123456) is the club ID

### Route ID

To find a Strava route ID:

1. Go to the route page on Strava
2. Look at the URL: `https://www.strava.com/routes/3147857`
3. The number at the end (3147857) is the route ID

## Important Notes

### No Individual User Authentication Required

These scripts use a single service account approach:

- You authenticate once using your own Strava account
- The access token is stored as an environment variable
- You can fetch events for any public club (or clubs you're a member of)
- No need to authenticate individual users of your application

### Token Expiration

- Access tokens expire after 6 hours
- Refresh tokens do not expire (unless revoked)
- Always refresh the access token before it expires
- The refresh token endpoint also returns a new refresh token (update your `.env.local`)

### API Rate Limits

Strava has rate limits:

- 100 requests per 15 minutes
- 1000 requests per day

For production use, implement proper rate limiting and caching.

### Group Events Endpoint

The Strava API's group events endpoint (`/clubs/{id}/group_events`) may not be officially documented or available for all clubs. If you encounter issues:

1. The script will fall back gracefully
2. You may need to explore alternative endpoints
3. Consider contacting Strava API support for access

### Route Access and GPX Export

- You can view stats for any public route
- GPX export may only work for routes created by the authenticated user or routes you have explicit access to
- If GPX export fails, you can still get the route stats (distance, elevation, etc.)
- Private routes require the authenticated user to have access

## Troubleshooting

### "Invalid authorization code"

The authorization code can only be used once. Generate a new one with `get-auth-url` and try again.

### "Invalid refresh token"

Your refresh token may have been revoked. Go through the full authorization flow again.

### "Resource not found" for club

- Verify the club ID is correct
- Ensure your account has access to the club (for private clubs)
- Check that your access token has the correct scopes

## Integration with Your Application

Once you have events data, you can:

1. Transform the Strava events to match your `TrailRun` interface
2. Store them in your `api/seeds` directory
3. Import them into your application

Example transformation:

```typescript
import type { TrailRun } from '../api/interfaces/run';
import type { StravaClubEvent } from './fetch-strava-events';

function stravaEventToTrailRun(event: StravaClubEvent): TrailRun {
  return {
    title: event.title,
    description: event.description || null,
    location: 'location-id', // Map from Strava address to your location ID
    recurrence: {
      // Determine from event.upcoming_occurrences
      frequency: 'once',
      day: null,
      interval: 1,
      weekNumber: null,
      date: event.upcoming_occurrences[0],
      holiday: null,
    },
    hosts: ['organization-id'], // Your organization ID
    organizers: [],
    runs: [{
      name: null,
      leaders: [],
      distance: '5-10 Mi', // Parse from description if available
      vert: '500-1000ft',
      pace: null,
      category: 'at-your-own-pace',
      meetTime: '18:00',
      startTime: '18:15',
      eventLink: `https://www.strava.com/clubs/${event.club_id}/group_events/${event.id}`,
      stravaRouteLink: event.route_id ? `https://www.strava.com/routes/${event.route_id}` : null,
      gpxLink: null,
    }],
    eventLink: null,
  };
}
```
