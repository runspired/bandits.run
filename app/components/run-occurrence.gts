import './run-occurrence.css';
import { isPastDate, excludeNull } from '#app/utils/helpers.ts';

interface RunOccurrenceSignature {
  Args: {
    date: string | null;
    label?: string;
  };
}

function parseDate(dateStr: string): Date {
  const [year, month, day] = dateStr.split('-').map(Number);
  return new Date(year ?? 2000, (month ?? 1) - 1, day ?? 1);
}

function getMonthShort(date: Date): string {
  return date.toLocaleDateString('en-US', { month: 'short' });
}

function getDay(date: Date): number {
  return date.getDate();
}

const RunOccurrence: TemplateOnlyComponent<RunOccurrenceSignature> = <template>
  {{#if @date}}
    {{#let (excludeNull @date) as |dateStr|}}
      {{#let (parseDate dateStr) as |dateObj|}}
        <div class="next-occurrence {{if (isPastDate @date) 'past'}}">
          <div class="badge-wrapper">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              xmlns:xlink="http://www.w3.org/1999/xlink"
              viewBox="0 0 500 500"
              class="nps-svg"
            >
              <use href="/nps.svg#nps-badge" xlink:href="/nps.svg#nps-badge"></use>
            </svg>
            <div class="date-overlay">
              <div class="date-month">
                {{getMonthShort dateObj}}
              </div>
              <div class="date-day">
                {{getDay dateObj}}
              </div>
            </div>
            <div class="run-label">
              {{#if @label}}
                {{@label}}
              {{else if (isPastDate @date)}}
                Past Run
              {{else}}
                Next Run
              {{/if}}
            </div>
          </div>
          {{#if (isPastDate @date)}}
            <div class="past-date-badge">Past Date</div>
          {{/if}}
        </div>
      {{/let}}
    {{/let}}
  {{/if}}
</template>;

export default RunOccurrence;

import type { TemplateOnlyComponent } from '@ember/component/template-only';
