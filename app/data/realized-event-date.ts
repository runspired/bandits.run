import type { Type } from "@warp-drive/core/types/symbols";
import type { TrailRun } from "./run";
import { withLegacy } from "./-utils";

export interface RealizedEventDate {
  id: string;
  $type: 'realized-event-date';
  date: string;
  weekNumberMonday: number;
  weekNumberSunday: number;
  event: TrailRun
  [Type]: 'realized-event-date';
}

export const RealizedEventDateSchema = withLegacy({
  type: 'realized-event-date',
  fields: [
    { name: 'date', kind: 'field' },
    { name: 'weekNumberMonday', kind: 'field' },
    { name: 'weekNumberSunday', kind: 'field' },
    { name: 'event', kind: 'belongsTo', type: 'trail-run', options: { async: false, inverse: 'occurrences' } },
  ]
})
