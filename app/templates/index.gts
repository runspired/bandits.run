import { pageTitle } from 'ember-page-title';
import { Request } from '@warp-drive/ember';
import { withReactiveResponse } from '@warp-drive/core/request';
import type { ScheduleDay } from '#app/data/schedule.ts';
import ThemedPage from '#app/components/themed-page.gts';
import { Tabs } from '#app/components/tabs.gts';
import { getFirstDayOfWeek, formatDay, formatRunTime } from '#app/utils/helpers.ts';

const query = withReactiveResponse<ScheduleDay[]>({
  url: '/api/schedule.json',
  method: 'GET',
} as const);


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
    <Tabs as |Tab|>
      <Tab>
        <:label>Schedule</:label>
        <:body>
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
        </:body>
      </Tab>
    </Tabs>
  </ThemedPage>
</template>
