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
        'leaflet-images/marker-icon.png',
        'leaflet-images/marker-icon-2x.png',
        'leaflet-images/marker-shadow.png',
        'fonts/montserrat-regular.woff2',
        'fonts/montserrat-bold.woff2',
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
        // Cache all static assets
        globPatterns: ['**/*.{js,css,html,ico,png,svg,woff2}'],
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
            // Cache Stadia Maps tiles
            urlPattern: /^https:\/\/tiles\.stadiamaps\.com\/.*/i,
            handler: 'CacheFirst',
            options: {
              cacheName: 'stadia-map-tiles',
              expiration: {
                maxEntries: 500,
                maxAgeSeconds: 60 * 60 * 24 * 30 // 30 days
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
