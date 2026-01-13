import { pageTitle } from 'ember-page-title';
import { Request } from '@warp-drive/ember';
import type { RealizedEventDate } from '#app/data/realized-event-date.ts';
import ThemedPage from '#layout/themed-page.gts';
import { Tabs } from '#ux/tabs.gts';
import { getDayOfWeek, isToday } from '#app/utils/helpers.ts';
import RunPreview from '#entities/run-preview.gts';
import RunOccurrence from '#ui/nps-date.gts';
import { getCurrentWeek, getNextWeek } from '#api/GET';
import { weekHasFourDaysRemaining } from '#app/utils/helpers.ts';

interface DayGroup {
  date: string;
  dayOfWeek: string;
  events: RealizedEventDate[];
}

function groupEventsByDay(events: RealizedEventDate[]): DayGroup[] {
  const grouped = new Map<string, RealizedEventDate[]>();

  for (const event of events) {
    const date = event.date;
    if (!grouped.has(date)) {
      grouped.set(date, []);
    }
    grouped.get(date)!.push(event);
  }

  const sortedDates = Array.from(grouped.keys()).sort();

  return sortedDates.map(date => ({
    date,
    dayOfWeek: getDayOfWeek(date),
    events: grouped.get(date)!,
  }));
}

function filterFutureDays(dayGroups: DayGroup[]): DayGroup[] {
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  yesterday.setHours(0, 0, 0, 0);

  return dayGroups.filter(dayGroup => {
    const [year, month, day] = dayGroup.date.split('-').map(Number);
    const date = new Date(year ?? 2000, (month ?? 1) - 1, day ?? 1);
    return date >= yesterday;
  });
}

<template>
  {{pageTitle "Bandits | The Bay Area Trail Running Community"}}

  <ThemedPage>
    <Tabs as |Tab|>
      <Tab @slug="this-week">
        <:title>This Week</:title>
        <:body>
          <Request @query={{(getCurrentWeek)}}>
            <:loading> <h2>Peeking through the trees...</h2> </:loading>
            <:content as |week|>
              <div class="schedule">
                <h3 class="section-title">Runs This Week</h3>
                {{#each (if (weekHasFourDaysRemaining) (filterFutureDays (groupEventsByDay week.data.events)) (groupEventsByDay week.data.events)) as |dayGroup|}}
                  <div class="day-schedule {{if (isToday dayGroup.date) 'today'}}">
                    <RunOccurrence @date={{dayGroup.date}} @label={{dayGroup.dayOfWeek}} />
                    {{#if dayGroup.events.length}}
                      <div class="day-events">
                        {{#each dayGroup.events as |occurrence|}}
                          <RunPreview @hideOccurrence={{true}} @occurrence={{occurrence.date}} @run={{occurrence.event}} @organizationId={{occurrence.event.owner.id}} />
                        {{/each}}
                      </div>
                    {{else}}
                      <div class="day-events">
                        <p>No scheduled events.</p>
                      </div>
                    {{/if}}
                  </div>
                {{/each}}
              </div>
              {{#if (weekHasFourDaysRemaining)}}
                <Request @query={{(getNextWeek)}}>
                  <:loading> <h2>Loading next week...</h2> </:loading>
                  <:content as |nextWeek|>
                    <div class="schedule">
                      <h3 class="section-title">Runs Next Week</h3>
                      {{#each (groupEventsByDay nextWeek.data.events) as |dayGroup|}}
                        <div class="day-schedule {{if (isToday dayGroup.date) 'today'}}">
                          <RunOccurrence @date={{dayGroup.date}} @label={{dayGroup.dayOfWeek}} />
                          {{#if dayGroup.events.length}}
                            <div class="day-events">
                              {{#each dayGroup.events as |occurrence|}}
                                <RunPreview @hideOccurrence={{true}} @occurrence={{occurrence.date}} @run={{occurrence.event}} @organizationId={{occurrence.event.owner.id}} />
                              {{/each}}
                            </div>
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
                      next week's trail runs!</p><p
                      class="error-message"
                    >{{error.message}} </p></div></:error>
                </Request>
              {{/if}}
            </:content>
            <:error as |error|>
              <div class="error-box"><h2>Whoops!</h2><p>We weren't able to load
                  this week's trail runs!</p><p
                  class="error-message"
                >{{error.message}} </p></div></:error>
          </Request>
        </:body>
      </Tab>
    </Tabs>
  </ThemedPage>
</template>
