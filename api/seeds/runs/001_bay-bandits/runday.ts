import type { TrailRun } from "../../../interfaces/run";

export const data = {
  title: 'RUNDAY',
  description: '',
  location: '1',
  recurrence: {
    day: 1,
    frequency: 'weekly',
    interval: 1,
    weekNumber: null,
    "monthNumber": null,
    date: null,
    holiday: null
  },
  hosts: ['1'],
  organizers: ['1'],
  eventLink: null,
  runs: [
    {
      name: "Longer",
      leaders: [],
      distance: "7-9 Mi",
      vert: "1200-2000ft",
      pace: "Easy to Moderate",
      category: "no-drop",
      meetTime: "18",
      startTime: "18:15",
      eventLink: "https://www.strava.com/clubs/504077/group_events/1513300",
      stravaRouteLink: null,
      gpxLink: null
    },
    {
      name: "Social",
      leaders: [],
      distance: "3-5 Mi",
      vert: "600-1000ft",
      pace: "Very Easy",
      category: "no-drop",
      meetTime: "18:15",
      startTime: "18:30",
      eventLink: "https://www.strava.com/clubs/504077/group_events/1449709",
      stravaRouteLink: null,
      gpxLink: null
    },
    {
      name: "Shorter",
      leaders: [],
      distance: "6-8 Mi",
      vert: "1000-1600ft",
      pace: "Easy to Moderate",
      category: "no-drop",
      meetTime: "18:15",
      startTime: "18:30",
      eventLink: "https://www.strava.com/clubs/504077/group_events/1449710",
      stravaRouteLink: null,
      gpxLink: null
    }
  ]
} satisfies TrailRun;
