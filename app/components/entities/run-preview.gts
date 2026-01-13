import { LinkTo } from '@ember/routing';
import { array } from '@ember/helper';
import FaIcon from '#ui/fa-icon.gts';
import RunOccurrence from '#ui/nps-date.gts';
import { faCalendarDays } from '@fortawesome/free-solid-svg-icons';
import { faStrava, faMeetup } from '@fortawesome/free-brands-svg-icons';
import type { TrailRun } from '#app/data/run.ts';
import {
  getRecurrenceDescription,
  formatTime,
  getCategoryLabel,
  isPastDate,
  isToday,
} from '#app/utils/helpers.ts';
import {
  eq,
  neq,
  and,
  or,
} from '#app/utils/comparison.ts';

interface RunPreviewSignature {
  Args: {
    run: TrailRun;
    organizationId: string;
    occurrence?: string;
    hideOccurrence?: boolean;
  };
}

const RunPreview: TemplateOnlyComponent<RunPreviewSignature> = <template>
  {{#let (if @occurrence @occurrence @run.nextOccurrence) as |displayDate|}}
    <div
      class="run-card
        {{if (and displayDate (isPastDate displayDate)) 'past-occurrence'}}"
    >
      <div class="run-header">
        <div class="run-header-content">
          <h3 class="run-title">
            <LinkTo
              @route="organizations.single.run"
              @models={{array @organizationId @run.id}}
            >
              {{@run.title}}
            </LinkTo>
          </h3>

          <div class="run-schedule">
            <span class="schedule-badge">{{getRecurrenceDescription
                @run.recurrence
              }}</span>
            {{#if (isToday displayDate)}}
              <span class="today-badge">Today</span>
            {{/if}}
          </div>
        </div>

        {{#unless @hideOccurrence}}
          <div class="run-header-occurrence">
            <RunOccurrence @date={{displayDate}} />
          </div>
        {{/unless}}
      </div>

      {{#if @run.description}}
        <p class="run-description">{{@run.description}}</p>
      {{/if}}

      {{#if @run.location}}
        <div class="run-location">
          <strong>Location:</strong>
          <LinkTo @route="location" @model={{@run.location.id}}>
            {{@run.location.name}}
          </LinkTo>
        </div>
      {{/if}}

      {{#if
        (and
          (neq @run.runs.length 1)
          (or @run.eventLink @run.stravaEventLink @run.meetupEventLink)
        )
      }}
        <div class="run-links">
          <strong>RSVP:</strong>
          {{#if @run.eventLink}}
            <a
              href="{{@run.eventLink}}"
              target="_blank"
              rel="noopener noreferrer"
              class="details-link"
            >
              <FaIcon @icon={{faCalendarDays}} />
              Event Details
            </a>
          {{/if}}
          {{#if @run.stravaEventLink}}
            <a
              href="{{@run.stravaEventLink}}"
              target="_blank"
              rel="noopener noreferrer"
              class="details-link"
            >
              <FaIcon @icon={{faStrava}} />
              Strava Event
            </a>
          {{/if}}
          {{#if @run.meetupEventLink}}
            <a
              href="{{@run.meetupEventLink}}"
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

      {{#if @run.runs}}
        <div class="run-options">
          <h4>{{#if (eq @run.runs.length 1)}}Run Details:{{else}}Run Options:{{/if}}</h4>
          <ul class="run-options-list">
            {{#each @run.runs as |option|}}
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
                {{#let
                  (if (eq @run.runs.length 1) @run.eventLink option.eventLink)
                  (if
                    (eq @run.runs.length 1)
                    @run.stravaEventLink
                    option.stravaEventLink
                  )
                  (if
                    (eq @run.runs.length 1)
                    @run.meetupEventLink
                    option.meetupEventLink
                  )
                  as |eventLink stravaEventLink meetupEventLink|
                }}
                  <span class="run-times">
                    {{formatTime option.meetTime}}
                    {{#if (or eventLink stravaEventLink meetupEventLink)}}
                      <span class="run-option-links">
                        •
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
                      </span>
                    {{/if}}
                  </span>
                {{/let}}
              </li>
            {{/each}}
          </ul>
        </div>
      {{/if}}

    </div>
  {{/let}}
</template>;

export default RunPreview;

import type { TemplateOnlyComponent } from '@ember/component/template-only';
