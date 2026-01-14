import Component from '@glimmer/component';
import { service } from '@ember/service';
import { cached, tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import type RouterService from '@ember/routing/router-service';
import { Request } from '@warp-drive/ember';
import ThemedPage from '#layout/themed-page.gts';
import { pageTitle } from 'ember-page-title';
import type { TrailRun } from '#app/data/run.ts';
import FaIcon from '#ui/fa-icon.gts';
import {
  faLocationDot,
  faMapLocationDot,
  faExpand,
} from '@fortawesome/free-solid-svg-icons';
import { LinkTo } from '@ember/routing';
import type { Future } from '@warp-drive/core/request';
import type { ReactiveDataDocument } from '@warp-drive/core/reactive';
import BackgroundMap from '#maps/background-map.gts';
import FullscreenMap from '#maps/fullscreen-map.gts';
import RunOccurrence from '#ui/nps-date.gts';
import RunOptionComponent from '#entities/run-option.gts';
import {
  getRecurrenceDescription,
} from '#app/utils/helpers.ts';
import {
  and,
  eq,
  excludeNull
} from '#app/utils/comparison.ts';
import { getTheme } from '#app/core/site-theme.ts';
import './run.css';


export default class OrganizationRunRoute extends Component<{
  Args: {
    model: {
      run: Future<ReactiveDataDocument<TrailRun>>;
      organizationId: string;
      runId: string;
    };
  };
}> {
  @service declare router: RouterService;

  @tracked showFullscreenMap = false;

  @cached
  get tileUrl() {
    return getTheme().isDarkMode
      ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png'
      : 'https://tiles.stadiamaps.com/tiles/outdoors/{z}/{x}/{y}{r}.png';
  }

  openFullscreenMap = () => {
    this.showFullscreenMap = true;
  }

  closeFullscreenMap = () => {
    this.showFullscreenMap = false;
  }

  <template>
    {{pageTitle "Organization | Bandits"}}

    <Request @request={{@model.run}}>
      <:loading> <h2>Loading run...</h2> </:loading>
      <:error as |error|>
        <div class="error-box">
          <h2>Whoops!</h2>
          <p>We weren't able to load this run!</p>
          <p class="error-message">{{error.message}}</p>
        </div>
      </:error>
      <:content as |response|>
        {{#let response.data as |run|}}
          {{pageTitle run.title " | Bandits"}}
          <ThemedPage>
            <:header>{{run.owner.name}}</:header>
            <:default>
            <div class="run-page">
              {{#if
                (and
                  run.location run.location.latitude run.location.longitude
                )
              }}
                <BackgroundMap
                  @lat={{excludeNull run.location.latitude}}
                  @lng={{excludeNull run.location.longitude}}
                  @zoom={{12}}
                  @minZoom={{8}}
                  @maxZoom={{18}}
                  @tileUrl={{this.tileUrl}}
                  @markerTitle={{run.location.name}}
                />
              {{/if}}

              <div class="run-content">
                <div class="run-header">
                  <div class="run-header-main">
                    <div class="run-header-content">
                      <h2>{{run.title}}</h2>
                      <div class="run-schedule">
                        <span
                          class="schedule-badge"
                        >{{getRecurrenceDescription run.recurrence}}</span>
                      </div>
                    </div>
                    {{#if run.nextOccurrence}}
                      <div class="run-header-occurrence">
                        <RunOccurrence @date={{run.nextOccurrence}} />
                      </div>
                    {{/if}}
                  </div>

                  {{#if run.location}}
                    <div class="run-header-location">
                      <div class="location-info">
                        <FaIcon @icon={{faLocationDot}} />
                        <div class="location-text">
                          <strong>
                            <LinkTo
                              @route="location"
                              @model={{run.location.id}}
                            >
                              {{run.location.name}}
                            </LinkTo>
                          </strong>
                          {{#if run.location.address}}
                            <address>
                              {{#if run.location.address.street}}
                                {{run.location.address.street}}<br />
                              {{/if}}
                              {{#if run.location.address.city}}
                                {{run.location.address.city}},
                                {{run.location.address.state}}
                                {{run.location.address.zip}}
                              {{/if}}
                            </address>
                          {{/if}}
                        </div>
                      </div>
                      <div class="location-actions">
                        {{#if run.location.googleMapsLink}}
                          <a
                            href="{{run.location.googleMapsLink}}"
                            target="_blank"
                            rel="noopener noreferrer"
                            class="location-action-button"
                            title="Open in Google Maps"
                          >
                            <FaIcon @icon={{faMapLocationDot}} />
                            Google Maps
                          </a>
                        {{/if}}
                        {{#if
                          (and run.location.latitude run.location.longitude)
                        }}
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
                  {{/if}}
                </div>

                {{! Run Options }}
                {{#if run.runs}}
                  <div class="run-options">
                    <h4>{{#if (eq run.runs.length 1)}}Run Details{{else}}Run
                        Options{{/if}}</h4>
                    <ul class="run-options-list">
                      {{#each run.runs as |option|}}
                        <RunOptionComponent
                          @option={{option}}
                          @eventLink={{if
                            (eq run.runs.length 1)
                            run.eventLink
                            option.eventLink
                          }}
                          @stravaEventLink={{if
                            (eq run.runs.length 1)
                            run.stravaEventLink
                            option.stravaEventLink
                          }}
                          @meetupEventLink={{if
                            (eq run.runs.length 1)
                            run.meetupEventLink
                            option.meetupEventLink
                          }}
                        />
                      {{/each}}
                    </ul>
                  </div>
                {{/if}}
              </div>

              {{! Fullscreen Map }}
              {{#if this.showFullscreenMap}}
                <FullscreenMap
                  @locationId={{run.location.id}}
                  @locationName={{run.location.name}}
                  @lat={{excludeNull run.location.latitude}}
                  @lng={{excludeNull run.location.longitude}}
                  @zoom={{14}}
                  @tileUrl={{this.tileUrl}}
                  @onClose={{this.closeFullscreenMap}}
                />
              {{/if}}
            </div>
            </:default>
          </ThemedPage>
        {{/let}}
      </:content>
    </Request>
  </template>
}
