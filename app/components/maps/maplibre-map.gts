import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { modifier } from 'ember-modifier';
import type { Map, MapOptions, StyleSpecification } from 'maplibre-gl';
import { getMapLibre } from './maplibre-boundary.gts';

interface MapLibreMapSignature {
  Element: HTMLDivElement;
  Args: {
    lat: number;
    lng: number;
    zoom?: number;
    minZoom?: number;
    maxZoom?: number;
    scrollZoom?: boolean;
    dragPan?: boolean;
    touchZoomRotate?: boolean;
    doubleClickZoom?: boolean;
    style?: string | StyleSpecification;
    onMoveEnd?: () => void;
    onZoomEnd?: () => void;
    onClick?: (lng: number, lat: number) => void;
  };
  Blocks: {
    default: [{ map: Map; }];
  };
}

const MAP_RESIZE_DEBOUNCE_MS = 160;

interface Token {
  cancelled: boolean;
}

function deferredFrame(cb: () => void): Token {
  const token: Token = { cancelled: false };
  setTimeout(() => {
    if (!token.cancelled) {
      requestAnimationFrame(() => {
        if (token.cancelled) {
          return;
        }

        cb();
      });
    }
  }, MAP_RESIZE_DEBOUNCE_MS);

  return token;
}
export default class MapLibreMapComponent extends Component<MapLibreMapSignature> {
  @tracked map: Map | null = null;

  setupMap = modifier((element: HTMLElement) => {
    const {
      lat,
      lng,
      zoom = 13,
      minZoom = 0,
      maxZoom = 22,
      scrollZoom = true,
      dragPan = true,
      touchZoomRotate = true,
      doubleClickZoom = true,
      style = '/map-styles/openstreetmap-us-vector.json',
      onMoveEnd,
      onZoomEnd,
      onClick,
    } = this.args;

    const maplibregl = getMapLibre();

    // Initialize map
    const mapOptions: MapOptions = {
      container: element,
      center: [lng, lat],
      zoom,
      minZoom,
      maxZoom,
      scrollZoom,
      dragPan,
      touchZoomRotate,
      doubleClickZoom,
      style,
      trackResize: false, // Disable automatic resize
    };

    const map = new maplibregl.Map(mapOptions);

    // Debounced resize handler
    let token: Token | null = null;
    const handleResize = () => {
      if (token !== null) {
        token.cancelled = true;
      }
      token = deferredFrame(() => {
        map.resize();
        token = null;
      });
    };

    // Set up ResizeObserver for container size changes
    const resizeObserver = new ResizeObserver(() => {
      handleResize();
    });
    resizeObserver.observe(element);

    // Wait for map to load before storing reference
    map.on('load', () => {
      this.map = map;

      // Event handlers
      if (onMoveEnd) {
        map.on('moveend', onMoveEnd);
      }
      if (onZoomEnd) {
        map.on('zoomend', onZoomEnd);
      }
      if (onClick) {
        map.on('click', (e) => {
          onClick(e.lngLat.lng, e.lngLat.lat);
        });
      }
    });

    return () => {
      // Cleanup
      if (token !== null) {
        token.cancelled = true;
      }
      resizeObserver.disconnect();
      map.remove();
      this.map = null;
    };
  });

  @cached
  get context() {
    if (!this.map) {
      return null;
    }
    return {
      map: this.map,
    };
  }

  <template>
    {{! template-lint-disable no-inline-styles }}
    <div
      class="maplibre-map-container"
      style="width: 100%; height: 100%;"
      {{this.setupMap}}
    >
      {{#if this.context}}
        {{yield this.context}}
      {{/if}}
    </div>
  </template>
}
