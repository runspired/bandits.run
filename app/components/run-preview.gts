import { LinkTo } from '@ember/routing';
import { array } from '@ember/helper';
import FaIcon from '#app/components/fa-icon.gts';
import { faCalendarDays } from '@fortawesome/free-solid-svg-icons';
import { faStrava, faMeetup } from '@fortawesome/free-brands-svg-icons';
import type { TrailRun } from '#app/data/run.ts';
import {
  eq,
  neq,
  and,
  or,
  formatFriendlyDate,
  getRecurrenceDescription,
  formatTime,
  getCategoryLabel,
} from '#app/utils/helpers.ts';

interface RunPreviewSignature {
  Args: {
    run: TrailRun;
    organizationId: string;
  };
}

const RunPreview: TemplateOnlyComponent<RunPreviewSignature> = <template>
  <div class="run-card">
    <h3 class="run-title">
      <LinkTo
        @route="organizations.single.run"
        @models={{array @organizationId @run.id}}
      >
        {{@run.title}}
      </LinkTo>
    </h3>

    {{#if @run.nextOccurrence}}
      <div class="next-occurrence">
        <strong>Next Run:</strong>
        <span class="next-date">{{formatFriendlyDate
            @run.nextOccurrence
          }}</span>
      </div>
    {{/if}}

    <div class="run-schedule">
      <span class="schedule-badge">{{getRecurrenceDescription
          @run.recurrence
        }}</span>
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
              <span class="run-times">
                {{formatTime option.meetTime}}
              </span>
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
</template>;

export default RunPreview;

import type { TemplateOnlyComponent } from '@ember/component/template-only';
