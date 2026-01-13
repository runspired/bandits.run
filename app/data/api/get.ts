import type { Organization } from '#app/data/organization.ts';
import type { TrailRun } from '#app/data/run.ts';
import type { Location } from '#app/data/location.ts';

import { withReactiveResponse } from '@warp-drive/core/request';
import type { Week } from '../week';
import { getToday, getNextWeek as nextWeek } from '#app/utils/helpers.ts';

/**
 * Builds a request to fetch all organizations.
 */
export function getOrganizations() {
  return withReactiveResponse<Organization[]>({
    url: '/api/organization.json',
    method: 'GET',
  });
}

/**
 * Builds a request to fetch a single organization by ID.
 */
export function getOrganization(organization: string) {
  return withReactiveResponse<Organization>({
    url: `/api/organization/${organization}.json`,
    method: 'GET',
  });
}

/**
 * Builds a request to fetch all runs for a given organization by organization ID.
 */
export function getOrganizationRuns(organization: string) {
  return withReactiveResponse<TrailRun[]>({
    url: `/api/organization/${organization}/runs.json`,
    method: 'GET',
  });
}

/**
 * Builds a request to fetch a single run for a given organization
 * by organization ID and run ID.
 */
export function getOrganizationRun(organization: string, run: string) {
  return withReactiveResponse<TrailRun[]>({
    url: `/api/organization/${organization}/runs/${run}.json`,
    method: 'GET',
  });
}

/**
 * Builds a request to fetch a location by its ID.
 */
export function getLocation(locationId: string) {
  return withReactiveResponse<Location>({
    url: `/api/location/${locationId}.json`,
    method: 'GET',
  } as const);
}

/**
 * Builds a request to fetch the run data for a given week of the year.
 *
 * The week number is based on the week starting day:
 * - 'monday': weeks start on Monday ('default')
 * - 'sunday': weeks start on Sunday
 *
 * January 1st is always in week 1 (which may be a partial week).
 * The first full week starts on the first occurrence of the specified day.
 *
 * @param year - the year in YYYY format
 * @param weekNo - the week number, where week 1 is the week starting Jan 1st
 * @param day - either 'monday' or 'sunday' to indicate the starting day of the week
 */
export function getWeek(year: number, weekNo: number, day: 'monday' | 'sunday' = 'monday') {
  return withReactiveResponse<Week>({
    url: `/api/weeks/${year}-${String(weekNo).padStart(2, '0')}-${day}.json`,
    method: 'GET',
    priority: 'high',
    credentials: 'include',
    mode: 'cors'
  } as const);
}

/**
 * Builds a request to fetch the run data for the current week.
 *
 * Reactively uses the preferred first day of the week and
 * the current clock time.
 */
export function getCurrentWeek() {
  const { year, weekNo, day } = getToday();
  return getWeek(year, weekNo, day);
}

/**
 * Builds a request to fetch the run data for the week after the current week.
 *
 * Reactively uses the preferred first day of the week and
 * the current clock time.
 */
export function getNextWeek() {
  const { year, weekNo, day } = nextWeek();
  return getWeek(year, weekNo, day);
}
