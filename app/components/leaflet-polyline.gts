import Component from '@glimmer/component';
import { modifier } from 'ember-modifier';
import * as L from 'leaflet';
import { MapContext } from './leaflet-map.gts';

interface LeafletPolylineSignature {
  Element: HTMLDivElement;
  Args: {
    context: object;
    points: Array<[number, number]>;
    color?: string;
    weight?: number;
    opacity?: number;
    smoothFactor?: number;
    onClick?: (event: L.LeafletMouseEvent) => void;
  };
  Blocks: {
    default?: [];
  };
}

export default class LeafletPolylineComponent extends Component<LeafletPolylineSignature> {
  setupPolyline = modifier((_element: HTMLElement) => {
    const map = MapContext.get(this.args.context);
    if (!map) {
      console.error('LeafletPolyline: No map found in context');
      return;
    }

    const {
      points,
      color = '#3388ff',
      weight = 3,
      opacity = 1.0,
      smoothFactor = 1.0,
      onClick,
    } = this.args;

    const polyline = L.polyline(points, {
      color,
      weight,
      opacity,
      smoothFactor,
    }).addTo(map);

    if (onClick) {
      polyline.on('click', onClick);
    }

    return () => {
      polyline.remove();
    };
  });

  <template>
    {{! template-lint-disable no-inline-styles }}
    <div style="display: none;" {{this.setupPolyline}}>
      {{yield}}
    </div>
  </template>
}
