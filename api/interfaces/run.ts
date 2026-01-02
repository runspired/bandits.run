
export interface TrailRun {
  /**
   * Title of the Trail Run Event
   */
  title: string;
  /**
   * Description of the Trail Run Event
   */
  description: string | null;
  /**
   * ID of the Start location of the Trail Run Event
   */
  location: string;
  /**
   * Recurrence information for the Trail Run Event
   */
  recurrence: Recurrence;
  /**
   * A list of organization IDs that host the run
   */
  hosts: string[];
  /**
   * A list of user IDs that organize the run
   */
  organizers: string[];
  /**
   * A list of runs associated with the event
   */
  runs: RunOption[];
  /**
   * Link to the event page for the entire Trail Run Event (if any).
   *
   * Use this if the entire event shares a single link, use the
   * eventLink field on the RunOption interface if each run option has its own event link.
   */
  eventLink: string | null;
}

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
   * - weekly: occurs every week on the specified day
   * - monthly: occurs once a month on the specified day + week number
   * - annually: occurs once a year on the specified day + week number
   */
  frequency: 'once' | 'annually' | 'weekly' | 'monthly';
  /**
   * For weekly recurrences, the interval in weeks between occurrences (e.g., every 2 weeks).
   * For monthly recurrences, the interval in months between occurrences (e.g., every 3 months for a quarterly run).
   * For annual recurrences, this should always be 1.
   */
  interval: 1 | 2 | 3 | 4 | 5 | 6;
  /**
   * For monthly recurrences, the week number in the month (1 = first week, 2 = second week, etc.)
   * E.G. "2nd Tuesday of every month" would be frequency: 'monthly', day: 2, weekNumber: 2, interval: 1
   */
  weekNumber: 1 | 2 | 3 | 4 | 5 | null;
  /**
   * Specific date for one-time events (YYYY-MM-DD format). Null for recurring events.
   * For recurring annual events on a specific date, this will be the date of the first occurrence.
   */
  date: string | null;
  /**
   * Specialized Floating Dates for annual recurring events on these days. If the event is not
   * on a floating date holiday, this should be null.
   *
   * If the floating date holiday is not in this list, it is not currently supported. A single-use
   * run with the specific date should be created instead.
   */
  holiday: 'July 4th' | 'Thanksgiving Day' | 'Summer Solstice' | 'Winter Solstice' | null;
}


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
   * Link to the route for this run option (if any)
   */
  stravaRouteLink: string | null;
  /**
   * Link to a GPX file for this run option (if any)
   */
  gpxLink: string | null;
}
