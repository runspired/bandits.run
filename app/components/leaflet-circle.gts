import Component from '@glimmer/component';
import { modifier } from 'ember-modifier';
import * as L from 'leaflet';
import { MapContext } from './leaflet-map.gts';

interface LeafletCircleSignature {
  Element: HTMLDivElement;
  Args: {
    context: object;
    lat: number;
    lng: number;
    radius: number;
    color?: string;
    fillColor?: string;
    fillOpacity?: number;
    weight?: number;
    opacity?: number;
    onClick?: (event: L.LeafletMouseEvent) => void;
  };
  Blocks: {
    default?: [];
  };
}

export default class LeafletCircleComponent extends Component<LeafletCircleSignature> {
  setupCircle = modifier((_element: HTMLElement) => {
    const map = MapContext.get(this.args.context);
    if (!map) {
      console.error('LeafletCircle: No map found in context');
      return;
    }

    const {
      lat,
      lng,
      radius,
      color = '#3388ff',
      fillColor = '#3388ff',
      fillOpacity = 0.2,
      weight = 3,
      opacity = 1.0,
      onClick,
    } = this.args;

    const circle = L.circle([lat, lng], {
      radius,
      color,
      fillColor,
      fillOpacity,
      weight,
      opacity,
    }).addTo(map);

    if (onClick) {
      circle.on('click', onClick);
    }

    return () => {
      circle.remove();
    };
  });

  <template>
    {{! template-lint-disable no-inline-styles }}
    <div style="display: none;" {{this.setupCircle}}>
      {{yield}}
    </div>
  </template>
}
