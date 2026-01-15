import Component from '@glimmer/component';
import { modifier } from 'ember-modifier';
import type { Map, Marker } from 'maplibre-gl';
import { getMapLibre } from './maplibre-boundary.gts';

interface MapLibreMarkerSignature {
  Args: {
    context: { map: Map };
    lat: number;
    lng: number;
    title?: string;
    color?: string;
    draggable?: boolean;
    element?: HTMLElement;
    onDragEnd?: (lng: number, lat: number) => void;
  };
}

export default class MapLibreMarkerComponent extends Component<MapLibreMarkerSignature> {
  setupMarker = modifier((_element: HTMLElement) => {
    const {
      context,
      lat,
      lng,
      title,
      color = '#3FB1CE',
      draggable = false,
      element,
      onDragEnd,
    } = this.args;

    const maplibregl = getMapLibre();
    const map = context.map;

    let marker: Marker;

    if (element) {
      // Use custom HTML element for marker
      marker = new maplibregl.Marker({ element, draggable });
    } else {
      // Use default marker with color
      marker = new maplibregl.Marker({ color, draggable });
    }

    marker.setLngLat([lng, lat]).addTo(map);

    // Set popup if title is provided
    if (title) {
      const popup = new maplibregl.Popup({ offset: 25 }).setText(title);
      marker.setPopup(popup);
    }

    // Handle drag events
    if (draggable && onDragEnd) {
      marker.on('dragend', () => {
        const lngLat = marker.getLngLat();
        onDragEnd(lngLat.lng, lngLat.lat);
      });
    }

    return () => {
      marker.remove();
    };
  });

  <template>
    <div {{this.setupMarker}}></div>
  </template>
}
