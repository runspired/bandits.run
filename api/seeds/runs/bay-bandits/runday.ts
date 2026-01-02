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
    date: null
  },
  hosts: ['1'],
  organizers: ['1'],
  runs: [
    {
      name: "Long",
      leaders: [],
      distance: "7-9 Mi",
      vert: "1200-2000ft",
      pace: "Easy to Moderate",
      category: "no-drop",
      meetTime: "18",
      startTime: "18:15",
      eventLink: null,
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
      eventLink: null,
      stravaRouteLink: null,
      gpxLink: null
    },
    {
      name: "Short",
      leaders: [],
      distance: "6-8 Mi",
      vert: "1000-1600ft",
      pace: "Easy to Moderate",
      category: "no-drop",
      meetTime: "18:15",
      startTime: "18:30",
      eventLink: null,
      stravaRouteLink: null,
      gpxLink: null
    }
  ]
} satisfies TrailRun;
