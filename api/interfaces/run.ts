
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

export interface JSONAPITrailRun {
  type: 'trail-run';
  id: string;
  attributes: {
    title: string;
    description: string | null;
    recurrence: Recurrence;
    eventLink: string | null;
    runs: RunOption[];
    descriptionHtml: string | null;
  };
  relationships: {
    location: {
      data: { type: 'location', id: string }
    },
    hosts: {
      data: { type: 'organization', id: string }[]
    };
    organizers: {
      data: { type: 'user', id: string }[]
    };
    owner: {
      data: { type: 'organization', id: string }
    },
    occurrences: {
      data: { type: 'realized-event-date', id: string }[]
    }
  };
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

export interface JSONAPIRealizedEventDate {
  type: 'realized-event-date';
  /**
   * The ID of the event + the date for uniqueness
   */
  id: string;
  attributes: {
   /**
    * Specific date for the event occurrence (YYYY-MM-DD format).
    */
    date: string;
   /**
    * Week number when weeks start on Monday (1-53)
    */
    weekNumberMonday: number;
   /**
    * Week number when weeks start on Sunday (1-53)
    */
    weekNumberSunday: number;
  },
  relationships: {
    event: {
      data: { type: 'trail-run', id: string }
    },
  }
}

export interface JSONAPIMonth {
  type: 'month';
  /**
   * The ID is in the format YYYY-MM (e.g., "2024-06" for June 2024)
   */
  id: string;
  attributes: {
    year: number;
    month: number;
  },
  relationships: {
    events: {
      data: { type: 'realized-event-date', id: string }[]
    }
  }
}

export interface JSONAPIWeek {
  type: 'week';
  /**
   * The ID is in the format YYYY-WW-startDay (e.g., "2024-23-sunday" for the week starting Sunday of week 23 in 2024)
   */
  id: string;
  attributes: {
    year: number;
    weekNumber: number;
    startDay: 'sunday' | 'monday';
    startDate: string;
    endDate: string;
  },
  relationships: {
    events: {
      data: { type: 'realized-event-date', id: string }[]
    }
  }
}
