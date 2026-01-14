import { LinkTo } from '@ember/routing';
import { array } from '@ember/helper';
import FaIcon from '#ui/fa-icon.gts';
import RunOccurrence from '#ui/nps-date.gts';
import { faCalendarDays, faLocationDot } from '@fortawesome/free-solid-svg-icons';
import { faStrava, faMeetup } from '@fortawesome/free-brands-svg-icons';
import type { TrailRun } from '#app/data/run.ts';
import {
  getRecurrenceDescription,
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

          <h4 class="run-organization">
            <LinkTo
              @route="organizations.single"
              @model={{@run.owner.id}}
              class={{scopedClass "organization-link"}}
            >
              {{@run.owner.name}}
            </LinkTo>
          </h4>

          <div class="run-schedule">
            <span class="schedule-badge">{{getRecurrenceDescription
                @run.recurrence
              }}</span>
            {{#if (isToday displayDate)}}
              <span class="today-badge">Today</span>
            {{/if}}
            {{#if @run.location}}
              <span class="location-badge">
                <strong><FaIcon @icon={{faLocationDot}} /></strong>
                <LinkTo @route="location" @model={{@run.location.id}}>
                  {{@run.location.name}}
                </LinkTo>
              </span>
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
              <RunOption
                @option={{option}}
                @eventLink={{if (eq @run.runs.length 1)
                  @run.eventLink option.eventLink}}
                @stravaEventLink={{if (eq @run.runs.length 1)
                    @run.stravaEventLink option.stravaEventLink}}
                @meetupEventLink={{if (eq @run.runs.length 1)
                    @run.meetupEventLink option.meetupEventLink}}
              />
            {{/each}}
          </ul>
        </div>
      {{/if}}

    </div>
  {{/let}}
</template>;

export default RunPreview;

import type { TemplateOnlyComponent } from '@ember/component/template-only';import RunOptionComponent from './run-option.gts';
import RunOption from './run-option.gts';
import { scopedClass } from 'ember-scoped-css';

