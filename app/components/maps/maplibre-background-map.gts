import Component from '@glimmer/component';
import MapLibreBoundary from './maplibre-boundary.gts';
import MapLibreMap from './maplibre-map.gts';
import MapLibreMarker from './maplibre-marker.gts';
import './background-map.css';

interface MapLibreBackgroundMapSignature {
  Args: {
    lat: number;
    lng: number;
    zoom?: number;
    minZoom?: number;
    maxZoom?: number;
    style?: string;
    markerTitle?: string;
  };
}

export default class MapLibreBackgroundMap extends Component<MapLibreBackgroundMapSignature> {
  get zoom() {
    return this.args.zoom ?? 10;
  }

  get minZoom() {
    return this.args.minZoom ?? 6;
  }

  get maxZoom() {
    return this.args.maxZoom ?? 14;
  }

  get style() {
    return this.args.style ?? '/map-styles/simple-background.json';
  }

  <template>
    <div class="background-map" ...attributes>
      <MapLibreBoundary>
        <MapLibreMap
          @lat={{@lat}}
          @lng={{@lng}}
          @zoom={{this.zoom}}
          @minZoom={{this.minZoom}}
          @maxZoom={{this.maxZoom}}
          @scrollZoom={{false}}
          @dragPan={{false}}
          @touchZoomRotate={{false}}
          @doubleClickZoom={{false}}
          @style={{this.style}}
          as |map|
        >
          <MapLibreMarker
            @context={{map}}
            @lat={{@lat}}
            @lng={{@lng}}
            @title={{@markerTitle}}
          />
        </MapLibreMap>
      </MapLibreBoundary>
    </div>
  </template>
}
