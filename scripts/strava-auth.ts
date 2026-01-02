#!/usr/bin/env node

/**
 * Helper script to obtain and refresh Strava API access tokens
 *
 * Usage:
 *   # Get initial authorization URL
 *   node scripts/strava-auth.ts get-auth-url
 *
 *   # Exchange authorization code for tokens
 *   node scripts/strava-auth.ts exchange-token <authorization_code>
 *
 *   # Refresh an expired access token
 *   node scripts/strava-auth.ts refresh-token <refresh_token>
 *
 * Environment variables required:
 *   STRAVA_CLIENT_ID - Your Strava application client ID
 *   STRAVA_CLIENT_SECRET - Your Strava application client secret
 */

interface StravaTokenResponse {
  token_type: string;
  expires_at: number;
  expires_in: number;
  refresh_token: string;
  access_token: string;
  athlete: {
    id: number;
    username: string;
    resource_state: number;
    firstname: string;
    lastname: string;
    // ... other athlete fields
  };
}

interface StravaRefreshTokenResponse {
  token_type: string;
  access_token: string;
  expires_at: number;
  expires_in: number;
  refresh_token: string;
}

class StravaAuth {
  private clientId: string;
  private clientSecret: string;
  private readonly authUrl = 'https://www.strava.com/oauth/authorize';
  private readonly tokenUrl = 'https://www.strava.com/oauth/token';

  constructor(clientId: string, clientSecret: string) {
    this.clientId = clientId;
    this.clientSecret = clientSecret;
  }

  /**
   * Generate the OAuth authorization URL
   */
  getAuthorizationUrl(redirectUri = 'http://localhost', scope = 'read,activity:read'): string {
    const params = new URLSearchParams({
      client_id: this.clientId,
      redirect_uri: redirectUri,
      response_type: 'code',
      approval_prompt: 'auto',
      scope: scope,
    });

    return `${this.authUrl}?${params}`;
  }

  /**
   * Exchange authorization code for access and refresh tokens
   */
  async exchangeToken(code: string): Promise<StravaTokenResponse> {
    const response = await fetch(this.tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        client_id: this.clientId,
        client_secret: this.clientSecret,
        code: code,
        grant_type: 'authorization_code',
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Failed to exchange token: ${response.status} - ${error}`);
    }

    return response.json();
  }

  /**
   * Refresh an expired access token
   */
  async refreshToken(refreshToken: string): Promise<StravaRefreshTokenResponse> {
    const response = await fetch(this.tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        client_id: this.clientId,
        client_secret: this.clientSecret,
        grant_type: 'refresh_token',
        refresh_token: refreshToken,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Failed to refresh token: ${response.status} - ${error}`);
    }

    return response.json();
  }

  /**
   * Check if a token is expired
   */
  isTokenExpired(expiresAt: number): boolean {
    const now = Math.floor(Date.now() / 1000);
    // Consider token expired if it expires in the next 5 minutes
    return now >= (expiresAt - 300);
  }
}

// Main execution
async function main() {
  const args = process.argv.slice(2);
  const command = args[0];

  const clientId = process.env.STRAVA_CLIENT_ID;
  const clientSecret = process.env.STRAVA_CLIENT_SECRET;

  if (!clientId || !clientSecret) {
    console.error('Error: STRAVA_CLIENT_ID and STRAVA_CLIENT_SECRET environment variables are required');
    console.error('');
    console.error('To get these credentials:');
    console.error('1. Go to https://www.strava.com/settings/api');
    console.error('2. Create an application if you haven\'t already');
    console.error('3. Copy the Client ID and Client Secret');
    console.error('4. Set them as environment variables:');
    console.error('   export STRAVA_CLIENT_ID="your_client_id"');
    console.error('   export STRAVA_CLIENT_SECRET="your_client_secret"');
    process.exit(1);
  }

  const auth = new StravaAuth(clientId, clientSecret);

  try {
    switch (command) {
      case 'get-auth-url': {
        const url = auth.getAuthorizationUrl();
        console.log('🔗 Authorization URL:');
        console.log('');
        console.log(url);
        console.log('');
        console.log('Steps:');
        console.log('1. Open the URL above in your browser');
        console.log('2. Authorize the application');
        console.log('3. You will be redirected to a URL like: http://localhost?code=AUTHORIZATION_CODE');
        console.log('4. Copy the code parameter from the URL');
        console.log('5. Run: pnpm tsx scripts/strava-auth.ts exchange-token <code>');
        break;
      }

      case 'exchange-token': {
        const code = args[1];
        if (!code) {
          console.error('Error: Authorization code is required');
          console.error('Usage: pnpm tsx scripts/strava-auth.ts exchange-token <code>');
          process.exit(1);
        }

        console.log('Exchanging authorization code for tokens...');
        const tokens = await auth.exchangeToken(code);

        console.log('');
        console.log('✅ Success! Tokens obtained:');
        console.log('');
        console.log('Access Token:', tokens.access_token);
        console.log('Refresh Token:', tokens.refresh_token);
        console.log('Expires At:', new Date(tokens.expires_at * 1000).toISOString());
        console.log('Athlete:', `${tokens.athlete.firstname} ${tokens.athlete.lastname}`);
        console.log('');
        console.log('💾 Save these to your environment or .env.local file:');
        console.log('');
        console.log(`export STRAVA_ACCESS_TOKEN="${tokens.access_token}"`);
        console.log(`export STRAVA_REFRESH_TOKEN="${tokens.refresh_token}"`);
        console.log(`export STRAVA_TOKEN_EXPIRES_AT="${tokens.expires_at}"`);
        console.log('');
        console.log('⚠️  The access token expires in 6 hours. Use the refresh token to get a new one.');
        break;
      }

      case 'refresh-token': {
        const refreshToken = args[1] || process.env.STRAVA_REFRESH_TOKEN;
        if (!refreshToken) {
          console.error('Error: Refresh token is required');
          console.error('Usage: pnpm tsx scripts/strava-auth.ts refresh-token <refresh_token>');
          console.error('Or set STRAVA_REFRESH_TOKEN environment variable');
          process.exit(1);
        }

        console.log('Refreshing access token...');
        const tokens = await auth.refreshToken(refreshToken);

        console.log('');
        console.log('✅ Success! New tokens obtained:');
        console.log('');
        console.log('Access Token:', tokens.access_token);
        console.log('Refresh Token:', tokens.refresh_token);
        console.log('Expires At:', new Date(tokens.expires_at * 1000).toISOString());
        console.log('');
        console.log('💾 Update your environment variables:');
        console.log('');
        console.log(`export STRAVA_ACCESS_TOKEN="${tokens.access_token}"`);
        console.log(`export STRAVA_REFRESH_TOKEN="${tokens.refresh_token}"`);
        console.log(`export STRAVA_TOKEN_EXPIRES_AT="${tokens.expires_at}"`);
        break;
      }

      default:
        console.error('Unknown command:', command);
        console.error('');
        console.error('Available commands:');
        console.error('  get-auth-url     - Generate OAuth authorization URL');
        console.error('  exchange-token   - Exchange authorization code for tokens');
        console.error('  refresh-token    - Refresh an expired access token');
        process.exit(1);
    }
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

main();
