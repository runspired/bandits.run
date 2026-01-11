import type { Type } from "@warp-drive/core/types/symbols";
import type { RealizedEventDate } from "./realized-event-date";

import { withLegacy } from "./-utils";

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

export const WeekSchema = withLegacy({
  type: 'week',
  fields: [
    { name: 'year', kind: 'field' },
    { name: 'weekNumber', kind: 'field' },
    { name: 'startDay', kind: 'field' },
    { name: 'startDate', kind: 'field' },
    { name: 'endDate', kind: 'field' },
    { name: 'events', kind: 'hasMany', type: 'realized-event-date', options: { async: false, inverse: null } },
  ]
});
