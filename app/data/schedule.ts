import { withDefaults } from "@warp-drive/core/reactive";

export interface ScheduleDay {
  day: 0 | 1 | 2 | 3 | 4 | 5 | 6;
  events: TrailRunEvent[];
}

export interface TrailRunEvent {
  title: string;
  hosts: Organization[];
  organizers: Organizer[];
  runs: RunOption[];
  location: RunLocation;
  description?: string;
  recurrence: {
    frequency: 'weekly' | 'monthly';
    interval: number;
    unit: 'weeks' | 'months';
    weekNumber: number | null;
  }
}

export interface RunLocation {
  name: string;
  address: string | null;
  link: string | null;
}

export interface Organization {
  name: string;
  link: string | null;
}

export interface Organizer {
  name: string;
}

export interface RunOption {
  name: string;
  leaders: Organizer[];
  distance: string;
  pace: string | null;
  category: "no-drop" | "pace-groups" | "at-your-own-pace";
  meetTime: string;
  startTime: string;
  eventLink: string | null;
  routeLink: string | null;
}

export const ScheduleDaySchema = withDefaults({
  type: 'schedule-day',
  fields: [
    { name: 'day', kind: 'field' },
    { name: 'events', kind: 'field' }
  ]
})
