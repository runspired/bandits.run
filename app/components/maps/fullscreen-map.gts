import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';
import LeafletMap from '#maps/leaflet-map.gts';
import LeafletMarker from '#maps/leaflet-marker.gts';
import MapDownloadButton from '#maps/map-download-button.gts';
import FaIcon from '#ui/fa-icon.gts';
import { faXmark } from '@fortawesome/free-solid-svg-icons';
import type * as L from 'leaflet';
import './fullscreen-map.css';
import { service } from '@ember/service';
import type PortalsService from '#app/services/ux/portals.ts';

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

  map: L.Map | null = null;
  currentZoom: number = this.args.zoom ?? 14;

  setupEscapeKey = modifier((_element: HTMLElement) => {
    const handleEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        this.args.onClose();
      }
    };

    document.addEventListener('keydown', handleEscape);

    return () => {
      document.removeEventListener('keydown', handleEscape);
    };
  });

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
            />
          </div>

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
            {{/if}}
          </LeafletMap>
        </div>
      </div>
    {{/in-element}}
  </template>
}
