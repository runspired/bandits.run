import type { TemplateOnlyComponent } from '@ember/component/template-only';
import FaIcon from '#ui/fa-icon.gts';
import { faCalendarDays } from '@fortawesome/free-solid-svg-icons';
import { faStrava, faMeetup } from '@fortawesome/free-brands-svg-icons';
import type { RunOption as RunOptionResource } from '#app/data/run.ts';
import { formatTime, getCategoryLabel } from '#app/utils/helpers.ts';
import { or } from '#app/utils/comparison.ts';
import './run-option.css';

interface RunOptionComponentSignature {
  Args: {
    option: RunOptionResource;
    eventLink?: string | null;
    stravaEventLink?: string | null;
    meetupEventLink?: string | null;
  };
}

const RunOption: TemplateOnlyComponent<RunOptionComponentSignature> = <template>
  <li class="run-option" ...attributes>
    {{#if @option.name}}
      <strong>{{@option.name}}:</strong>
    {{/if}}
    {{@option.distance}}
    •
    {{@option.vert}}
    {{#if @option.pace}}
      •
      {{@option.pace}}
      •
      {{getCategoryLabel @option.category}}
    {{/if}}
    <br />
    <span class="run-times">
      {{formatTime @option.meetTime}}
    </span>
    {{#if (or @eventLink @stravaEventLink @meetupEventLink)}}
      <div class="run-option-links">
        <strong>RSVP:</strong>
        {{#if @eventLink}}
          <a
            href="{{@eventLink}}"
            target="_blank"
            rel="noopener noreferrer"
            title="Event Details"
            class="rsvp-link"
          >
            <FaIcon @icon={{faCalendarDays}} />
            Event
          </a>
        {{/if}}
        {{#if @stravaEventLink}}
          <a
            href="{{@stravaEventLink}}"
            target="_blank"
            rel="noopener noreferrer"
            title="Strava Event"
            class="rsvp-link"
          >
            <FaIcon @icon={{faStrava}} />
            Strava
          </a>
        {{/if}}
        {{#if @meetupEventLink}}
          <a
            href="{{@meetupEventLink}}"
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
  </li>
</template>;

export default RunOption;
