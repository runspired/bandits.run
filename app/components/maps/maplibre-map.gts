import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { modifier } from 'ember-modifier';
import type { Map, MapOptions, StyleSpecification } from 'maplibre-gl';
import { getMapLibre } from './maplibre-boundary.gts';
import { assert } from '@ember/debug';
import { excludeNull } from '#app/utils/comparison.ts';

interface MapSignature {
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
  lat: number;
  lng: number;
  zoom: number;
}

interface MapLibreMapSignature {
  Element: HTMLDivElement;
  Args: MapSignature;
  Blocks: {
    default: [Map];
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
  @tracked initialized: boolean = false;
  map: Map | null = null;
  declare cleanup: (() => void);

  @cached
  get allArgs(): MapSignature {
    return {
      lat: this.args.lat,
      lng: this.args.lng,
      zoom: this.args.zoom,
      minZoom: this.args.minZoom,
      maxZoom: this.args.maxZoom,
      scrollZoom: this.args.scrollZoom,
      dragPan: this.args.dragPan,
      touchZoomRotate: this.args.touchZoomRotate,
      doubleClickZoom: this.args.doubleClickZoom,
      style: this.args.style,
      onMoveEnd: this.args.onMoveEnd,
      onZoomEnd: this.args.onZoomEnd,
      onClick: this.args.onClick,
    };
  }

  #createMap(element: HTMLElement, options: MapSignature) {
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
      onClick
    } = options;
    assert('Latitude is required for MapLibreMap', typeof lat === 'number');
    assert('Longitude is required for MapLibreMap', typeof lng === 'number');
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
      // Event handlers
      if (onMoveEnd) {
        map.on('move', onMoveEnd);
      }
      if (onZoomEnd) {
        map.on('zoom', onZoomEnd);
      }
      if (onClick) {
        map.on('click', (e) => {
          onClick(e.lngLat.lng, e.lngLat.lat);
        });
      }

      void Promise.resolve()
        .then(() => {
          // Yield map to block
          this.initialized = true;
        });
    });

    const cleanup = () => {
      // Cleanup
      if (token !== null) {
        token.cancelled = true;
      }
      resizeObserver.disconnect();
      map.remove();
      this.map = null;
    };

    this.cleanup = cleanup;
    this.map = map;
  }

  #updateMap(map: Map, options: MapSignature) {
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
    } = options;
    assert('Latitude is required for MapLibreMap', typeof lat === 'number');
    assert('Longitude is required for MapLibreMap', typeof lng === 'number');

    // Update center and zoom
    const currentCenter = map.getCenter();
    const currentZoom = map.getZoom();
    if (currentCenter.lng !== lng || currentCenter.lat !== lat || currentZoom !== zoom) {
      map.jumpTo({ center: [lng, lat], zoom });
    }

    // Update zoom constraints
    if (map.getMinZoom() !== minZoom) {
      map.setMinZoom(minZoom);
    }
    if (map.getMaxZoom() !== maxZoom) {
      map.setMaxZoom(maxZoom);
    }

    // Update interaction settings
    if (scrollZoom) {
      map.scrollZoom.enable();
    } else {
      map.scrollZoom.disable();
    }

    if (dragPan) {
      map.dragPan.enable();
    } else {
      map.dragPan.disable();
    }

    if (touchZoomRotate) {
      map.touchZoomRotate.enable();
    } else {
      map.touchZoomRotate.disable();
    }

    if (doubleClickZoom) {
      map.doubleClickZoom.enable();
    } else {
      map.doubleClickZoom.disable();
    }
  }

  setupMap = modifier((element: HTMLElement, positional: [MapSignature]) => {
    // If map already exists, update it instead of recreating
    const { map } = this;
    if (!map) {
      this.#createMap(element, positional[0]);
    } else {
      this.#updateMap(map, positional[0]);
    }
  });

  willDestroy(): void {
    super.willDestroy();
    if (this.cleanup) {
      this.cleanup();
    }
  }

  <template>
    {{! template-lint-disable no-inline-styles }}
    <div
      class="maplibre-map-container"
      style="width: 100%; height: 100%;"
      {{this.setupMap this.allArgs}}
    >
      {{#if this.initialized}}
        {{yield (excludeNull this.map)}}
      {{/if}}
    </div>
  </template>
}
