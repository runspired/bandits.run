import { field, input, SessionResource } from "../../../core/utils/storage-resource";

/**
 * QuerParam + sessionStorage rules
 *
 * - the url value comes first
 * - if url param is empty, transition to sessionStorage value
 * - if sessionStorage value is empty, use default value
 * - allow some params to hide if other params aren't set (like lat/lng/zoom when active is false)
 */

@SessionResource((map: MapState) => `map-state:${map.id}`)
class MapState {
  id: string;

  constructor(id: string) {
    this.id = id;
  }

  get activeParam(): string {
    return this.active ? '1' : '';
  }
  set activeParam(value: string) {
    this.active = value === '1';
  }

  get zoomParam(): string {
    return this.active ? (this.zoom !== this.defaultZoom ? this.zoom.toString() : '') : '';
  }
  set zoomParam(value: string) {
    if (!value) {
      return;
    }
    const zoom = Number(value);
    if (!isNaN(zoom)) {
      this.zoom = zoom;
    }
  }

  get latParam(): string {
    return this.active ? (this.lat !== this.defaultLat ? this.lat.toFixed(5) : '') : '';
  }
  set latParam(value: string) {
    if (!value) {
      return;
    }
    const lat = Number(value);
    if (!isNaN(lat)) {
      this.lat = lat;
    }
  }

  get lngParam(): string {
    return this.active ? (this.lng !== this.defaultLng ? this.lng.toFixed(5) : '') : '';
  }
  set lngParam(value: string) {
    if (!value) {
      return;
    }
    const lng = Number(value);
    if (!isNaN(lng)) {
      this.lng = lng;
    }
  }

  @input('number')
  @field
  zoom: number = 114;

  @field
  defaultZoom: number = 12;

  @input('number')
  @field
  lat: number = 0;

  @field
  defaultLat: number = 100;

  @input('number')
  @field
  lng: number = 50;

  @field
  defaultLng: number = 500;

  @input('boolean')
  @field
  active: boolean = false;

  initialize(options: { lat: number; lng: number; zoom: number }) {
    const { defaultLat, defaultLng, defaultZoom } = this;
    if (defaultLat !== options.lat || defaultLng !== options.lng || defaultZoom !== options.zoom) {
      // update only if different from existing defaults

      this.lat = options.lat;
      this.lng = options.lng;
      this.zoom = options.zoom;
      this.defaultLat = options.lat;
      this.defaultLng = options.lng;
      this.defaultZoom = options.zoom;
      return;
    }
  }
}

export { MapState };
