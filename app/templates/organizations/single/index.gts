import Component from '@glimmer/component';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import type RouterService from '@ember/routing/router-service';
import { Request } from '@warp-drive/ember';
import { withReactiveResponse } from '@warp-drive/core/request';
import ThemedPage from '#app/components/themed-page.gts';
import { pageTitle } from 'ember-page-title';
import type { Organization } from '#app/data/organization.ts';
import type { TrailRun } from '#app/data/run.ts';
import FaIcon from '#app/components/fa-icon.gts';
import { faGlobe, faCalendarDays } from '@fortawesome/free-solid-svg-icons';
import { faInstagram, faStrava, faMeetup } from '@fortawesome/free-brands-svg-icons';
import { Tabs } from '#app/components/tabs.gts';

function or(...args: unknown[]): boolean {
  return args.some(Boolean);
}

function eq(a: unknown, b: unknown): boolean {
  return a === b;
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

export default class OrganizationSingleRoute extends Component<{
  Args: {
    model: {
      organization: string;
    };
  };
}> {
  @service declare router: RouterService;

  @tracked tab: string | null = null;

  get activeTab(): string | null {
    // Get the tab from query params
    const currentRoute = this.router.currentRoute;
    const tabParam = currentRoute?.queryParams?.tab;
    return typeof tabParam === 'string' ? tabParam : null;
  }

  handleTabChange = (tabId: string | undefined) => {
    // Update the query param when tab changes
    this.router.transitionTo({ queryParams: { tab: tabId || null } });
  };

  get query() {
    return withReactiveResponse<Organization>({
      url: `/api/organization/${this.args.model.organization}.json`,
    });
  }

  get runsQuery() {
    return withReactiveResponse<TrailRun[]>({
      url: `/api/organization/${this.args.model.organization}/runs.json`,
    });
  }

  /**
   * Sort runs by next occurrence date, with runs without future occurrences at the end
   */
  sortRunsByNextOccurrence = (runs: TrailRun[]): TrailRun[] => {
    return [...runs].sort((a, b) => {
      const nextA = this.getNextOccurrence(a);
      const nextB = this.getNextOccurrence(b);

      // If neither has a next occurrence, maintain original order
      if (!nextA && !nextB) return 0;
      // If only A has no next occurrence, put it after B
      if (!nextA) return 1;
      // If only B has no next occurrence, put it after A
      if (!nextB) return -1;
      // Both have next occurrences, sort by date
      return nextA.localeCompare(nextB);
    });
  };

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

    const nextDate = futureOccurrences.length > 0 ? futureOccurrences[0]?.toISOString().split('T')[0] : null;
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
      day: 'numeric'
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
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    if (recurrence.frequency === 'weekly') {
      const dayName = recurrence.day !== null ? days[recurrence.day] : '';
      if (recurrence.interval === 1) {
        return `Every ${dayName}`;
      }
      return `Every ${recurrence.interval} weeks on ${dayName}`;
    }

    if (recurrence.frequency === 'monthly' && recurrence.weekNumber !== null && recurrence.day !== null) {
      const weekOrdinal = ['', 'first', 'second', 'third', 'fourth', 'fifth'][recurrence.weekNumber];
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

    <ThemedPage>
      <Tabs @activeId={{this.activeTab}} @onTabChange={{this.handleTabChange}} as |Tab|>
        <Tab @id="overview">
          <:label>Overview</:label>
          <:body>
            <Request @query={{this.query}}>
              <:loading> <h2>Loading organization...</h2> </:loading>
              <:content as |response|>
                {{#let response.data as |org|}}
                  {{pageTitle org.name " | Bandits"}}
                  <div class="schedule">
                    <div class="day-schedule">
                      <h2>{{org.name}}</h2>
                      <div class="day-events">
                        {{#if org.description}}
                          <div class="org-description">
                            {{org.description}}
                          </div>
                        {{/if}}
                        <ul class="org-details">
                          {{#if org.website}}
                            <li class="org-detail">
                              <a
                                href="{{org.website}}"
                                target="_blank"
                                rel="noopener noreferrer"
                              >
                                <FaIcon @icon={{faGlobe}} />
                                {{getHostname org.website}}
                              </a>
                            </li>
                          {{/if}}
                          {{#if org.stravaHandle}}
                            <li class="org-detail">
                              <a
                                href="https://www.strava.com/clubs/{{org.stravaHandle}}"
                                target="_blank"
                                rel="noopener noreferrer"
                              >
                                <FaIcon @icon={{faStrava}} />
                                @{{org.stravaHandle}}
                              </a>
                            </li>
                          {{else if org.stravaId}}
                            <li class="org-detail">
                              <a
                                href="https://www.strava.com/clubs/{{org.stravaId}}"
                                target="_blank"
                                rel="noopener noreferrer"
                              >
                                <FaIcon @icon={{faStrava}} />
                                Strava
                              </a>
                            </li>
                          {{/if}}
                          {{#if org.instagramHandle}}
                            <li class="org-detail">
                              <a
                                href="https://www.instagram.com/{{org.instagramHandle}}"
                                target="_blank"
                                rel="noopener noreferrer"
                              >
                                <FaIcon @icon={{faInstagram}} />
                                @{{org.instagramHandle}}
                              </a>
                            </li>
                          {{/if}}
                          {{#if org.email}}
                            <li class="org-detail">
                              <span class="detail-label">Email:</span>
                              <a href="mailto:{{org.email}}">{{org.email}}</a>
                            </li>
                          {{/if}}
                          {{#if org.phoneNumber}}
                            <li class="org-detail">
                              <span class="detail-label">Phone:</span>
                              <a
                                href="tel:{{org.phoneNumber}}"
                              >{{org.phoneNumber}}</a>
                            </li>
                          {{/if}}
                          {{#if org.meetupId}}
                            <li class="org-detail">
                              <span class="detail-label">Meetup:</span>
                              <a
                                href="https://www.meetup.com/{{org.meetupId}}"
                                target="_blank"
                                rel="noopener noreferrer"
                              >{{org.meetupId}}</a>
                            </li>
                          {{/if}}
                        </ul>
                      </div>
                    </div>
                  </div>
                {{/let}}
              </:content>
              <:error as |error|>
                <div class="error-box">
                  <h2>Whoops!</h2>
                  <p>We weren't able to load this organization!</p>
                  <p class="error-message">{{error.message}}</p>
                </div>
              </:error>
            </Request>
          </:body>
        </Tab>
        <Tab @id="runs">
          <:label>Runs</:label>
          <:body>
            <Request @query={{this.runsQuery}}>
              <:loading> <h2>Loading runs...</h2> </:loading>
              <:content as |response|>
                {{#let response.data as |runs|}}
                  {{#if runs}}
                    <div class="runs-list">
                      {{#each (this.sortRunsByNextOccurrence runs) as |run|}}
                        {{#let (this.getNextOccurrence run) as |nextDate|}}
                          <div class="run-card">
                            <h3 class="run-title">{{run.title}}</h3>

                            {{#if nextDate}}
                              <div class="next-occurrence">
                                <strong>Next Run:</strong>
                                <span class="next-date">{{this.formatDate nextDate}}</span>
                              </div>
                            {{/if}}

                            <div class="run-schedule">
                              <span class="schedule-badge">{{this.getRecurrenceDescription run.recurrence}}</span>
                            </div>

                            {{#if run.description}}
                              <p class="run-description">{{run.description}}</p>
                            {{/if}}

                            {{#if run.location}}
                              <div class="run-location">
                                <strong>Location:</strong> {{run.location.name}}
                              </div>
                            {{/if}}

                            {{#if run.runs}}
                              <div class="run-options">
                                <h4>{{#if (eq run.runs.length 1)}}Run Details:{{else}}Run Options:{{/if}}</h4>
                                <ul class="run-options-list">
                                  {{#each run.runs as |option|}}
                                    <li class="run-option">
                                      {{#if option.name}}
                                        <strong>{{option.name}}:</strong>
                                      {{/if}}
                                      {{option.distance}} • {{option.vert}}
                                      {{#if option.pace}}
                                        • {{option.pace}} • {{this.getCategoryLabel option.category}}
                                      {{/if}}
                                      <br />
                                      <span class="run-times">
                                        {{this.formatTime option.meetTime}}
                                      </span>
                                      {{#let
                                        (if (eq run.runs.length 1) run.eventLink option.eventLink)
                                        (if (eq run.runs.length 1) run.stravaEventLink option.stravaEventLink)
                                        (if (eq run.runs.length 1) run.meetupEventLink option.meetupEventLink)
                                        as |eventLink stravaEventLink meetupEventLink|
                                      }}
                                        {{#if (or eventLink stravaEventLink meetupEventLink)}}
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
                        {{/let}}
                      {{/each}}
                    </div>
                  {{else}}
                    <p>No runs found for this organization.</p>
                  {{/if}}
                {{/let}}
              </:content>
              <:error as |error|>
                <div class="error-box">
                  <h2>Whoops!</h2>
                  <p>We weren't able to load the runs!</p>
                  <p class="error-message">{{error.message}}</p>
                </div>
              </:error>
            </Request>
          </:body>
        </Tab>
      </Tabs>
    </ThemedPage>
  </template>
}
