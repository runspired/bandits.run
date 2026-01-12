import ThemedPage from '#app/components/themed-page.gts';
import Component from '@glimmer/component';
import type { Location } from '#app/data/location.ts';
import { withReactiveResponse } from '@warp-drive/core/request';
import { Request } from '@warp-drive/ember';
import { pageTitle } from 'ember-page-title';
import LeafletMap from '#components/leaflet-map.gts';
import LeafletMarker from '#components/leaflet-marker.gts';
import FaIcon from '#app/components/fa-icon.gts';
import {
  faLocationDot,
  faMapLocationDot,
} from '@fortawesome/free-solid-svg-icons';
import { cached, tracked } from '@glimmer/tracking';
import { colorSchemeManager } from '#app/templates/application.gts';
import './location.css';
import LeafletBoundary from '#app/components/leaflet-boundary.gts';
import { assert } from '@ember/debug';
import { and } from '#app/utils/helpers.ts';

function getLocation(locationId: string) {
  return withReactiveResponse<Location>({
    url: `/api/location/${locationId}.json`,
    method: 'GET',
  } as const);
}

const TOKEN = '';

export default class LocationDisplay extends Component<{
  Args: {
    model: {
      location: string;
    };
  };
}> {
  @tracked showTerrain: boolean = false;
  @tracked showSatellite: boolean = false;

  @cached
  get tileUrl() {
    // see https://github.com/leaflet-extras/leaflet-providers/blob/master/leaflet-providers.js
    // for more providers and https://leaflet-extras.github.io/leaflet-providers/preview/
    // for a preview
    //
    // https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.{ext}
    // https://tiles.stadiamaps.com/tiles/outdoors/{z}/{x}/{y}{r}.{ext}
    // https://tiles.stadiamaps.com/tiles/alidade_satellite/{z}/{x}/{y}{r}.{ext}
    // https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.{ext}
    //
    if (this.showTerrain) {
      return `https://tile.jawg.io/jawg-terrain/{z}/{x}/{y}{r}.png?access-token=${TOKEN}`;
      // "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png";
    }
    if (this.showSatellite) {
      return 'https://tiles.stadiamaps.com/tiles/alidade_satellite/{z}/{x}/{y}{r}.png';
    }
    return colorSchemeManager.isDarkMode
      ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png'
      : 'https://tiles.stadiamaps.com/tiles/outdoors/{z}/{x}/{y}{r}.png';
  }

  <template>
    {{pageTitle "Location | Bandits"}}
    <ThemedPage>
      <Request @query={{getLocation @model.location}}>
        <:loading>
          <h2>Loading location...</h2>
        </:loading>
        <:error as |error|>
          <div class="error-box">
            <h2>Whoops!</h2>
            <p>We weren't able to load this location!</p>
            <p class="error-message">{{error.message}}</p>
          </div>
        </:error>
        <:content as |response|>
          {{#let response.data as |location|}}
            {{pageTitle location.name " | Bandits"}}
            <div class="location-page">
              <div class="location-header">
                <h2>{{location.name}}</h2>
                {{#if location.region}}
                  <p class="location-region">{{location.region}}</p>
                {{/if}}
              </div>

              {{#if location.descriptionHtml}}
                <div class="location-description">
                  {{! Safe because we control the markdown compilation }}
                  {{! template-lint-disable no-triple-curlies }}
                  {{{location.descriptionHtml}}}
                </div>
              {{/if}}

              <div class="location-details">
                {{#if location.address}}
                  <div class="location-detail">
                    <FaIcon @icon={{faLocationDot}} />
                    <div>
                      <strong>Address:</strong>
                      <address>
                        {{#if location.address.street}}
                          {{location.address.street}}<br />
                        {{/if}}
                        {{#if location.address.city}}
                          {{location.address.city}},
                          {{location.address.state}}
                          {{location.address.zip}}
                        {{/if}}
                      </address>
                    </div>
                  </div>
                {{/if}}

                {{#if location.googleMapsLink}}
                  <div class="location-detail">
                    <FaIcon @icon={{faMapLocationDot}} />
                    <a
                      href="{{location.googleMapsLink}}"
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      Open in Google Maps
                    </a>
                  </div>
                {{/if}}

                {{#if (and location.latitude location.longitude)}}
                  <div class="location-detail">
                    <strong>Coordinates:</strong>
                    {{location.latitude}},
                    {{location.longitude}}
                  </div>
                {{/if}}
              </div>

              {{#if (and location.latitude location.longitude)}}
                <div class="location-map">
                  <h3>Map</h3>
                  <div class="map-container">
                    <LeafletBoundary>
                      <LeafletMap
                        @lat={{excludeNull location.latitude}}
                        @lng={{excludeNull location.longitude}}
                        @zoom={{12}}
                        @tileUrl={{this.tileUrl}}
                        as |map|
                      >
                        <LeafletMarker
                          @context={{map}}
                          @lat={{excludeNull location.latitude}}
                          @lng={{excludeNull location.longitude}}
                          @title={{location.name}}
                        />
                      </LeafletMap>
                    </LeafletBoundary>
                  </div>
                </div>
              {{/if}}
            </div>
          {{/let}}
        </:content>
      </Request>
    </ThemedPage>
  </template>
}

function excludeNull<T>(value: T | null): T {
  assert('Value is not null', value !== null);
  return value;
}
