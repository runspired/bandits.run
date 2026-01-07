Bay Bandits Logo Assets
=======================

This package contains assets for both light and dark themes, organized in separate folders.
Each theme includes both full logo (with text) and chevron-only variants.

STRUCTURE:
----------
light/               Light theme assets
  ├── favicon-32x32.png              Favicon 32x32 PNG (with text)
  ├── favicon-32x32-inverted.png     Favicon 32x32 PNG (with text, inverted colors)
  ├── favicon.ico                    Favicon ICO format (with text)
  ├── favicon-inverted.ico           Favicon ICO format (with text, inverted colors)
  ├── favicon-32x32-chevron.png      Favicon 32x32 PNG (chevron only)
  ├── favicon-32x32-chevron-inverted.png  Favicon 32x32 PNG (chevron only, inverted)
  ├── favicon-chevron.ico            Favicon ICO format (chevron only)
  ├── favicon-chevron-inverted.ico   Favicon ICO format (chevron only, inverted)
  ├── apple-touch-icon-180x180.png   Apple Touch Icon 180x180 (with text)
  ├── apple-touch-icon-180x180-inverted.png   Apple Touch Icon (with text, inverted)
  ├── apple-touch-icon-180x180-chevron.png    Apple Touch Icon (chevron only)
  ├── apple-touch-icon-180x180-chevron-inverted.png  Apple Touch Icon (chevron, inverted)
  ├── android-chrome-192x192.png     App icon 192x192 (with text)
  ├── android-chrome-192x192-inverted.png     App icon 192x192 (with text, inverted)
  ├── android-chrome-192x192-chevron.png      App icon 192x192 (chevron only)
  ├── android-chrome-192x192-chevron-inverted.png  App icon 192x192 (chevron, inverted)
  ├── android-chrome-512x512.png     App icon 512x512 (with text)
  ├── android-chrome-512x512-inverted.png     App icon 512x512 (with text, inverted)
  ├── android-chrome-512x512-chevron.png      App icon 512x512 (chevron only)
  ├── android-chrome-512x512-chevron-inverted.png  App icon 512x512 (chevron, inverted)
  ├── logo.svg                       Vector logo (with text)
  ├── logo-inverted.svg              Vector logo (with text, inverted colors)
  ├── logo-chevron.svg               Vector logo (chevron only)
  ├── logo-chevron-inverted.svg      Vector logo (chevron only, inverted colors)
  ├── og-logo-600x600.png            Social media preview square (with text)
  ├── og-logo-600x600-inverted.png   Social media preview square (with text, inverted)
  ├── og-logo-600x600-chevron.png    Social media preview square (chevron only)
  ├── og-logo-600x600-chevron-inverted.png  Social media preview (chevron, inverted)
  ├── og-banner-1200x630.png         Social media preview landscape banner PNG
  ├── og-banner-1210x593.png         Social media preview PNG (Strava dimensions)
  ├── og-banner-1210x593.svg         Social media preview SVG (Strava dimensions)
  └── site.manifest                  Web app manifest (references light theme icons)

dark/                Dark theme assets
  └── [same structure as light/]

logo-adaptive.svg                    Adaptive SVG (with text, auto-switches light/dark)
logo-adaptive-inverted.svg           Adaptive SVG (with text, inverted, auto-switches)
logo-chevron-adaptive.svg            Adaptive SVG (chevron only, auto-switches)
logo-chevron-adaptive-inverted.svg   Adaptive SVG (chevron only, inverted, auto-switches)
og-banner-adaptive.svg               Adaptive banner SVG (auto-switches light/dark)

USAGE NOTES:
------------
Logo Variants:
- Files without "-chevron" suffix include the full logo with "BAY BANDITS" text
- Files with "-chevron" suffix contain only the chevron icon (no text)
- Files with "-inverted" suffix swap the logo and background colors
  (e.g., if normal has purple logo on light background, inverted has light logo on purple background)
- Inverted variants are useful for creating visual contrast or matching different background contexts
- Choose the variant that best fits your use case and design needs

Site Icons:
- favicon.ico: Traditional favicon format for broad browser compatibility
- favicon-32x32.png: Modern PNG favicon for <link rel="icon" sizes="32x32" href="...">
- apple-touch-icon-180x180.png: Use in <link rel="apple-touch-icon" sizes="180x180" href="...">
- android-chrome-192x192.png & android-chrome-512x512.png: Referenced in site.manifest
- Chevron-only variants available for minimal/compact designs

Site Manifest:
- Use site.manifest as your web app manifest file
- Update icon paths in the manifest to match your deployment structure
- Serve with Content-Type: application/manifest+json
- Default manifest references full logos; update to -chevron variants if preferred

Social Media Previews (og:image):
- og-logo-600x600.png: Square variant (with text)
- og-logo-600x600-inverted.png: Square variant (with text, inverted colors)
- og-logo-600x600-chevron.png: Square variant (chevron only)
- og-logo-600x600-chevron-inverted.png: Square variant (chevron only, inverted colors)
- og-banner-1200x630.png: Standard Open Graph landscape format PNG (1.91:1 ratio)
- og-banner-1210x593.png: Strava club header dimensions PNG
- og-banner-1210x593.svg: Strava club header dimensions SVG (per theme)
- og-banner-adaptive.svg: Adaptive banner SVG (auto-switches with prefers-color-scheme)

Example HTML:
<!-- Traditional favicon -->
<link rel="icon" href="/light/favicon.ico">
<!-- Modern PNG favicons -->
<link rel="icon" type="image/png" sizes="32x32" href="/light/favicon-32x32.png">
<!-- Apple Touch Icon -->
<link rel="apple-touch-icon" sizes="180x180" href="/light/apple-touch-icon-180x180.png">
<!-- Web App Manifest -->
<link rel="manifest" href="/light/site.manifest">
<!-- Open Graph image -->
<meta property="og:image" content="https://yourdomain.com/light/og-banner-1200x630.png">

For chevron-only icons:
<link rel="icon" href="/light/favicon-chevron.ico">
<link rel="icon" type="image/png" sizes="32x32" href="/light/favicon-32x32-chevron.png">

For inverted color icons:
<link rel="icon" href="/light/favicon-inverted.ico">
<link rel="icon" type="image/png" sizes="32x32" href="/light/favicon-32x32-inverted.png">

Banner SVGs:
<!-- Theme-specific banner SVG -->
<img src="/light/og-banner-1210x593.svg" alt="Bay Bandits Banner">
<!-- Adaptive banner that auto-switches -->
<img src="/og-banner-adaptive.svg" alt="Bay Bandits Banner">

Adaptive SVGs (automatically switch between light/dark based on user's system preference):
<!-- Adaptive SVG that changes with prefers-color-scheme -->
<img src="/logo-adaptive.svg" alt="Bay Bandits Logo">
<!-- Chevron-only adaptive variant -->
<img src="/logo-chevron-adaptive.svg" alt="Bay Bandits Chevron">
<!-- Adaptive banner -->
<img src="/og-banner-adaptive.svg" alt="Bay Bandits Banner">

Adaptive SVG Features:
- Automatically adapts to user's system color scheme preference (light/dark mode)
- Uses CSS @media (prefers-color-scheme: dark) internally
- Single file that works in both themes
- Recommended for websites that support system-based theme switching
- Five variants: normal, inverted, chevron, chevron-inverted, and banner
- Each variant automatically switches colors between light and dark modes
- Banner SVG is perfect for hero sections, headers, or social media that support SVG

Generated: 2026-01-07T07:35:05.364Z
Theme: Both light and dark variants included