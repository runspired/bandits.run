import Component from '@glimmer/component';
import { service } from '@ember/service';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import type RouterService from '@ember/routing/router-service';
import { Request } from '@warp-drive/ember';
import ThemedPage from '#layout/themed-page.gts';
import { getMapStateById, type TrailRun } from '#app/data/run.ts';
import FaIcon from '#ui/fa-icon.gts';
import {
  faLocationDot,
  faMapLocationDot,
  faExpand,
} from '@fortawesome/free-solid-svg-icons';
import { LinkTo } from '@ember/routing';
import type { Future } from '@warp-drive/core/request';
import type { ReactiveDataDocument } from '@warp-drive/core/reactive';
import MapLibreBackgroundMap from '#maps/maplibre-background-map.gts';
import MapLibreFullscreenMap from '#maps/maplibre-fullscreen-map.gts';
import RunOccurrence from '#ui/nps-date.gts';
import RunOptionComponent from '#entities/run-option.gts';
import SocialGraph from '#app/components/seo/social-graph.gts';
import {
  getRecurrenceDescription,
} from '#app/utils/helpers.ts';
import {
  and,
  eq,
  excludeNull,
  not
} from '#app/utils/comparison.ts';
import './run.css';
import { getOrgSlug, getRunSlug } from '#app/utils/org.ts';

function getRunDescription(run: TrailRun): string {
  const recurrence = getRecurrenceDescription(run.recurrence);
  const orgName = run.owner.name;
  const location = run.location?.name;

  let runDetails = '';
  for (const option of run.runs ?? []) {
    if (runDetails.length > 0) {
      runDetails += ' ';
    }
    runDetails += `- ${option.name}: ${option.distance}`;
    if (option.vert) {
      runDetails += `, ⛰️ ${option.vert}.`;
    } else {
      runDetails += '.';
    }
  }
  runDetails += ' ';

  if (location) {
    return `${recurrence} group trail run with ${orgName} at ${location}. ${runDetails}Join fellow trail runners for an amazing experience! ${run.description ?? ''}`;
  }
  return `${recurrence} group trail run with ${orgName}. ${runDetails}Join fellow trail runners for an amazing experience! ${run.description ?? ''}`;
}

function getRunKeywords(run: TrailRun): string {
  const recurrence = getRecurrenceDescription(run.recurrence);
  const orgName = run.owner.name;
  const location = run.location?.name;

  const keywords = ['trail running', 'group run', orgName, recurrence];
  if (location) {
    keywords.push(location);
  }
  return keywords.join(', ');
}

function getRunUrl(organizationId: string, runId: string): string {
  return `https://bandits.run/runs/${getOrgSlug(organizationId)}/runs/${getRunSlug(runId)}`;
}

function getRunTitle(run: TrailRun): string {
  return `${run.title} | ${run.owner.name}`;
}

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
  get mapStyle() {
    return '/map-styles/openstreetmap-us-vector.json';
  }

  @cached
  get mapState() {
    return getMapStateById(`trail-run:${this.args.model.runId}`);
  }

  openFullscreenMap = () => {
    this.mapState.active = true;
  }

  closeFullscreenMap = () => {
    this.mapState.active = false;
  }

  <template>
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
          <SocialGraph
            @title={{getRunTitle run}}
            @description={{getRunDescription run}}
            @url={{getRunUrl @model.organizationId @model.runId}}
            @type="website"
            @keywords={{getRunKeywords run}}
          />
          <ThemedPage>
            <:header>{{run.owner.name}}</:header>
            <:default>
            <div class="run-page">
              {{#if
                (and
                  run.location run.location.latitude run.location.longitude (not this.mapState.active)
                )
              }}
                <MapLibreBackgroundMap
                  @lat={{excludeNull run.location.latitude}}
                  @lng={{excludeNull run.location.longitude}}
                  @zoom={{12}}
                  @minZoom={{8}}
                  @maxZoom={{18}}
                  @style={{this.mapStyle}}
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
              {{#if this.mapState.active}}
                <MapLibreFullscreenMap
                  @mapState={{run.mapState}}
                  @locationName={{run.location.name}}
                  @style={{this.mapStyle}}
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
