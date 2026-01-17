import ThemedPage from '#layout/themed-page.gts';
import Component from '@glimmer/component';
import { Request } from '@warp-drive/ember';
import { pageTitle } from 'ember-page-title';
import MapLibreBackgroundMap from '#maps/maplibre-background-map.gts';
import FaIcon from '#ui/fa-icon.gts';
import {
  faLocationDot,
  faMapLocationDot,
  faExpand,
} from '@fortawesome/free-solid-svg-icons';
import { tracked } from '@glimmer/tracking';
import './location.css';
import { assert } from '@ember/debug';
import { getLocation } from '#api/GET';
import { and } from '#app/utils/comparison.ts';
import MapLibreFullscreenMap from '#maps/maplibre-fullscreen-map.gts';
import { on } from '@ember/modifier';

export default class LocationDisplay extends Component<{
  Args: {
    model: {
      location: string;
    };
  };
}> {
  @tracked showFullscreenMap: boolean = false;

  openFullscreenMap = () => {
    this.showFullscreenMap = true;
  };

  closeFullscreenMap = () => {
    this.showFullscreenMap = false;
  };

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
                <MapLibreBackgroundMap
                  @lat={{excludeNull location.latitude}}
                  @lng={{excludeNull location.longitude}}
                  @zoom={{10}}
                  @minZoom={{6}}
                  @maxZoom={{18}}
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
                <MapLibreFullscreenMap
                  @mapState={{location.mapState}}
                  @locationName={{location.name}}
                  @lat={{excludeNull location.latitude}}
                  @lng={{excludeNull location.longitude}}
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
