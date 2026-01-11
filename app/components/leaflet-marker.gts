import Component from '@glimmer/component';
import { modifier } from 'ember-modifier';
import type * as L from 'leaflet';
import { MapContext } from './leaflet-map.gts';
import { getLeaflet } from './leaflet-boundary.gts';

function fixIconIfNecessary() {
  const L = getLeaflet();
  // Fix for default marker icons in bundled environments
  // @ts-expect-error - Leaflet icon paths
  delete L.Icon.Default.prototype._getIconUrl;
  L.Icon.Default.mergeOptions({
    iconRetinaUrl:
    'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
    iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
    shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
  });
}

interface LeafletMarkerSignature {
  Element: HTMLDivElement;
  Args: {
    context: { map: L.Map; context: object };
    lat: number;
    lng: number;
    title?: string;
    draggable?: boolean;
    icon?: L.Icon | L.DivIcon;
    zIndexOffset?: number;
    opacity?: number;
    onClick?: (event: L.LeafletMouseEvent) => void;
    onDragEnd?: (event: L.DragEndEvent) => void;
  };
  Blocks: {
    default?: [];
  };
}

export default class LeafletMarkerComponent extends Component<LeafletMarkerSignature> {
  setupMarker = modifier(
    (_element: HTMLElement, [context]: [{ map: L.Map; context: object }]) => {
      const map = MapContext.get(context.context);
      if (!map) {
        console.error('LeafletMarker: No map found in context');
        return;
      }

      const {
        lat,
        lng,
        title,
        draggable = false,
        icon,
        zIndexOffset = 0,
        opacity = 1.0,
        onClick,
        onDragEnd,
      } = this.args;

      const markerOptions: L.MarkerOptions = {
        draggable,
        title,
        opacity,
        zIndexOffset,
      };

      if (icon) {
        markerOptions.icon = icon;
      }

      const L = getLeaflet();
      const marker = L.marker([lat, lng], markerOptions).addTo(map);

      // Event handlers
      if (onClick) {
        marker.on('click', onClick);
      }
      if (onDragEnd) {
        marker.on('dragend', onDragEnd);
      }

      return () => {
        marker.remove();
      };
    }
  );

  <template>
    {{! template-lint-disable no-inline-styles }}
    <div style="display: none;" {{this.setupMarker @context}}>
      {{yield}}
    </div>
  </template>
}
