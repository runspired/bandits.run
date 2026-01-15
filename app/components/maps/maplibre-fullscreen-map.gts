import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';
import { tracked } from '@glimmer/tracking';
import MapLibreMap from '#maps/maplibre-map.gts';
import MapLibreMarker from '#maps/maplibre-marker.gts';
import MapLibreBoundary from '#maps/maplibre-boundary.gts';
import FaIcon from '#ui/fa-icon.gts';
import { faXmark } from '@fortawesome/free-solid-svg-icons';
import './fullscreen-map.css';
import { service } from '@ember/service';
import type PortalsService from '#app/services/ux/portals.ts';
import { getDevicePreferences } from '#app/core/preferences.ts';
import type { Map } from 'maplibre-gl';
import type { StyleSpecification } from 'maplibre-gl';

interface MapLibreFullscreenMapSignature {
  Args: {
    /**
     * Location ID for caching
     */
    locationId: string;

    /**
     * Location name for display
     */
    locationName: string;

    /**
     * Center latitude
     */
    lat: number;

    /**
     * Center longitude
     */
    lng: number;

    /**
     * Initial zoom level (default: 14)
     */
    zoom?: number;

    /**
     * Map style (default: OpenStreetMap style)
     */
    style?: string | StyleSpecification;

    /**
     * Callback when user closes the fullscreen map
     */
    onClose: () => void;
  };
}

export default class MapLibreFullscreenMap extends Component<MapLibreFullscreenMapSignature> {
  @service('ux/portals') declare portals: PortalsService;

  preferences = getDevicePreferences();

  map: Map | null = null;
  currentZoom: number = this.args.zoom ?? 14;
  locationWatchId: number | null = null;

  @tracked
  userLocation: { lat: number; lng: number } | null = null;

  @tracked
  userLocationElement: HTMLElement | null = null;

  setupEscapeKey = modifier((_element: HTMLElement) => {
    const handleEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        this.args.onClose();
      }
    };

    document.addEventListener('keydown', handleEscape);

    // Start watching location if enabled
    this.startLocationTracking();

    // Create user location element
    this.createUserLocationElement();

    return () => {
      document.removeEventListener('keydown', handleEscape);
      this.stopLocationTracking();
    };
  });

  createUserLocationElement = () => {
    const el = document.createElement('div');
    el.className = 'user-location-marker';
    el.innerHTML = `
      <div class="user-location-dot">
        <div class="user-location-pulse"></div>
      </div>
    `;
    this.userLocationElement = el;
  };

  startLocationTracking = () => {
    // Only track location if user has enabled it
    if (!this.preferences.enableLocationServices) {
      return;
    }

    if (!('geolocation' in navigator)) {
      return;
    }

    // Watch position with high accuracy
    this.locationWatchId = navigator.geolocation.watchPosition(
      (position) => {
        console.log('Received location update:', position);
        const { latitude, longitude } = position.coords;

        this.userLocation = { lat: latitude, lng: longitude };
      },
      (error) => {
        console.error('Error watching location:', error);
        this.userLocation = null;
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 5000,
      }
    );
  };

  stopLocationTracking = () => {
    if (this.locationWatchId !== null) {
      navigator.geolocation.clearWatch(this.locationWatchId);
      this.locationWatchId = null;
    }
    this.userLocation = null;
  };

  storeMapReference = (context: { map: Map } | null) => {
    if (context && !this.map) {
      this.map = context.map;
    }
  }

  getMap = () => {
    return this.map;
  }

  close = () => {
    this.args.onClose();
  }

  <template>
    {{#in-element this.portals.takeover}}
      {{! template-lint-disable no-inline-styles }}
      <div class="fullscreen-map-overlay" {{this.setupEscapeKey}}>
        <div class="fullscreen-map-container">
          {{! Close button - upper right }}
          <button
            type="button"
            class="fullscreen-map-close"
            {{on "click" this.close}}
            aria-label="Close fullscreen map"
          >
            <FaIcon @icon={{faXmark}} />
          </button>

          <MapLibreBoundary>
            <MapLibreMap
              @lat={{@lat}}
              @lng={{@lng}}
              @zoom={{this.currentZoom}}
              @style={{@style}}
              as |context|
            >
              {{#if context}}
                {{this.storeMapReference context}}
                <MapLibreMarker
                  @context={{context}}
                  @lat={{@lat}}
                  @lng={{@lng}}
                  @title={{@locationName}}
                />

                {{! User location marker }}
                {{#if this.userLocation}}
                  {{#if this.userLocationElement}}
                    <MapLibreMarker
                      @context={{context}}
                      @lat={{this.userLocation.lat}}
                      @lng={{this.userLocation.lng}}
                      @title="Your Location"
                      @element={{this.userLocationElement}}
                    />
                  {{/if}}
                {{/if}}
              {{/if}}
            </MapLibreMap>
          </MapLibreBoundary>
        </div>
      </div>
    {{/in-element}}
  </template>
}
