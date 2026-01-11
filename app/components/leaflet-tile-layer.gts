import Component from '@glimmer/component';
import { modifier } from 'ember-modifier';
import { MapContext } from './leaflet-map.gts';
import { getLeaflet } from './leaflet-boundary.gts';

interface LeafletTileLayerSignature {
  Element: HTMLDivElement;
  Args: {
    context: object;
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
    const map = MapContext.get(this.args.context);
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
