import Component from '@glimmer/component';
import { service } from '@ember/service';
import { cached } from '@glimmer/tracking';
import type RouterService from '@ember/routing/router-service';
import { Request } from '@warp-drive/ember';
import ThemedPage from '#app/components/themed-page.gts';
import { pageTitle } from 'ember-page-title';
import type { TrailRun } from '#app/data/run.ts';
import FaIcon from '#app/components/fa-icon.gts';
import {
  faCalendarDays,
  faLocationDot,
  faMapLocationDot,
} from '@fortawesome/free-solid-svg-icons';
import { faStrava, faMeetup } from '@fortawesome/free-brands-svg-icons';
import { LinkTo } from '@ember/routing';
import type { Future } from '@warp-drive/core/request';
import type { ReactiveDataDocument } from '@warp-drive/core/reactive';
import LeafletMap from '#components/leaflet-map.gts';
import LeafletMarker from '#components/leaflet-marker.gts';
import LeafletBoundary from '#app/components/leaflet-boundary.gts';
import { colorSchemeManager } from '#app/templates/application.gts';
import {
  and,
  neq,
  or,
  eq,
  excludeNull,
  formatFriendlyDate,
  getRecurrenceDescription,
  formatTime,
  getCategoryLabel,
} from '#app/utils/helpers.ts';

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

  @cached
  get tileUrl() {
    return colorSchemeManager.isDarkMode
      ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png'
      : 'https://tiles.stadiamaps.com/tiles/outdoors/{z}/{x}/{y}{r}.png';
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
            <:header>
              {{run.title}}
            </:header>
            <:default>
              <div class="run-overview">
                {{! Schedule info }}
                <div class="run-card">
                  {{#if run.nextOccurrence}}
                    <div class="next-occurrence">
                      <strong>Next Run:</strong>
                      <span class="next-date">{{formatFriendlyDate
                          run.nextOccurrence
                        }}</span>
                    </div>
                  {{/if}}

                  <div class="run-schedule">
                    <span
                      class="schedule-badge"
                    >{{getRecurrenceDescription run.recurrence}}</span>
                  </div>

                  {{! Location info }}
                  {{#if run.location}}
                    <div class="run-location-info">
                      <div class="location-detail">
                        <FaIcon @icon={{faLocationDot}} />
                        <div>
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
                      {{#if run.location.googleMapsLink}}
                        <div class="location-detail">
                          <FaIcon @icon={{faMapLocationDot}} />
                          <a
                            href="{{run.location.googleMapsLink}}"
                            target="_blank"
                            rel="noopener noreferrer"
                          >
                            Open in Google Maps
                          </a>
                        </div>
                      {{/if}}
                    </div>
                  {{/if}}

                  {{! RSVP Links }}
                  {{#if
                    (and
                      (neq run.runs.length 1)
                      (or
                        run.eventLink run.stravaEventLink run.meetupEventLink
                      )
                    )
                  }}
                    <div class="run-links">
                      <strong>RSVP:</strong>
                      {{#if run.eventLink}}
                        <a
                          href="{{run.eventLink}}"
                          target="_blank"
                          rel="noopener noreferrer"
                          class="details-link"
                        >
                          <FaIcon @icon={{faCalendarDays}} />
                          Event Details
                        </a>
                      {{/if}}
                      {{#if run.stravaEventLink}}
                        <a
                          href="{{run.stravaEventLink}}"
                          target="_blank"
                          rel="noopener noreferrer"
                          class="details-link"
                        >
                          <FaIcon @icon={{faStrava}} />
                          Strava Event
                        </a>
                      {{/if}}
                      {{#if run.meetupEventLink}}
                        <a
                          href="{{run.meetupEventLink}}"
                          target="_blank"
                          rel="noopener noreferrer"
                          class="details-link"
                        >
                          <FaIcon @icon={{faMeetup}} />
                          Meetup Event
                        </a>
                      {{/if}}
                    </div>
                  {{/if}}

                  {{! Run Options }}
                  {{#if run.runs}}
                    <div class="run-options">
                      <h4>{{#if (eq run.runs.length 1)}}Run Details:{{else}}Run
                          Options:{{/if}}</h4>
                      <ul class="run-options-list">
                        {{#each run.runs as |option|}}
                          <li class="run-option">
                            {{#if option.name}}
                              <strong>{{option.name}}:</strong>
                            {{/if}}
                            {{option.distance}}
                            •
                            {{option.vert}}
                            {{#if option.pace}}
                              •
                              {{option.pace}}
                              •
                              {{getCategoryLabel option.category}}
                            {{/if}}
                            <br />
                            <span class="run-times">
                              {{formatTime option.meetTime}}
                            </span>
                            {{#let
                              (if
                                (eq run.runs.length 1)
                                run.eventLink
                                option.eventLink
                              )
                              (if
                                (eq run.runs.length 1)
                                run.stravaEventLink
                                option.stravaEventLink
                              )
                              (if
                                (eq run.runs.length 1)
                                run.meetupEventLink
                                option.meetupEventLink
                              )
                              as |eventLink stravaEventLink meetupEventLink|
                            }}
                              {{#if
                                (or eventLink stravaEventLink meetupEventLink)
                              }}
                                <div class="run-option-links">
                                  <strong>RSVP:</strong>
                                  {{#if eventLink}}
                                    <a
                                      href="{{eventLink}}"
                                      target="_blank"
                                      rel="noopener noreferrer"
                                      title="Event Details"
                                      class="rsvp-link"
                                    >
                                      <FaIcon @icon={{faCalendarDays}} />
                                      Event
                                    </a>
                                  {{/if}}
                                  {{#if stravaEventLink}}
                                    <a
                                      href="{{stravaEventLink}}"
                                      target="_blank"
                                      rel="noopener noreferrer"
                                      title="Strava Event"
                                      class="rsvp-link"
                                    >
                                      <FaIcon @icon={{faStrava}} />
                                      Strava
                                    </a>
                                  {{/if}}
                                  {{#if meetupEventLink}}
                                    <a
                                      href="{{meetupEventLink}}"
                                      target="_blank"
                                      rel="noopener noreferrer"
                                      title="Meetup Event"
                                      class="rsvp-link"
                                    >
                                      <FaIcon @icon={{faMeetup}} />
                                      Meetup
                                    </a>
                                  {{/if}}
                                </div>
                              {{/if}}
                            {{/let}}
                          </li>
                        {{/each}}
                      </ul>
                    </div>
                  {{/if}}
                </div>

                {{!-- {{! Description }}
                {{#if run.descriptionHtml}}
                  <div class="run-description-section">
                    <h3>About This Run</h3>
                    <div class="markdown-content">
                      {{htmlSafe run.descriptionHtml}}
                    </div>
                  </div>
                {{else if run.description}}
                  <div class="run-description-section">
                    <h3>About This Run</h3>
                    <p class="run-description-text">{{run.description}}</p>
                  </div>
                {{/if}} --}}

                {{! Map }}
                {{#if
                  (and
                    run.location run.location.latitude run.location.longitude
                  )
                }}
                  <div class="run-map-section">
                    <h3>Location</h3>
                    <div class="map-container">
                      <LeafletBoundary>
                        <LeafletMap
                          @lat={{excludeNull run.location.latitude}}
                          @lng={{excludeNull run.location.longitude}}
                          @zoom={{14}}
                          @tileUrl={{this.tileUrl}}
                          as |map|
                        >
                          <LeafletMarker
                            @context={{map}}
                            @lat={{excludeNull run.location.latitude}}
                            @lng={{excludeNull run.location.longitude}}
                            @title={{run.location.name}}
                          />
                        </LeafletMap>
                      </LeafletBoundary>
                    </div>
                  </div>
                {{/if}}
              </div>
            </:default>
          </ThemedPage>
        {{/let}}
      </:content>
    </Request>
  </template>
}
