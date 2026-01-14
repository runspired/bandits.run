import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { modifier } from 'ember-modifier';
import type * as L from 'leaflet';
import { getLeaflet } from './leaflet-boundary.gts';

interface LeafletMapSignature {
  Element: HTMLDivElement;
  Args: {
    lat: number;
    lng: number;
    zoom?: number;
    minZoom?: number;
    maxZoom?: number;
    scrollWheelZoom?: boolean;
    dragging?: boolean;
    touchZoom?: boolean;
    doubleClickZoom?: boolean;
    zoomControl?: boolean;
    tileUrl?: string;
    tileAttribution?: string;
    onMoveEnd?: (event: L.LeafletEvent) => void;
    onZoomEnd?: (event: L.LeafletEvent) => void;
    onClick?: (event: L.LeafletMouseEvent) => void;
  };
  Blocks: {
    default: [{ map: L.Map; context: object }];
  };
}

export const MapContext = new Map<object, L.Map>();

export default class LeafletMapComponent extends Component<LeafletMapSignature> {
  @tracked map: L.Map | null = null;
  contextKey = {};

  setupMap = modifier((element: HTMLElement) => {
    const {
      lat,
      lng,
      zoom = 13,
      minZoom = 1,
      maxZoom = 18,
      scrollWheelZoom = true,
      dragging = true,
      touchZoom = true,
      doubleClickZoom = true,
      zoomControl = true,
      tileUrl = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      tileAttribution = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      onMoveEnd,
      onZoomEnd,
      onClick,
    } = this.args;
    const L = getLeaflet();

    // Initialize map
    const map = L.map(element, {
      center: [lat, lng],
      zoom,
      minZoom,
      maxZoom,
      scrollWheelZoom,
      dragging,
      touchZoom,
      doubleClickZoom,
      zoomControl,
    });

    // Add tile layer using the passed tileUrl
    L.tileLayer(tileUrl, {
      attribution: tileAttribution,
      maxZoom: 19,
    }).addTo(map);

    // Store map in context
    this.map = map;
    MapContext.set(this.contextKey, map);

    // Event handlers
    if (onMoveEnd) {
      map.on('moveend', onMoveEnd);
    }
    if (onZoomEnd) {
      map.on('zoomend', onZoomEnd);
    }
    if (onClick) {
      map.on('click', onClick);
    }

    return () => {
      // Cleanup
      map.remove();
      MapContext.delete(this.contextKey);
      this.map = null;
    };
  });

  @action
  updateCenter() {
    if (this.map) {
      this.map.setView([this.args.lat, this.args.lng], this.args.zoom);
    }
  }

  @cached
  get context() {
    if (!this.map) {
      return null;
    }
    return {
      map: this.map,
      context: this.contextKey,
    };
  }

  <template>
    {{! template-lint-disable no-inline-styles }}
    <div
      class="leaflet-map-container"
      style="width: 100%; height: 100%;"
      {{this.setupMap}}
    >
      {{#if this.context}}
        {{yield this.context}}
      {{/if}}
    </div>
  </template>
}
