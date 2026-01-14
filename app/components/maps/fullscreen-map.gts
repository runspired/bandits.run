import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';
import { tracked } from '@glimmer/tracking';
import LeafletMap from '#maps/leaflet-map.gts';
import LeafletMarker from '#maps/leaflet-marker.gts';
import MapDownloadButton from '#maps/map-download-button.gts';
import PolygonSelector from '#maps/polygon-selector.gts';
import FaIcon from '#ui/fa-icon.gts';
import { faXmark } from '@fortawesome/free-solid-svg-icons';
import type * as L from 'leaflet';
import type { PolygonPoint } from '#app/utils/tile-preloader.ts';
import './fullscreen-map.css';
import { service } from '@ember/service';
import type PortalsService from '#app/services/ux/portals.ts';
import { getDevicePreferences } from '#app/core/preferences.ts';
import { getLeaflet } from '#maps/leaflet-boundary.gts';

interface FullscreenMapSignature {
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
     * Tile URL for the map
     */
    tileUrl: string;

    /**
     * Callback when user closes the fullscreen map
     */
    onClose: () => void;
  };
}

export default class FullscreenMap extends Component<FullscreenMapSignature> {
  @service('ux/portals') declare portals: PortalsService;

  preferences = getDevicePreferences();

  map: L.Map | null = null;
  currentZoom: number = this.args.zoom ?? 14;
  locationWatchId: number | null = null;

  @tracked
  showPolygonSelector: boolean = false;

  @tracked
  polygon: PolygonPoint[] | null = null;

  @tracked
  userLocation: { lat: number; lng: number } | null = null;

  setupEscapeKey = modifier((_element: HTMLElement) => {
    const handleEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        // If polygon selector is showing, close it first
        if (this.showPolygonSelector) {
          this.handlePolygonCancel();
        } else {
          this.args.onClose();
        }
      }
    };

    document.addEventListener('keydown', handleEscape);

    // Start watching location if enabled
    this.startLocationTracking();

    return () => {
      document.removeEventListener('keydown', handleEscape);
      this.stopLocationTracking();
    };
  });

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

  isLocationInBounds = (lat: number, lng: number): boolean => {
    // Calculate approximate bounds (roughly 10km radius from center)
    // 1 degree latitude ≈ 111km, 1 degree longitude varies by latitude
    const latDelta = 0.1; // ~11km
    const lngDelta = 0.1 / Math.cos((this.args.lat * Math.PI) / 180); // Adjust for latitude

    const inBounds =
      Math.abs(lat - this.args.lat) <= latDelta &&
      Math.abs(lng - this.args.lng) <= lngDelta;

    return inBounds;
  };

  storeMapReference = (context: { map: L.Map; context: object } | null) => {
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

  startPolygonSelection = () => {
    this.showPolygonSelector = true;
  };

  handlePolygonComplete = (points: PolygonPoint[]) => {
    this.polygon = points;
    this.showPolygonSelector = false;
  };

  handlePolygonCancel = () => {
    this.showPolygonSelector = false;
  };

  clearPolygon = () => {
    this.polygon = null;
  };

  get userLocationIcon(): L.DivIcon {
    const L = getLeaflet();
    return L.divIcon({
      className: 'user-location-marker',
      html: `
        <div class="user-location-dot">
          <div class="user-location-pulse"></div>
        </div>
      `,
      iconSize: [20, 20],
      iconAnchor: [10, 10],
    });
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

          {{! Download button - bottom right }}
          <div class="fullscreen-map-download">
            <MapDownloadButton
              @locationId={{@locationId}}
              @locationName={{@locationName}}
              @lat={{@lat}}
              @lng={{@lng}}
              @getMap={{this.getMap}}
              @polygon={{this.polygon}}
              @onStartPolygonSelection={{this.startPolygonSelection}}
              @onClearPolygon={{this.clearPolygon}}
            />
          </div>

          {{! Polygon selector overlay - rendered conditionally }}
          {{#if this.showPolygonSelector}}
            {{#if this.map}}
              <PolygonSelector
                @map={{this.map}}
                @onPolygonComplete={{this.handlePolygonComplete}}
                @onCancel={{this.handlePolygonCancel}}
              />
            {{/if}}
          {{/if}}

          <LeafletMap
            @lat={{@lat}}
            @lng={{@lng}}
            @zoom={{this.currentZoom}}
            @tileUrl={{@tileUrl}}
            as |context|
          >
            {{#if context}}
              {{this.storeMapReference context}}
              <LeafletMarker
                @context={{context}}
                @lat={{@lat}}
                @lng={{@lng}}
                @title={{@locationName}}
              />

              {{! User location marker }}
              {{#if this.userLocation}}
                <LeafletMarker
                  @context={{context}}
                  @lat={{this.userLocation.lat}}
                  @lng={{this.userLocation.lng}}
                  @title="Your Location"
                  @icon={{this.userLocationIcon}}
                  @zIndexOffset={{1000}}
                />
              {{/if}}
            {{/if}}
          </LeafletMap>
        </div>
      </div>
    {{/in-element}}
  </template>
}
