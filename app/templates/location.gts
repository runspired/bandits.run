import ThemedPage from '#layout/themed-page.gts';
import Component from '@glimmer/component';
import { Request } from '@warp-drive/ember';
import { pageTitle } from 'ember-page-title';
import BackgroundMap from '#maps/background-map.gts';
import FaIcon from '#ui/fa-icon.gts';
import {
  faLocationDot,
  faMapLocationDot,
  faExpand,
} from '@fortawesome/free-solid-svg-icons';
import { cached, tracked } from '@glimmer/tracking';
import './location.css';
import { assert } from '@ember/debug';
import { getLocation } from '#api/GET';
import { and } from '#app/utils/comparison.ts';
import { getTheme } from '#app/core/site-theme.ts';
import FullscreenMap from '#maps/fullscreen-map.gts';
import { on } from '@ember/modifier';

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
  @tracked showFullscreenMap: boolean = false;

  openFullscreenMap = () => {
    this.showFullscreenMap = true;
  };

  closeFullscreenMap = () => {
    this.showFullscreenMap = false;
  };

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
    return getTheme().isDarkMode
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
              {{#if (and location.latitude location.longitude)}}
                <BackgroundMap
                  @lat={{excludeNull location.latitude}}
                  @lng={{excludeNull location.longitude}}
                  @zoom={{12}}
                  @minZoom={{8}}
                  @maxZoom={{18}}
                  @tileUrl={{this.tileUrl}}
                  @markerTitle={{location.name}}
                />
              {{/if}}

              <div class="location-content">
                <div class="location-header">
                  <div class="location-header-main">
                    <div class="location-header-content">
                      <h2>{{location.name}}</h2>
                      {{#if location.region}}
                        <p class="location-region">{{location.region}}</p>
                      {{/if}}
                    </div>
                  </div>

                  <div class="location-header-address">
                    {{#if location.address}}
                      <div class="location-info">
                        <FaIcon @icon={{faLocationDot}} />
                        <div class="location-text">
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
                          {{#if (and location.latitude location.longitude)}}
                            <div class="location-coordinates">
                              {{location.latitude}}, {{location.longitude}}
                            </div>
                          {{/if}}
                        </div>
                      </div>
                    {{/if}}
                    <div class="location-actions">
                      {{#if location.googleMapsLink}}
                        <a
                          href="{{location.googleMapsLink}}"
                          target="_blank"
                          rel="noopener noreferrer"
                          class="location-action-button"
                          title="Open in Google Maps"
                        >
                          <FaIcon @icon={{faMapLocationDot}} />
                          Google Maps
                        </a>
                      {{/if}}
                      {{#if (and location.latitude location.longitude)}}
                        <button
                          type="button"
                          class="location-action-button"
                          {{on "click" this.openFullscreenMap}}
                          aria-label="Open map in fullscreen"
                        >
                          <FaIcon @icon={{faExpand}} />
                          Show Map
                        </button>
                      {{/if}}
                    </div>
                  </div>
                </div>

                {{#if location.descriptionHtml}}
                  <div class="location-description">
                    {{! Safe because we control the markdown compilation }}
                    {{! template-lint-disable no-triple-curlies }}
                    {{{location.descriptionHtml}}}
                  </div>
                {{/if}}
              </div>

              {{! Fullscreen Map }}
              {{#if this.showFullscreenMap}}
                <FullscreenMap
                  @locationId={{location.id}}
                  @locationName={{location.name}}
                  @lat={{excludeNull location.latitude}}
                  @lng={{excludeNull location.longitude}}
                  @zoom={{14}}
                  @tileUrl={{this.tileUrl}}
                  @onClose={{this.closeFullscreenMap}}
                />
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
