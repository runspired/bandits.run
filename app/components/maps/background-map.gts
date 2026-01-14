import Component from '@glimmer/component';
import LeafletBoundary from './leaflet-boundary.gts';
import LeafletMap from './leaflet-map.gts';
import LeafletMarker from './leaflet-marker.gts';
import './background-map.css';

interface BackgroundMapSignature {
  Args: {
    lat: number;
    lng: number;
    zoom?: number;
    minZoom?: number;
    maxZoom?: number;
    tileUrl: string;
    markerTitle?: string;
  };
}

export default class BackgroundMap extends Component<BackgroundMapSignature> {
  get zoom() {
    return this.args.zoom ?? 12;
  }

  get minZoom() {
    return this.args.minZoom ?? 8;
  }

  get maxZoom() {
    return this.args.maxZoom ?? 18;
  }

  <template>
    <div class="background-map" ...attributes>
      <LeafletBoundary>
        <LeafletMap
          @lat={{@lat}}
          @lng={{@lng}}
          @zoom={{this.zoom}}
          @minZoom={{this.minZoom}}
          @maxZoom={{this.maxZoom}}
          @scrollWheelZoom={{false}}
          @zoomControl={{false}}
          @tileUrl={{@tileUrl}}
          as |map|
        >
          <LeafletMarker
            @context={{map}}
            @lat={{@lat}}
            @lng={{@lng}}
            @title={{@markerTitle}}
          />
        </LeafletMap>
      </LeafletBoundary>
    </div>
  </template>
}
