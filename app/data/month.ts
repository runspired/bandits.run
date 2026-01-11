import type { Type } from "@warp-drive/core/types/symbols";
import type { RealizedEventDate } from "./realized-event-date";
import { withLegacy } from "./-utils";

export interface Month {
  id: string;
  $type: 'month';
  year: number;
  month: number;
  events: RealizedEventDate[];
  [Type]: 'month';
}

export const MonthSchema = withLegacy({
  type: 'month',
  fields: [
    { name: 'year', kind: 'field' },
    { name: 'month', kind: 'field' },
    { name: 'events', kind: 'hasMany', type: 'realized-event-date', options: { async: false, inverse: null } },
  ]
})
