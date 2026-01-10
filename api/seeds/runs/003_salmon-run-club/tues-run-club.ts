import type { TrailRun } from "../../../interfaces/run";

export const data = {
  title: 'Tuesday 🐠',
  description: '',
  location: '1',
  recurrence: {
    day: 2,
    frequency: 'weekly',
    interval: 1,
    weekNumber: null,
    "monthNumber": null,
    date: null,
    holiday: null
  },
  hosts: ['3'],
  organizers: ['4'],
  eventLink: "https://www.strava.com/clubs/963747/group_events/3415801823546428632",
  runs: [
    {
      name: "",
      leaders: [],
      distance: "6-8 Mi",
      vert: "1000-1600ft",
      pace: "Easy to Moderate",
      category: "no-drop",
      meetTime: "18:30",
      startTime: "18:35",
      eventLink: null,
      stravaRouteLink: null,
      gpxLink: null
    }
  ]
} satisfies TrailRun;
