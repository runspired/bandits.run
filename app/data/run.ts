import { Type } from "@warp-drive/core/types/symbols";
import { objectSchema } from "@warp-drive/core/types/schema/fields";
import type { Location } from "./location";
import type { Organization } from "./organization";
import type { User } from "./user";
import type { RealizedEventDate } from "./realized-event-date";
import { withLegacy } from "./-utils";
import { MapState } from "#app/components/maps/-utils/map-state.ts";

export interface TrailRun {
  id: string;
  $type: 'trail-run';
  title: string;
  description: string | null;
  recurrence: Recurrence;
  eventLink: string | null;
  stravaEventLink: string | null;
  meetupEventLink: string | null;
  runs: RunOption[];
  descriptionHtml: string | null;
  location: Location;
  hosts: Organization[];
  organizers: User[];
  owner: Organization;
  occurrences: RealizedEventDate[];
  nextOccurrence: string | null;
  mapState: MapState;
  [Type]: 'trail-run';
}

export const TrailRunSchema = withLegacy({
  type: 'trail-run',
  fields: [
    { name: 'title', kind: 'field' },
    { name: 'description', kind: 'field' },
    { name: 'descriptionHtml', kind: 'field' },
    { name: 'recurrence', kind: 'schema-object', type: 'recurrence' },
    { name: 'eventLink', kind: 'field' },
    { name: 'stravaEventLink', kind: 'field' },
    { name: 'meetupEventLink', kind: 'field' },
    { name: 'runs', kind: 'schema-array', type: 'run-option' },
    { name: 'descriptionHtml', kind: 'field' },
    { name: 'location', kind: 'belongsTo', type: 'location', options: { async: false, inverse: null } },
    { name: 'hosts', kind: 'hasMany', type: 'organization', options: { async: false, inverse: null} },
    { name: 'organizers', kind: 'hasMany', type: 'user', options: { async: false, inverse: null } },
    { name: 'owner', kind: 'belongsTo', type: 'organization', options: { async: false, inverse: 'runs' } },
    { name: 'occurrences', kind: 'hasMany', type: 'realized-event-date', options: { async: false, inverse: 'event' } },
    { name: 'nextOccurrence', kind: 'derived', type: 'next-occurrence-finder' },
    { name: 'mapState', kind: 'derived', type: 'map-state' }
  ]
});

export interface Recurrence {
  /**
   * Day of the week the run occurs on (0 = Sunday, 6 = Saturday)
   *
   * Should only be null for recurring annual events on specific dates
   * or floating date holidays.
   */
  day: 0 | 1 | 2 | 3 | 4 | 5 | 6 | null;
  /**
   * Frequency of the recurrence
   *
   * - once: occurs only once on the specified date
   * - weekly: occurs every week on the specified day
   * - monthly: occurs once a month on the specified day + week number
   * - annually: occurs once a year on the specified day + week number
   */
  frequency: 'once' | 'annually' | 'weekly' | 'monthly';
  /**
   * For weekly recurrences, the interval in weeks between occurrences (e.g., every 2 weeks).
   * For monthly recurrences, the interval in months between occurrences (e.g., every 3 months for a quarterly run).
   * For annual recurrences, this should always be 1.
   *
   * For weekly and monthly recurrences, a start date must be set
   * to determine the first occurrence if the interval is greater than 1.
   */
  interval: 1 | 2 | 3 | 4 | 5 | 6;
  /**
   * For monthly recurrences, the week number in the month (1 = first week, 2 = second week, etc.)
   * E.G. "2nd Tuesday of every month" would be frequency: 'monthly', day: 2, weekNumber: 2, interval: 1
   */
  weekNumber: 1 | 2 | 3 | 4 | 5 | null;
  /**
   * For Annual recurrences, the month of the year (1 = January, 12 = December)
   * E.G. "3rd Thursday of November every year" would be frequency: 'annually', day: 4, weekNumber: 3, month: 11
   */
  monthNumber: 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | null;
  /**
   * Specific date for one-time events (YYYY-MM-DD format). Null for recurring events.
   * For recurring annual events on a specific date, this will be the date of the first occurrence.
   *
   * For recurring weekly or monthly events with an interval greater than 1, this will be the date
   * of the first occurrence.
   */
  date: string | null;
  /**
   * Specialized Floating Dates for annual recurring events on these days. If the event is not
   * on a floating date holiday, this should be null.
   *
   * If the floating date holiday is not in this list, it is not currently supported. A single-use
   * run with the specific date should be created instead.
   */
  holiday: 'Thanksgiving Day' | 'Summer Solstice' | 'Winter Solstice' | null;
}

export const RecurrenceObjectSchema = objectSchema({
  type: 'recurrence',
  identity: null,
  fields: [
    { name: 'day', kind: 'field' },
    { name: 'frequency', kind: 'field' },
    { name: 'interval', kind: 'field' },
    { name: 'weekNumber', kind: 'field' },
    { name: 'monthNumber', kind: 'field' },
    { name: 'date', kind: 'field' },
    { name: 'holiday', kind: 'field' },
  ]
});


export interface RunOption {
  /**
   * If the event has only a single run option, this should
   * be `null` as the event title will be the run's name.
   */
  name: string | null;
  /**
   * A list of users who lead this run option. If the event
   * has only a single run option, this should be empty as
   * the organizers will be considered the leaders.
   */
  leaders: string[];
  /**
   * Rough distance of the run option. This can be a range.
   * For instance "6-8 Mi"
   */
  distance: string;
  /**
   * Rough vertical gain of the run option. This can be a range.
   *
   * For instance 800-1200ft
   */
  vert: string;
  /**
   * A description of the pace for this run option.
   * Can be either a string description like "Moderate"
   * or a target pace like "9:00/Mi GAP"
   */
  pace: string | null;
  /**
   * Category of the run option
   *
   * - no-drop: everyone stays together or waits at key points
   * - pace-groups: runners are grouped by pace, but all start together
   * - at-your-own-pace: runners start and run or self-organize at their own pace
   */
  category: "no-drop" | "pace-groups" | "at-your-own-pace";
  /**
   * Time to meet before the run starts (in 24h format, e.g., "18:15" for 6:15 PM)
   */
  meetTime: string;
  /**
   * Time the run actually starts (in 24h format, e.g., "18:30" for 6:30 PM)
   */
  startTime: string;
  /**
   * Link to the event page for this run option (if any).
   *
   * Use this if each run option has its own event link, use the
   * eventLink field on the TrailRun interface if the entire event shares a single link.
   */
  eventLink: string | null;
  /**
   * Link to the Strava event for this run option (if any)
   */
  stravaEventLink: string | null;
  /**
   * Link to the Meetup event for this run option (if any)
   */
  meetupEventLink: string | null;
  /**
   * Link to the route for this run option (if any)
   */
  stravaRouteLink: string | null;
  /**
   * Link to a GPX file for this run option (if any)
   */
  gpxLink: string | null;
}

export const RunOptionObjectSchema = objectSchema({
  type: 'run-option',
  identity: null,
  fields: [
    { name: 'name', kind: 'field' },
    { name: 'leaders', kind: 'field' },
    { name: 'distance', kind: 'field' },
    { name: 'vert', kind: 'field' },
    { name: 'pace', kind: 'field' },
    { name: 'category', kind: 'field' },
    { name: 'meetTime', kind: 'field' },
    { name: 'startTime', kind: 'field' },
    { name: 'eventLink', kind: 'field' },
    { name: 'stravaEventLink', kind: 'field' },
    { name: 'meetupEventLink', kind: 'field' },
    { name: 'stravaRouteLink', kind: 'field' },
    { name: 'gpxLink', kind: 'field' },
  ]
});


/**
 * Get the next occurrence date for a run
 */
function getNextOccurrence(record: unknown): string | null {
  const run = record as TrailRun;
  if (!run.occurrences || run.occurrences.length === 0) {
    return null;
  }

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const futureOccurrences = run.occurrences
    .map((occ) => {
      // Parse date as local timezone
      const [year, month, day] = occ.date.split('-').map(Number);
      return new Date(year ?? 2000, (month ?? 1) - 1, day ?? 1);
    })
    .filter((date) => date >= today)
    .sort((a, b) => a.getTime() - b.getTime());

  const nextDate = futureOccurrences.length > 0 ? futureOccurrences[0]?.toISOString().split('T')[0] : null;
  return nextDate ?? null;
}
getNextOccurrence[Type] = 'next-occurrence-finder';

type MapKeyId = `trail-run:${string}` | `location:${string}`;
const MapStates = new Map<string, MapState>();

/**
 * Get or create a {@link MapState} by its unique {@link MapKeyId} identifier
 *
 */
export function getMapStateById(id: MapKeyId): MapState {
  const existing = MapStates.get(id);
  if (existing) {
    return existing;
  }
  const state = new MapState(id);
  MapStates.set(id, state);
  return state;
}

/**
 * Get MapState for a run
 */
function getMapState(record: unknown): unknown {
  const run = record as TrailRun | Location;
  const location = run.$type === 'trail-run' ? run.location : run;
  const state = getMapStateById(`${run.$type}:${run.id}`);

  state.initialize(location);

  return state;
}
getMapState[Type] = 'map-state';

export { getNextOccurrence, getMapState };
