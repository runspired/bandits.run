import { pageTitle } from 'ember-page-title';
import { Request } from '@warp-drive/ember';
import { withReactiveResponse } from '@warp-drive/core/request';
import type { ScheduleDay } from '#app/data/schedule.ts';
import ThemedPage from '#app/components/themed-page.gts';

const query = withReactiveResponse<ScheduleDay[]>({
  url: '/api/schedule.json',
  method: 'GET',
} as const);

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

<template>
  {{pageTitle "Bandits | The Bay Area Trail Running Community"}}

  <ThemedPage>
    <Request @query={{query}}>
      <:loading> <h2>Peeking through the trees...</h2> </:loading>
      <:content as |days|>
        <div class="schedule">
          <h3 class="section-title">Find Your Trail Friends</h3>
          {{#each (sortDaysByFirstDayOfWeek days.data) as |day|}}
            <div class="day-schedule">
              <h3>{{formatDay day.day}}</h3>
              {{#if day.events.length}}
                <ul class="day-events">
                  {{#each day.events as |event|}}
                    <li class="day-event">
                      <span class="event-title">{{event.title}}</span>
                      <span class="event-location">@
                        <a
                          href="{{event.location.link}}"
                        >{{event.location.name}}</a></span>
                      <span class="event-hosts">with
                        {{#each event.hosts as |host|}}<span
                            class="host"
                          >{{host.name}}</span>{{/each}}</span>
                      {{#each event.runs as |run|}}
                        <div class="event-run">
                          <span class="event-run-time">{{formatRunTime
                              run.meetTime
                            }}</span>
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
      <:error as |error|>
        <div class="error-box"><h2>Whoops!</h2><p>We weren't able to load
            all the exciting trail runs happening near you!</p><p
            class="error-message"
          >{{error.message}} </p></div></:error>
    </Request>
  </ThemedPage>
</template>
