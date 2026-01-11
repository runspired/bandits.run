import Component from '@glimmer/component';
import { service } from '@ember/service';
import { cached, tracked } from '@glimmer/tracking';
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
import { htmlSafe } from '@ember/template';
import LeafletMap from '#components/leaflet-map.gts';
import LeafletMarker from '#components/leaflet-marker.gts';
import LeafletBoundary from '#app/components/leaflet-boundary.gts';
import { colorSchemeManager } from '#app/templates/application.gts';
import { assert } from '@ember/debug';

function or(...args: unknown[]): boolean {
  return args.some(Boolean);
}

function eq(a: unknown, b: unknown): boolean {
  return a === b;
}

function neq(a: unknown, b: unknown): boolean {
  return a !== b;
}

function and(...args: unknown[]): boolean {
  return args.every(Boolean);
}

/**
 * Extracts the hostname (domain and TLD) from a URL, removing www subdomain
 */
function getHostname(url: string): string {
  try {
    const urlObj = new URL(url);
    let hostname = urlObj.hostname;
    // Remove www. subdomain if present
    if (hostname.startsWith('www.')) {
      hostname = hostname.substring(4);
    }
    return hostname;
  } catch {
    // If URL parsing fails, return the original string
    return url;
  }
}

function excludeNull<T>(value: T | null): T {
  assert('Value is not null', value !== null);
  return value;
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
  get tileUrl() {
    return colorSchemeManager.isDarkMode
      ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png'
      : 'https://tiles.stadiamaps.com/tiles/outdoors/{z}/{x}/{y}{r}.png';
  }

  /**
   * Get the next occurrence date for a run
   */
  getNextOccurrence(run: { occurrences?: { date: string }[] }): string | null {
    if (!run.occurrences || run.occurrences.length === 0) {
      return null;
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const futureOccurrences = run.occurrences
      .map((occ) => {
        // Parse date as local timezone
        const [year, month, day] = occ.date.split('-').map(Number);
        return new Date(year ?? 2000, (month ?? 1) - 1, day ?? 1);
      })
      .filter((date) => date >= today)
      .sort((a, b) => a.getTime() - b.getTime());

    const nextDate =
      futureOccurrences.length > 0
        ? futureOccurrences[0]?.toISOString().split('T')[0]
        : null;
    return nextDate ?? null;
  }

  /**
   * Format a date string as a human-readable date
   */
  formatDate(dateStr: string): string {
    // Parse date as local timezone to avoid off-by-one errors
    const [year, month, day] = dateStr.split('-').map(Number);
    const date = new Date(year ?? 2000, (month ?? 1) - 1, day ?? 1);
    const options: Intl.DateTimeFormatOptions = {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    };
    return date.toLocaleDateString('en-US', options);
  }

  /**
   * Get a human-readable recurrence description
   */
  getRecurrenceDescription(recurrence: {
    frequency: string;
    day: number | null;
    interval: number;
    weekNumber: number | null;
  }): string {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];

    if (recurrence.frequency === 'weekly') {
      const dayName = recurrence.day !== null ? days[recurrence.day] : '';
      if (recurrence.interval === 1) {
        return `Every ${dayName}`;
      }
      return `Every ${recurrence.interval} weeks on ${dayName}`;
    }

    if (
      recurrence.frequency === 'monthly' &&
      recurrence.weekNumber !== null &&
      recurrence.day !== null
    ) {
      const weekOrdinal = ['', 'first', 'second', 'third', 'fourth', 'fifth'][
        recurrence.weekNumber
      ];
      return `${weekOrdinal} ${days[recurrence.day]} of each month`;
    }

    return recurrence.frequency;
  }

  /**
   * Format 24hr time to 12hr time
   */
  formatTime(time24: string): string {
    const [hoursStr, minutesStr] = time24.split(':');
    const hours = Number(hoursStr ?? 0);
    const minutes = Number(minutesStr ?? 0);
    const period = hours >= 12 ? 'PM' : 'AM';
    const hours12 = hours % 12 || 12;
    const minutesFormatted = minutes.toString().padStart(2, '0');
    return `${hours12}:${minutesFormatted} ${period}`;
  }

  /**
   * Get a friendly category label
   */
  getCategoryLabel(category: string): string {
    switch (category) {
      case 'no-drop':
        return 'No-Drop';
      case 'pace-groups':
        return 'Pace Groups';
      case 'at-your-own-pace':
        return 'At Your Own Pace';
      default:
        return category;
    }
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
          {{#let (this.getNextOccurrence run) as |nextDate|}}
            {{pageTitle run.title " | Bandits"}}
            <ThemedPage>
              <:header>
                {{run.title}}
              </:header>
              <:default>
                <div class="run-overview">
                  {{! Schedule info }}
                  <div class="run-card">
                    {{#if nextDate}}
                      <div class="next-occurrence">
                        <strong>Next Run:</strong>
                        <span class="next-date">{{this.formatDate
                            nextDate
                          }}</span>
                      </div>
                    {{/if}}

                    <div class="run-schedule">
                      <span
                        class="schedule-badge"
                      >{{this.getRecurrenceDescription run.recurrence}}</span>
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
                                {{this.getCategoryLabel option.category}}
                              {{/if}}
                              <br />
                              <span class="run-times">
                                {{this.formatTime option.meetTime}}
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
        {{/let}}
      </:content>
    </Request>
  </template>
}
