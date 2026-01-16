import { defineConfig } from 'vite';
import { extensions, ember } from '@embroider/vite';
import { babel } from '@rollup/plugin-babel';
import { scopedCSS } from 'ember-scoped-css/vite';
import { VitePWA } from 'vite-plugin-pwa';

export default defineConfig({
  plugins: [
    ember(),
    scopedCSS(),
    // extra plugins here
    babel({
      babelHelpers: 'runtime',
      extensions,
      exclude: [/\/dev-sw\.js/, /\/sw\.js/, /workbox-.*\.js/],
    }),
    VitePWA({
      registerType: 'autoUpdate',
      strategies: 'generateSW',
      includeAssets: [
        'favicon.ico',
        'images/light/logo-chevron-inverted.svg',
        'images/light/apple-touch-icon-180x180-chevron-inverted.png',
        'nps.svg',
        'redwood.svg',
        'logo-orange-chevron.svg',
        'fonts/montserrat-italic.woff2',
        'fonts/montserrat-normal.woff2',
        '**/*.json',
        '**/*.css',
        '**/*.js',
        '**/*.html'
      ],
      injectRegister: false,
      srcDir: 'app',
      outDir: 'dist',
      devOptions: {
        enabled: true,
        type: 'module',
      },
      manifest: {
        name: 'The Bandits',
        short_name: 'Bandits',
        description: 'Find Your Trail Friends! The Bandits are a Trail Running Community based in the SF Bay Area.',
        theme_color: '#ffffff',
        background_color: '#ffffff',
        display: 'standalone',
        start_url: '/',
        icons: [
          {
            src: '/images/light/logo-chevron-inverted.svg',
            sizes: 'any',
            type: 'image/svg+xml',
            purpose: 'any maskable'
          },
          {
            src: '/images/light/apple-touch-icon-180x180-chevron-inverted.png',
            sizes: '180x180',
            type: 'image/png'
          }
        ]
      },
      workbox: {
        // Serve index.html for navigation requests when offline
        navigateFallback: '/index.html',
        navigateFallbackDenylist: [/^\/api\//],
        // Cache all static assets including map styles
        globPatterns: [
          '**/*.{js,css,html,ico,png,svg,woff2}',
          'map-styles/*.json'
        ],
        // Runtime caching strategies
        runtimeCaching: [
          {
            // Cache week JSON files with StaleWhileRevalidate
            // Serve from cache immediately, update in background
            urlPattern: /\/api\/weeks\/.*\.json$/,
            handler: 'StaleWhileRevalidate',
            options: {
              cacheName: 'api-weeks-cache',
              expiration: {
                maxEntries: 100,
                maxAgeSeconds: 60 * 60 * 24 * 7 // 1 week
              },
              cacheableResponse: {
                statuses: [0, 200]
              }
            }
          },
          {
            // Cache other API JSON files
            urlPattern: /\/api\/.*\.json$/,
            handler: 'StaleWhileRevalidate',
            options: {
              cacheName: 'api-cache',
              expiration: {
                maxEntries: 50,
                maxAgeSeconds: 60 * 60 * 24 // 1 day
              }
            }
          },
          {
            // Cache OpenStreetMap.us vector tiles (openmaptiles, trails, contours)
            // Matches: https://tiles.openstreetmap.us/vector/{layer}/{z}/{x}/{y}.mvt
            urlPattern: ({ url }) => {
              return url.origin === 'https://tiles.openstreetmap.us' &&
                     url.pathname.startsWith('/vector/') &&
                     url.pathname.endsWith('.mvt');
            },
            handler: 'CacheFirst',
            options: {
              cacheName: 'osm-vector-tiles',
              expiration: {
                maxEntries: 1000,
                maxAgeSeconds: 60 * 60 * 24 * 90 // 90 days
              },
              cacheableResponse: {
                statuses: [0, 200]
              }
            }
          },
          {
            // Cache OpenStreetMap.us raster tiles (hillshade)
            // Matches: https://tiles.openstreetmap.us/raster/{layer}/{z}/{x}/{y}.jpg
            urlPattern: ({ url }) => {
              return url.origin === 'https://tiles.openstreetmap.us' &&
                     url.pathname.startsWith('/raster/') &&
                     (url.pathname.endsWith('.jpg') || url.pathname.endsWith('.png'));
            },
            handler: 'CacheFirst',
            options: {
              cacheName: 'osm-raster-tiles',
              expiration: {
                maxEntries: 500,
                maxAgeSeconds: 60 * 60 * 24 * 90 // 90 days
              },
              cacheableResponse: {
                statuses: [0, 200]
              }
            }
          },
          {
            // Cache MapLibre GL JS assets (sprites, glyphs, etc.)
            urlPattern: /^https:\/\/.*\/maplibre-gl.*\.(css|js|woff2?|pbf|png)$/i,
            handler: 'CacheFirst',
            options: {
              cacheName: 'maplibre-assets',
              expiration: {
                maxEntries: 100,
                maxAgeSeconds: 60 * 60 * 24 * 90 // 90 days
              },
              cacheableResponse: {
                statuses: [0, 200]
              }
            }
          }
        ]
      }
    })
  ],
});
