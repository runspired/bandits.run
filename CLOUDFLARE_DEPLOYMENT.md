# Cloudflare Pages Deployment Guide

This document explains how to deploy bandits.run as an SPA with SEO optimization on Cloudflare Pages.

## What Changed

The application has been configured for Cloudflare Pages deployment with history-based routing:

1. **Routing Mode**: Switched from hash routing (`#/path`) to history routing (`/path`)
2. **Cloudflare Config**: Added `_redirects` file to handle client-side routing fallback
3. **SEO Headers**: Added `_headers` file for caching and SEO optimization
4. **URL Generation**: Updated canonical URLs to use clean paths without hashes

## Prerequisites

- A Cloudflare account (free tier works fine)
- Your code in a Git repository (GitHub, GitLab, or Bitbucket)
- Node.js and pnpm installed locally

## Deployment Steps

### Option 1: Deploy via Cloudflare Dashboard (Recommended for first deployment)

1. **Build your application locally to verify:**
   ```bash
   pnpm build
   ```

2. **Push your code to GitHub/GitLab/Bitbucket**

3. **Connect to Cloudflare Pages:**
   - Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
   - Navigate to "Workers & Pages" → "Create application" → "Pages" → "Connect to Git"
   - Select your repository

4. **Configure build settings:**
   - **Framework preset**: None (or Custom)
   - **Build command**: `pnpm build`
   - **Build output directory**: `dist`
   - **Node version**: `24` (set in environment variable: `NODE_VERSION=24`)

5. **Deploy:**
   - Click "Save and Deploy"
   - Cloudflare will build and deploy your site
   - Your site will be available at `https://<your-project>.pages.dev`

### Option 2: Deploy via Wrangler CLI

1. **Install Wrangler:**
   ```bash
   pnpm add -D wrangler
   ```

2. **Login to Cloudflare:**
   ```bash
   pnpm wrangler login
   ```

3. **Build your application:**
   ```bash
   pnpm build
   ```

4. **Deploy:**
   ```bash
   pnpm wrangler pages deploy dist --project-name=bandits-web
   ```

## Custom Domain Setup

1. In Cloudflare Dashboard, go to your Pages project
2. Navigate to "Custom domains"
3. Click "Set up a custom domain"
4. Enter your domain (e.g., `bandits.run`)
5. Follow the DNS configuration steps
6. Cloudflare will automatically provision an SSL certificate

## Important Files

### `public/_redirects`
This file tells Cloudflare Pages to serve static assets directly and fallback all other routes to `index.html` for client-side routing:
- Static assets (fonts, images, CSS, JS, etc.) are served with `200` status
- All other routes fallback to `/index.html 200` for SPA routing
- This enables clean URLs without hash fragments

### `public/_headers`
This file configures HTTP headers for different file types:
- **SEO headers**: `X-Robots-Tag: all` ensures crawlability
- **Caching**: Aggressive caching for static assets, shorter cache for dynamic content
- **Security**: Basic security headers (`X-Frame-Options`, `X-Content-Type-Options`)

## SEO Optimization

Your site is SEO-ready with:

1. **Clean URLs**: No hash fragments (`/organizations/123/runs/456` instead of `#/organizations/123/runs/456`)
2. **Meta tags**: The `SocialGraph` component generates proper Open Graph and meta tags
3. **Crawlable**: All routes return the main HTML, allowing crawlers to execute JavaScript
4. **Sitemaps**: Consider adding a sitemap generator for better crawl coverage

### Testing SEO

After deployment, test your SEO implementation:

```bash
# Test with curl to see what crawlers see
curl -A "Googlebot" https://your-domain.com/organizations/123/runs/456

# Validate Open Graph tags
curl https://your-domain.com/organizations/123/runs/456 | grep "og:"
```

Use tools like:
- [Google Search Console](https://search.google.com/search-console)
- [Open Graph Debugger](https://www.opengraph.xyz/)
- [Twitter Card Validator](https://cards-dev.twitter.com/validator)

## Environment Variables

If you need to add environment variables:

1. **Via Dashboard**: Pages project → Settings → Environment variables
2. **Via Wrangler**: Use `wrangler pages project create` with `--env` flags

## Monitoring and Analytics

Consider adding:
- **Cloudflare Web Analytics** (free, privacy-friendly)
- **Google Search Console** for SEO monitoring
- **Cloudflare Logs** for debugging

## Progressive Web App (PWA)

Your PWA features will continue to work:
- Service worker is configured via `vite-plugin-pwa`
- Caching strategies are defined in `vite.config.mjs`
- The manifest is auto-generated

## Rollbacks

If you need to rollback:
1. Go to Cloudflare Dashboard → Your project → Deployments
2. Find the previous successful deployment
3. Click "Rollback to this deployment"

## Local Development

To test the history routing locally:

```bash
pnpm start
```

The Vite dev server automatically handles history routing with fallback to `index.html`.

## Troubleshooting

### 404 errors on direct URL access
- **Cause**: `_redirects` file not properly configured or deployed
- **Fix**: Ensure `_redirects` is in the `public` folder and gets copied to `dist` during build
- **Verify**: Check that `dist/_redirects` exists after running `pnpm build`
- **Deploy**: Make sure to redeploy after adding the `_redirects` file

### Assets not loading
- **Cause**: Incorrect `rootURL` or asset paths
- **Fix**: Verify `rootURL: '/'` in `app/config/environment.ts`

### Service worker issues
- **Cause**: Caching old hash-based routes
- **Fix**: Clear browser cache and service worker storage, or increment the cache version

### Maps not loading
- **Cause**: CSP or CORS issues with map tiles
- **Fix**: Check Cloudflare's automatic CSP headers aren't blocking map tile requests

## Next Steps

Consider these enhancements:

1. **Dynamic Sitemap**: Generate a sitemap from your API data
2. **Structured Data**: Add JSON-LD structured data for rich snippets
3. **Performance**: Enable Cloudflare's speed optimizations (Auto Minify, Brotli)
4. **Analytics**: Add Cloudflare Web Analytics or similar
5. **A/B Testing**: Use Cloudflare Workers for A/B tests

## Resources

- [Cloudflare Pages Documentation](https://developers.cloudflare.com/pages/)
- [Single-page apps on Cloudflare Pages](https://developers.cloudflare.com/pages/configuration/serving-pages/#single-page-application-spa-rendering)
- [Cloudflare Pages Headers](https://developers.cloudflare.com/pages/configuration/headers/)
- [Ember.js Deployment Guide](https://cli.emberjs.com/release/basic-use/deploying/)
