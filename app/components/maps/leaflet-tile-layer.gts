import Component from '@glimmer/component';
import { modifier } from 'ember-modifier';
import type * as L from 'leaflet';
import { getLeaflet } from './leaflet-boundary.gts';

interface LeafletTileLayerSignature {
  Element: HTMLDivElement;
  Args: {
    context: { map: L.Map; };
    url: string;
    attribution?: string;
    maxZoom?: number;
    minZoom?: number;
    subdomains?: string | string[];
    opacity?: number;
  };
}

export default class LeafletTileLayerComponent extends Component<LeafletTileLayerSignature> {
  setupTileLayer = modifier((_element: HTMLElement) => {
    const map = this.args.context.map;
    if (!map) {
      console.error('LeafletTileLayer: No map found in context');
      return;
    }

    const {
      url,
      attribution = '',
      maxZoom = 19,
      minZoom = 0,
      subdomains = 'abc',
      opacity = 1.0,
    } = this.args;

    const L = getLeaflet();
    const tileLayer = L.tileLayer(url, {
      attribution,
      maxZoom,
      minZoom,
      subdomains,
      opacity,
    }).addTo(map);

    return () => {
      tileLayer.remove();
    };
  });

  <template>
    {{! template-lint-disable no-inline-styles }}
    <div style="display: none;" {{this.setupTileLayer}}></div>
  </template>
}
