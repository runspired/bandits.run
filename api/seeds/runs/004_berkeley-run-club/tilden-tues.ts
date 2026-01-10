import type { TrailRun } from "../../../interfaces/run";

export const data = {
  title: 'Tilden Tuesday',
  description: '',
  location: '7',
  recurrence: {
    day: 2,
    frequency: 'weekly',
    interval: 1,
    weekNumber: null,
    "monthNumber": null,
    date: null,
    holiday: null
  },
  hosts: ['4'],
  organizers: ['3'],
  eventLink: null,
  runs: [
    {
      name: "Beginner's Run",
      leaders: [],
      distance: "3-4 Mi",
      vert: "300ft",
      pace: "Easy to Moderate",
      category: "no-drop",
      meetTime: "17:55",
      startTime: "18:00",
      eventLink: "https://www.meetup.com/runbrc/events/312483060/",
      stravaRouteLink: null,
      gpxLink: null
    },
    {
      name: "Main Run",
      leaders: [],
      distance: "5-10 Mi",
      vert: "1000-2400ft",
      pace: "Easy to Moderate",
      category: "no-drop",
      meetTime: "18:25",
      startTime: "18:35",
      eventLink: "https://www.meetup.com/runbrc/events/312482933/",
      stravaRouteLink: null,
      gpxLink: null
    }
  ]
} satisfies TrailRun;
