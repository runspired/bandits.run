import type { Type } from "@warp-drive/core/types/symbols";
import type { RealizedEventDate } from "./realized-event-date";
import { withDefaults } from "@warp-drive/core/reactive";

export interface Week {
  id: string;
  $type: 'week';
  year: number;
  weekNumber: number;
  startDay: 'sunday' | 'monday';
  startDate: string;
  endDate: string;
  events: RealizedEventDate[];
  [Type]: 'week';
}

export const WeekSchema = withDefaults({
  type: 'week',
  fields: [
    { name: 'year', kind: 'field' },
    { name: 'weekNumber', kind: 'field' },
    { name: 'startDay', kind: 'field' },
    { name: 'startDate', kind: 'field' },
    { name: 'endDate', kind: 'field' },
    { name: 'events', kind: 'hasMany', type: 'realized-event-date', options: { linksMode: true, async: false, inverse: null } },
  ]
});
