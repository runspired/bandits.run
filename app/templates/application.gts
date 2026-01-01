import { pageTitle } from 'ember-page-title';
import { Request } from '@warp-drive/ember';
import { on } from '@ember/modifier';
import { withReactiveResponse } from '@warp-drive/core/request';
import type { ScheduleDay } from '#app/data/schedule.ts';

const query = withReactiveResponse<ScheduleDay[]>({
  url: '/api/schedule.json',
  method: 'GET',
} as const);

let colorScheme: 'light only' | 'dark only' | null = null;

function initializeColorScheme() {
  const preferredScheme = globalThis.localStorage.getItem('preferred-color-scheme');
  if (preferredScheme === 'dark') {
    colorScheme = 'dark only';
    // eslint-disable-next-line no-undef
    document.body.style.colorScheme = 'dark only';
    // eslint-disable-next-line no-undef
    document.body.classList.add('dark-mode');
  } else if (preferredScheme === 'light') {
    colorScheme = 'light only';
    // eslint-disable-next-line no-undef
    document.body.style.colorScheme = 'light only';
    // eslint-disable-next-line no-undef
    document.body.classList.add('light-mode');
  }
}

function toggleColorScheme() {
  if (colorScheme === 'light only') {
    colorScheme = 'dark only';
    // eslint-disable-next-line no-undef
    document.body.style.colorScheme = 'dark only';
    // eslint-disable-next-line no-undef
    document.body.classList.remove('light-mode');
    // eslint-disable-next-line no-undef
    document.body.classList.add('dark-mode');
    globalThis.localStorage.setItem('preferred-color-scheme', 'dark');
  } else {
    colorScheme = 'light only';
    // eslint-disable-next-line no-undef
    document.body.style.colorScheme = 'light only';
    // eslint-disable-next-line no-undef
    document.body.classList.remove('dark-mode');
    // eslint-disable-next-line no-undef
    document.body.classList.add('light-mode');
    globalThis.localStorage.setItem('preferred-color-scheme', 'light');
  }
}

/**
 * Formats a meet time (HH:MM) into a locale-specific time string
 */
function formatRunTime(meetTime: string) {
  const date = new Date(`1970-01-01T${meetTime}:00`);
  return date.toLocaleTimeString(undefined, {
    hour: 'numeric',
    minute: meetTime.includes(':') ? '2-digit' : undefined,
  });
}

/**
 * Formats a day number (0-6) into a weekday name
 * in appropriate locale.
 */
function formatDay(day: 0 | 1 | 2 | 3 | 4 | 5 | 6) {
  const date = new Date();
  // Set to the desired day of the week
  date.setDate(date.getDate() + ((day + 7 - date.getDay()) % 7));
  return date.toLocaleDateString(undefined, { weekday: 'long' });
}

function getFirstDayOfWeek(): number {
  const pref = globalThis.localStorage.getItem('preferred-first-day-of-week');
  return pref ? parseInt(pref, 10) : 1;
}

function sortDaysByFirstDayOfWeek(days: ScheduleDay[]): ScheduleDay[] {
  const firstDayOfWeek = getFirstDayOfWeek();

  if (firstDayOfWeek !== 1) {
    return days.slice().sort((a, b) => {
      const dayA = (a.day - firstDayOfWeek + 7) % 7;
      const dayB = (b.day - firstDayOfWeek + 7) % 7;
      return dayA - dayB;
    });
  }

  return days;
}

export default <template>
  {{pageTitle "Bandits | The Bay Area Trail Running Community"}}

  <section class="page">
    {{(initializeColorScheme)}}

    <div class="landscape-container">

      <div class="sky">
        <h1 class="title" {{on "click" toggleColorScheme}}>The Bay Bandits</h1>
        <h2 class="subtitle">Trail Running Community</h2>

        <Request @query={{query}}>
          <:loading> <h2>Peeking through the trees...</h2> </:loading>
          <:content as |days|>
            <h2>Exciting Things are Happening on Trails Near You</h2>
            <div class="schedule">
              <h3 class="section-title">Schedule</h3>
              {{#each (sortDaysByFirstDayOfWeek days.data) as |day|}}
                <div class="day-schedule">
                  <h3>{{formatDay day.day}}</h3>
                  {{#if day.events.length}}
                  <ul class="day-events">
                    {{#each day.events as |event|}}
                      <li>
                        <span class="event-title">{{event.title}}</span>
                        <span class="event-location">@ <a href="{{event.location.link}}">{{event.location.name}}</a></span>
                        <span class="event-hosts">with {{#each event.hosts as |host|}}<span class="host">{{host.name}}</span>{{/each}}</span>
                        {{#each event.runs as |run|}}
                          <div class="event-run">
                            <span class="event-run-time">{{formatRunTime run.meetTime}}</span>
                            <span class="event-run-name">{{run.name}}</span>
                          </div>
                        {{/each}}
                      </li>
                    {{/each}}
                  </ul>
                  {{else}}
                  <div class="day-events">
                    <p>No scheduled events.</p>
                  </div>
                  {{/if}}
                </div>
              {{/each}}
            </div>
          </:content>
          <:error as |error|> <div class="error-box"><h2>Whoops!</h2><p>We weren't able to load all the exciting trail runs happening near you!</p><p class="error-message">{{error.message}} </p></div></:error>
        </Request>
      </div>

      <svg class="hill-svg back-hill" viewBox="0 0 1440 320" preserveAspectRatio="none">
        <path d="M0,160L120,176C240,192,480,224,720,224C960,224,1200,192,1320,176L1440,160L1440,320L1320,320C1200,320,960,320,720,320C480,320,240,320,120,320L0,320Z"></path>
      </svg>

      <svg class="hill-svg front-hill" viewBox="0 0 1440 320" preserveAspectRatio="none">
        <path d="M0,224L80,213.3C160,203,320,181,480,181.3C640,181,800,203,960,213.3C1120,224,1280,224,1360,224L1440,224L1440,320L1360,320C1280,320,1120,320,960,320C800,320,640,320,480,320C320,320,160,320,80,320L0,320Z"></path>
      </svg>

      <div class="tree-container">
        <div class="tree tree-left-0"></div>
        <div class="tree tree-left-1"></div>
        <div class="tree tree-left-2"></div>
        <div class="tree tree-left-3"></div>
        <div class="tree tree-right-0"></div>
        <div class="tree tree-right-1"></div>
        <div class="tree tree-right-2"></div>
        <div class="tree tree-right-3"></div>
        <div class="tree tree-right-4"></div>
      </div>
    </div>
  </section>

  {{outlet}}
</template>
