import type { Type } from "@warp-drive/core/types/symbols";
import type { RealizedEventDate } from "./realized-event-date";
import { withDefaults } from "@warp-drive/legacy/model/migration-support";

export interface Month {
  id: string;
  $type: 'month';
  year: number;
  month: number;
  events: RealizedEventDate[];
  [Type]: 'month';
}

export const MonthSchema = withDefaults({
  type: 'month',
  fields: [
    { name: 'year', kind: 'field' },
    { name: 'month', kind: 'field' },
    { name: 'events', kind: 'hasMany', type: 'realized-event-date', options: { linksMode: true, async: false, inverse: null } },
  ]
});
