#!/usr/bin/env node

/**
 * Compiles all seed data into organized maps
 *
 * Usage:
 *   node api/compile.ts
 *
 * This script:
 * - Loads all seed data from api/seeds/
 * - Loads markdown descriptions and converts to HTML
 * - Organizes them into maps by ID
 * - Provides a structured data set for further processing
 */

import { readdir, readFile, writeFile, mkdir } from 'fs/promises';
import { join } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import MarkdownIt from 'markdown-it';
import Shiki from '@shikijs/markdown-it';
import anchor from 'markdown-it-anchor';
import attrs from 'markdown-it-attrs';
import container from 'markdown-it-container';
import type { JSONAPIOrganization, Organization } from './interfaces/organization.js';
import type { JSONAPIUser, User } from './interfaces/user.js';
import type { JSONAPILocation, Location } from './interfaces/location.js';
import type { JSONAPIRealizedEventDate, JSONAPITrailRun, TrailRun, JSONAPIMonth, JSONAPIWeek } from './interfaces/run.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

function assert(msg: string, test: unknown): asserts test {
  if (!test) {
    throw new Error(msg);
  }
}

export interface AggregateData {
  organizations: Map<string, Organization & { id: string; descriptionHtml?: string }>;
  users: Map<string, User & { id: string; descriptionHtml?: string }>;
  locations: Map<string, Location & { id: string; descriptionHtml?: string }>;
  runs: Map<string, TrailRun & { id: string; organizationId: string; descriptionHtml?: string }>;
}

/**
 * Initialize markdown-it with VitePress-like plugins
 */
async function createMarkdownProcessor(): Promise<MarkdownIt> {
  const md = MarkdownIt({
    html: true,
    linkify: true,
    typographer: true,
  });

  // Add syntax highlighting with Shiki
  md.use(
    await Shiki({
      themes: {
        light: 'github-light',
        dark: 'github-dark',
      },
    })
  );

  // Add anchor links to headings
  md.use(anchor, {
    permalink: anchor.permalink.linkInsideHeader({
      symbol: '#',
      placement: 'before',
    }),
  });

  // Add attribute support (e.g., {.class #id})
  md.use(attrs);

  // Add custom containers (:::tip, :::warning, etc.)
  const containerTypes = ['tip', 'warning', 'danger', 'info', 'details'];
  containerTypes.forEach((type) => {
    md.use(container as any, type, {
      render(tokens: any[], idx: number) {
        const token = tokens[idx];
        const info = token.info.trim().slice(type.length).trim();
        if (token.nesting === 1) {
          const title = info || type.charAt(0).toUpperCase() + type.slice(1);
          return `<div class="custom-block ${type}"><p class="custom-block-title">${md.utils.escapeHtml(title)}</p>\n`;
        } else {
          return '</div>\n';
        }
      },
    });
  });

  return md;
}

/**
 * Extract ID from filename (e.g., "001_bay-bandits.ts" -> "1")
 */
function extractId(filename: string): string {
  const match = filename.match(/^(\d+)_/);
  if (!match || !match[1]) {
    throw new Error(`Invalid filename format: ${filename}`);
  }
  return String(parseInt(match[1], 10));
}

/**
 * Extract slug from filename
 * For numbered files: "001_bay-bandits.ts" -> "bay-bandits"
 * For non-numbered files: "runday.ts" -> "runday"
 */
function extractSlug(filename: string): string {
  // Try numbered format first
  const numberedMatch = filename.match(/^\d+_(.+)\.ts$/);
  if (numberedMatch && numberedMatch[1]) {
    return numberedMatch[1];
  }

  // Fall back to just removing .ts extension
  const simpleMatch = filename.match(/^(.+)\.ts$/);
  if (simpleMatch && simpleMatch[1]) {
    return simpleMatch[1];
  }

  throw new Error(`Invalid filename format: ${filename}`);
}

/**
 * Extract base name without extension
 * "001_bay-bandits.ts" -> "001_bay-bandits"
 * "runday.ts" -> "runday"
 */
function extractBaseName(filename: string): string {
  return filename.replace(/\.ts$/, '');
}

/**
 * Load markdown file if it exists
 */
async function loadMarkdown(
  dirPath: string,
  baseName: string,
  md: MarkdownIt
): Promise<string | undefined> {
  try {
    const mdPath = join(dirPath, `${baseName}.md`);
    const content = await readFile(mdPath, 'utf-8');
    return md.render(content);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
      return undefined;
    }
    throw error;
  }
}

/**
 * Load all files from a directory with optional markdown descriptions
 */
async function loadDirectory<T>(
  dirPath: string,
  md: MarkdownIt
): Promise<Map<string, T & { id: string; descriptionHtml?: string }>> {
  const map = new Map<string, T & { id: string; descriptionHtml?: string }>();

  try {
    const files = await readdir(dirPath);

    for (const file of files) {
      if (!file.endsWith('.ts')) continue;

      const id = extractId(file);
      const baseName = extractBaseName(file);
      const filePath = join(dirPath, file);

      // Dynamic import to load the module
      const module = await import(filePath);

      if (!module.data) {
        console.warn(`Warning: ${file} does not export 'data'`);
        continue;
      }

      // Load markdown description if it exists
      const descriptionHtml = await loadMarkdown(dirPath, baseName, md);

      map.set(id, {
        ...module.data,
        id,
        ...(descriptionHtml && { descriptionHtml }),
      });
    }
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
      console.warn(`Directory not found: ${dirPath}`);
    } else {
      throw error;
    }
  }

  return map;
}

/**
 * Load all runs (nested by organization) with optional markdown descriptions
 */
async function loadRuns(
  runsDir: string,
  md: MarkdownIt
): Promise<Map<string, TrailRun & { id: string; organizationId: string; descriptionHtml?: string }>> {
  const map = new Map<string, TrailRun & { id: string; organizationId: string; descriptionHtml?: string }>();

  try {
    const orgDirs = await readdir(runsDir);

    for (const orgDir of orgDirs) {
      const orgPath = join(runsDir, orgDir);
      const stat = await import('fs/promises').then(m => m.stat(orgPath));

      if (!stat.isDirectory()) continue;

      const organizationId = extractId(orgDir);
      const files = await readdir(orgPath);

      for (const file of files) {
        if (!file.endsWith('.ts')) continue;

        const slug = extractSlug(file);
        const id = `${organizationId}-${slug}`;
        const baseName = extractBaseName(file);
        const filePath = join(orgPath, file);

        // Dynamic import to load the module
        const module = await import(filePath);

        if (!module.data) {
          console.warn(`Warning: ${file} does not export 'data'`);
          continue;
        }

        // Load markdown description if it exists
        const descriptionHtml = await loadMarkdown(orgPath, baseName, md);

        map.set(id, {
          ...module.data,
          id,
          organizationId,
          ...(descriptionHtml && { descriptionHtml }),
        });
      }
    }
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
      console.warn(`Directory not found: ${runsDir}`);
    } else {
      throw error;
    }
  }

  return map;
}

/**
 * Gather all seed data into structured maps
 */
export async function collect(): Promise<AggregateData> {
  const seedsDir = join(__dirname, 'seeds');

  console.log('🔄 Compiling seed data...\n');
  console.log('⚙️  Initializing markdown processor...');

  // Initialize markdown processor with plugins
  const md = await createMarkdownProcessor();

  console.log('📄 Loading data and markdown files...\n');

  // Load all data in parallel
  const [organizations, users, locations, runs] = await Promise.all([
    loadDirectory<Organization>(join(seedsDir, 'organizations'), md),
    loadDirectory<User>(join(seedsDir, 'users'), md),
    loadDirectory<Location>(join(seedsDir, 'locations'), md),
    loadRuns(join(seedsDir, 'runs'), md),
  ]);

  // Count markdown files
  const orgWithMarkdown = Array.from(organizations.values()).filter(o => o.descriptionHtml).length;
  const usersWithMarkdown = Array.from(users.values()).filter(u => u.descriptionHtml).length;
  const locationsWithMarkdown = Array.from(locations.values()).filter(l => l.descriptionHtml).length;
  const runsWithMarkdown = Array.from(runs.values()).filter(r => r.descriptionHtml).length;

  // Print summary
  console.log('📊 Summary:');
  console.log(`   Organizations: ${organizations.size} (${orgWithMarkdown} with descriptions)`);
  console.log(`   Users:         ${users.size} (${usersWithMarkdown} with descriptions)`);
  console.log(`   Locations:     ${locations.size} (${locationsWithMarkdown} with descriptions)`);
  console.log(`   Runs:          ${runs.size} (${runsWithMarkdown} with descriptions)`);
  console.log('');

  return {
    organizations,
    users,
    locations,
    runs,
  };
}

interface ProcessedResources {
  organizations: Map<string, JSONAPIOrganization>;
  users: Map<string, JSONAPIUser>;
  locations: Map<string, JSONAPILocation>;
  runs: Map<string, JSONAPITrailRun>;
  events: Map<string, JSONAPIRealizedEventDate>;
  months: Map<string, JSONAPIMonth>;
  weeks: Map<string, JSONAPIWeek>;
}


/**
 * compile into json files with the data in json:api format which we place in /public/api
 *
 * each organization and run-overview will have its own json file
 *
 * - organization.json
 * - organization/[id].json
 * - organization/[id]/runs/id.json
 * - weeks/[year]-[weeknumber]-[monday|sunday].json
 * - months/[year]-[monthnumber].json
 *
 * during compilation, we compile into a structure of "weeks" by year + year week number
 * with monday and sunday as start of week variants
 *
 * as well as "months" by year + month number
 */
export async function compile(): Promise<AggregateData> {
  const aggregateData = await collect();
  const { organizations, users, locations, runs } = aggregateData;

  const resources: ProcessedResources = {
    organizations: new Map(),
    users: new Map(),
    locations: new Map(),
    runs: new Map(),
    events: new Map(),
    months: new Map(),
    weeks: new Map(),
  };

  for (const location of locations.values()) {
    transformLocation(location, resources);
  }

  for (const user of users.values()) {
    transformUser(user, resources);
  }

  for (const org of organizations.values()) {
    transformOrganization(org, resources);
  }

  for (const run of runs.values()) {
    transformRun(run, resources);
  }

  // Ensure output directory exists
  const publicApiDir = join(__dirname, '..', 'public', 'api');
  await mkdir(publicApiDir, { recursive: true });

  // Write organization list JSON
  const filePath = join(publicApiDir, 'organization.json');
  const copy = structuredClone(resources);
  await writeJsonApiDocument(filePath, copy.organizations, copy, [
    'contacts',
  ]);

  // construct payloads for /api/organization/[id].json
  await mkdir(join(publicApiDir, 'organization'), { recursive: true });
  console.log(`\n📂 Writing ${resources.organizations.size} organization payloads...\n`);
  for (const [orgId] of resources.organizations) {
    const orgFilePath = join(publicApiDir, 'organization', `${orgId}.json`);
    const copy = structuredClone(resources);
    const orgData = copy.organizations.get(orgId)!;
    await writeJsonApiDocument(orgFilePath, orgData, copy, [
      'contacts',
    ]);
    console.log(`Wrote organization ${orgId}`);
  }

  // construct payloads for /api/organization/[id]/runs.json
  console.log(`\n📂 Writing ${resources.organizations.size} organization runs payloads...\n`)
  for (const [orgId] of resources.organizations) {
    const orgRuns = new Map<string, JSONAPITrailRun>();
    const copy = structuredClone(resources);
    for (const [runId, runData] of copy.runs) {
      if (runData.relationships.owner.data.id === orgId) {
        orgRuns.set(runId, runData);
      }
    }
    const orgRunsFilePath = join(publicApiDir, 'organization', orgId, 'runs.json');
    await mkdir(join(publicApiDir, 'organization', orgId), { recursive: true });
    await writeJsonApiDocument(orgRunsFilePath, orgRuns, copy, [
      'hosts', 'organizers', 'owner', 'occurrences', 'location', 'owner.contacts'
    ]);
    console.log(`Wrote organization ${orgId} runs (${orgRuns.size} runs)`);
  }

  // construct payloads for /api/organization/[id]/runs/[id].json
  for (const [runId] of resources.runs) {
    const copy = structuredClone(resources);
    const runData = copy.runs.get(runId)!;
    await mkdir(join(publicApiDir, 'organization', runData.relationships.owner.data.id, 'runs'), { recursive: true });
    const runFilePath = join(publicApiDir, 'organization', runData.relationships.owner.data.id, 'runs', `${runId}.json`);
    await writeJsonApiDocument(runFilePath, runData, copy, [
      'hosts', 'organizers', 'owner', 'occurrences', 'location', 'owner.contacts'
    ]);
    console.log(`Wrote run ${runId}`);
  }

  // construct payloads for /api/weeks/[year]-[weeknumber]-[monday|sunday].json
  await generateWeekPayloads(publicApiDir, resources);

  // construct payloads for /api/months/[year]-[monthnumber].json
  await generateMonthPayloads(publicApiDir, resources);

  return aggregateData;
}

function transformLocation(
  location: Location & { id: string; descriptionHtml?: string },
  resources: ProcessedResources
): void {
  const locationData: JSONAPILocation = {
    type: 'location',
    id: location.id,
    attributes: {
      name: location.name,
      latitude: location.latitude || null,
      longitude: location.longitude || null,
      region: location.region || null,
      address: location.address || null,
      googleMapsLink: location.googleMapsLink || null,
      descriptionHtml: location.descriptionHtml || null,
    }
  };

  // Store location payload
  resources.locations.set(location.id, locationData);
}

function transformUser(
  user: User & { id: string; descriptionHtml?: string },
  resources: ProcessedResources
): void {
  const userData: JSONAPIUser = {
    type: 'user',
    id: user.id,
    attributes: {
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email || null,
      phoneNumber: user.phoneNumber || null,
      hasWhatsApp: user.hasWhatsApp || null,
      stravaId: user.stravaId || null,
      instagramHandle: user.instagramHandle || null,
      descriptionHtml: user.descriptionHtml || null,
    },
  };

  // Store user payload
  resources.users.set(user.id, userData);
}

function transformOrganization(
  org: Organization & { id: string; descriptionHtml?: string },
  resources: ProcessedResources
): void {
  const orgData: JSONAPIOrganization = {
    type: 'organization',
    id: org.id,
    attributes: {
      name: org.name,
      website: org.website || null,
      stravaId: org.stravaId || null,
      stravaHandle: org.stravaHandle || null,
      meetupId: org.meetupId || null,
      instagramHandle: org.instagramHandle || null,
      email: org.email || null,
      phoneNumber: org.phoneNumber || null,
      descriptionHtml: org.descriptionHtml || null,
    },
    relationships: {
      runs: {
        links: {
          related: `/api/organization/${org.id}/runs.json`,
        },
        meta: {
          count: 0,
        },
      },
      contacts: {
        data: org.contacts.map((userId) => ({ type: 'user', id: userId })),
      },
    },
  };

  // Store organization payloads
  resources.organizations.set(org.id, orgData);
}

function transformRun(
  run: TrailRun & { id: string; organizationId: string; descriptionHtml?: string },
  resources: ProcessedResources
): void {
    const runData: JSONAPITrailRun = {
    type: 'trail-run',
    id: run.id,
    attributes: {
      title: run.title,
      recurrence: run.recurrence,
      runs: run.runs,
      description: run.description || null,
      descriptionHtml: run.descriptionHtml || null,
      eventLink: run.eventLink || null,
    },
    relationships: {
      location: {
        data: { type: 'location', id: run.location },
      },
      hosts: {
        data: run.hosts.map((orgId) => ({ type: 'organization', id: orgId })),
      },
      organizers: {
        data: run.organizers.map((userId) => ({ type: 'user', id: userId })),
      },
      owner: {
        data: { type: 'organization', id: run.organizationId }
      },
      occurrences: {
        data: []
      }
    },
  };
  const orgData = resources.organizations.get(run.organizationId);
  orgData!.relationships.runs.meta.count += 1;

  // calculate occurrences for the next 371 days based on recurrence rules
  calculateRunOccurrences(runData, resources);

  resources.runs.set(run.id, runData);
}

type JSONAPIResource = JSONAPIOrganization | JSONAPIUser | JSONAPILocation | JSONAPITrailRun | JSONAPIRealizedEventDate | JSONAPIMonth | JSONAPIWeek;

/**
 * Get the earliest start time from a run's options
 */
function getEarliestStartTime(run: JSONAPITrailRun): string {
  const times = run.attributes.runs.map(option => option.startTime);
  return times.sort()[0] || '00:00';
}

/**
 * Get week number for a date based on a specific start day of week
 * Week 1 always includes January 1st, even if it's a partial week
 * Week 2 starts on the first occurrence of startDay after January 1st
 *
 * @param date - The date to get the week for
 * @param startDay - Day of week that starts the week (0 = Sunday, 1 = Monday)
 */
function getWeekNumber(date: Date, startDay: 0 | 1): { year: number; week: number } {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);

  const year = d.getFullYear();
  const jan1 = new Date(year, 0, 1);
  const jan1Day = jan1.getDay();

  // Week 1 is the partial or full week containing January 1st
  // Week 2 starts on the first startDay on or after Jan 1

  // If Jan 1 falls on the startDay, Week 1 is a full week
  // Otherwise, Week 1 is a partial week and Week 2 starts on the first startDay
  let week1End: Date;

  if (jan1Day === startDay) {
    // Jan 1 is the startDay, so week 1 runs from Jan 1 through the day before next startDay
    week1End = new Date(year, 0, 1 + 6); // 7 days total
  } else {
    // Jan 1 is not the startDay, so week 1 is partial
    // so we need to find the first occurrence of startDay after Jan 1

    const daysUntilFirstStartDay = (startDay - jan1Day + 7) % 7;

    // Week 1 ends the day before the first occurrence of startDay
    // First startDay occurs on daysUntilFirstStartDay, so day before is (daysUntilFirstStartDay - 1)
    week1End = new Date(year, 0, daysUntilFirstStartDay - 1);
  }

  // Calculate which week this date falls in
  if (d <= week1End) {
    return { year, week: 1 };
  }

  // Week 2 starts the day after week1End
  const week2Start = new Date(week1End);
  week2Start.setDate(week2Start.getDate() + 1);

  // Calculate days since week 2 started
  const daysSinceWeek2Start = Math.floor((d.getTime() - week2Start.getTime()) / (24 * 60 * 60 * 1000));
  const weekNumber = Math.floor(daysSinceWeek2Start / 7) + 2; // +2 for week 1 and current week

  return { year, week: weekNumber };
}

async function generateWeekPayloads(outputDir: string, resources: ProcessedResources): Promise<void> {
  const weeksDir = join(outputDir, 'weeks');
  await mkdir(weeksDir, { recursive: true });

  // sort events by start date + earliest start time
  // Sort events by date, then by earliest start time
  const events = Array.from(resources.events.values());
  events.sort((a, b) => {
    const dateCompare = a.attributes.date.localeCompare(b.attributes.date);
    if (dateCompare !== 0) return dateCompare;

    const runA = resources.runs.get(a.relationships.event.data.id)!;
    const runB = resources.runs.get(b.relationships.event.data.id)!;
    return getEarliestStartTime(runA).localeCompare(getEarliestStartTime(runB));
  });

  // find the first sunday and monday of the current year
  const now = new Date();
  const year = now.getFullYear();
  const firstDayOfYear = new Date(year, 0, 1);
  firstDayOfYear.setHours(0, 0, 0, 0);

  // find first monday
  let firstMonday = new Date(firstDayOfYear);
  let firstMondayWeekNumber = 1;
  while (firstMonday.getDay() !== 1) {
    firstMondayWeekNumber = 2; // if we have to advance, week 1 was partial
    firstMonday.setDate(firstMonday.getDate() + 1);
  }

  // find first sunday
  let firstSunday = new Date(firstDayOfYear);
  let firstSundayWeekNumber = 1;
  while (firstSunday.getDay() !== 0) {
    firstSundayWeekNumber = 2; // if we have to advance, week 1 was partial
    firstSunday.setDate(firstSunday.getDate() + 1);
  }

  console.log(`First Monday of ${year} is ${firstMonday.toDateString()}`);
  console.log(`First Sunday of ${year} is ${firstSunday.toDateString()}`);

  // Calculate the start date (nearest Sunday in the past or today)
  const startDate = new Date();
  startDate.setHours(0, 0, 0, 0);
  const dayOfWeek = startDate.getDay(); // 0 (Sun) to 6 (Sat)
  if (dayOfWeek !== 0) {
    // Go back dayOfWeek days to reach the previous Sunday
    startDate.setTime(startDate.getTime() - (dayOfWeek * 24 * 60 * 60 * 1000));
  }
  console.log(`Start date for week generation is ${startDate.toDateString()}`);

  // get date of first sunday
  const firstSundayOfYear = new Date(year, 0, 1 + ((7 - firstDayOfYear.getDay()) % 7));
  const firstMondayOfYear = new Date(year, 0, 1 + ((8 - firstDayOfYear.getDay()) % 7));

  // get weeks that have elapsed between first sunday and start date
  const daysSinceFirstSunday = Math.floor((startDate.getTime() - firstSundayOfYear.getTime()) / (24 * 60 * 60 * 1000));
  const currentSundayWeekNumber = firstSundayWeekNumber + Math.floor(daysSinceFirstSunday / 7);

  // get weeks that have elapsed between first monday and start date + 1 day
  const firstMondayOfRange = new Date(startDate.getTime() + (1 * 24 * 60 * 60 * 1000));
  const daysSinceFirstMonday = Math.floor((firstMondayOfRange.getTime() - firstMondayOfYear.getTime()) / (24 * 60 * 60 * 1000));
  const currentMondayWeekNumber = firstMondayWeekNumber + Math.floor(daysSinceFirstMonday / 7);

  console.log(`Current Sunday week number is ${currentSundayWeekNumber}`);
  console.log(`Current Monday week number is ${currentMondayWeekNumber}`);

  // prepopulate week numbers for each event
  const sundayWeekMap = new Map<string, JSONAPIRealizedEventDate[]>();
  const mondayWeekMap = new Map<string, JSONAPIRealizedEventDate[]>();

  // 371 days / 7 days per week = 53 weeks + buffer = 54 weeks
  for (let i = 0; i < 371; i++) {
    const elapsedTime = i * 24 * 60 * 60 * 1000;
    const sundayDate = new Date(firstSunday.getTime() + elapsedTime);
    const mondayDate = new Date(firstMonday.getTime() + elapsedTime);

    const sunday = getWeekNumber(sundayDate, 0);
    const monday = getWeekNumber(mondayDate, 1);

    const sundayWeekKey = `${sunday.year}-${String(sunday.week).padStart(2, '0')}`;
    const mondayWeekKey = `${monday.year}-${String(monday.week).padStart(2, '0')}`;

    sundayWeekMap.set(sundayWeekKey, []);
    mondayWeekMap.set(mondayWeekKey, []);
  }

  console.log(`Sunday Weeks: ${Array.from(sundayWeekMap.keys()).join(', ')}`);
  console.log(`Monday Weeks: ${Array.from(mondayWeekMap.keys()).join(', ')}`);

  // Group events by week number for Monday/Sunday-based weeks
  for (const event of events) {
    assert(`Event ${event.id} is missing weekNumberSunday`, event.attributes.weekNumberSunday !== undefined);
    assert(`Event ${event.id} is missing weekNumberMonday`, event.attributes.weekNumberMonday !== undefined);

    const year = new Date(event.attributes.date).getFullYear();
    const sundayKey = `${year}-${String(event.attributes.weekNumberSunday).padStart(2, '0')}`;
    const mondayKey = `${year}-${String(event.attributes.weekNumberMonday).padStart(2, '0')}`;

    // check that the week keys exist
    assert(`Event ${event.id} has unknown weekNumberSunday ${event.attributes.weekNumberSunday}`, sundayWeekMap.has(sundayKey));
    assert(`Event ${event.id} has unknown weekNumberMonday ${event.attributes.weekNumberMonday}`, mondayWeekMap.has(mondayKey));

    sundayWeekMap.get(sundayKey)!.push(event);
    mondayWeekMap.get(mondayKey)!.push(event);
  }

  // Create week resources for Sunday-based weeks
  console.log(`\n📂 Creating ${sundayWeekMap.size} Sunday-based week resources...\n`);
  for (const [weekNum, weekEvents] of sundayWeekMap) {
    // parse year and week number from weekNum (YYYY-WW)
    const [yearStr, weekStr] = weekNum.split('-');
    const year = parseInt(yearStr!, 10);
    const weekNumInt = parseInt(weekStr!, 10);
    const weekId = `${year}-${String(weekNumInt).padStart(2, '0')}-sunday`;

    // Calculate week start and end dates
    const weekStartDate = new Date(firstSunday);
    weekStartDate.setDate(weekStartDate.getDate() + ((weekNumInt - firstSundayWeekNumber) * 7));
    const weekEndDate = new Date(weekStartDate);
    weekEndDate.setDate(weekEndDate.getDate() + 6);

    const weekResource: JSONAPIWeek = {
      type: 'week',
      id: weekId,
      attributes: {
        year,
        weekNumber: weekNumInt,
        startDay: 'sunday',
        startDate: formatDate(weekStartDate),
        endDate: formatDate(weekEndDate),
      },
      relationships: {
        events: {
          data: weekEvents.map(e => ({ type: 'realized-event-date', id: e.id }))
        }
      }
    };

    resources.weeks.set(weekId, weekResource);

    // Write week file
    const sundayFile = join(weeksDir, `${weekId}.json`);
    await writeJsonApiDocument(sundayFile, weekResource, resources, [
      'events.event.hosts',
      'events.event.organizers',
      'events.event.owner',
      'events.event.occurrences',
      'events.event.location',
      'events.event.owner.contacts',
    ]);
    console.log(`Wrote week ${weekId} (${weekEvents.length} events)`);
  }

  // Create week resources for Monday-based weeks
  console.log(`\n📂 Creating ${mondayWeekMap.size} Monday-based week resources...\n`);
  for (const [weekNum, weekEvents] of mondayWeekMap) {
    // parse year and week number from weekNum (YYYY-WW)
    const [yearStr, weekStr] = weekNum.split('-');
    const year = parseInt(yearStr!, 10);
    const weekNumInt = parseInt(weekStr!, 10);
    const weekId = `${year}-${String(weekNumInt).padStart(2, '0')}-monday`;

    // Calculate week start and end dates
    const weekStartDate = new Date(firstMonday);
    weekStartDate.setDate(weekStartDate.getDate() + ((weekNumInt - firstMondayWeekNumber) * 7));
    const weekEndDate = new Date(weekStartDate);
    weekEndDate.setDate(weekEndDate.getDate() + 6);

    const weekResource: JSONAPIWeek = {
      type: 'week',
      id: weekId,
      attributes: {
        year,
        weekNumber: weekNumInt,
        startDay: 'monday',
        startDate: formatDate(weekStartDate),
        endDate: formatDate(weekEndDate),
      },
      relationships: {
        events: {
          data: weekEvents.map(e => ({ type: 'realized-event-date', id: e.id }))
        }
      }
    };

    resources.weeks.set(weekId, weekResource);

    // Write week file
    const mondayFile = join(weeksDir, `${weekId}.json`);
    await writeJsonApiDocument(mondayFile, weekResource, resources, [
        'events.event.hosts',
        'events.event.organizers',
        'events.event.owner',
        'events.event.occurrences',
        'events.event.location',
        'events.event.owner.contacts'
    ]);
    console.log(`Wrote week ${weekId} (${weekEvents.length} events)`);
  }
}

/**
 * Generate monthly payloads for all event dates
 */
async function generateMonthPayloads(
  outputDir: string,
  resources: ProcessedResources
): Promise<void> {
  const monthsDir = join(outputDir, 'months');
  await mkdir(monthsDir, { recursive: true });

  // Group events by year-month
  const eventsByMonth = new Map<string, JSONAPIRealizedEventDate[]>();

  for (const event of resources.events.values()) {
    const eventDate = new Date(event.attributes.date);
    const year = eventDate.getFullYear();
    const month = eventDate.getMonth() + 1; // Convert to 1-12
    const monthKey = `${year}-${String(month).padStart(2, '0')}`;

    if (!eventsByMonth.has(monthKey)) {
      eventsByMonth.set(monthKey, []);
    }
    eventsByMonth.get(monthKey)!.push(event);
  }

  console.log(`\n📂 Creating ${eventsByMonth.size} month resources...\n`);

  // Generate payload for each month
  for (const [monthKey, events] of eventsByMonth) {
    // Sort events by date, then by earliest start time
    events.sort((a, b) => {
      const dateCompare = a.attributes.date.localeCompare(b.attributes.date);
      if (dateCompare !== 0) return dateCompare;

      const runA = resources.runs.get(a.relationships.event.data.id)!;
      const runB = resources.runs.get(b.relationships.event.data.id)!;
      return getEarliestStartTime(runA).localeCompare(getEarliestStartTime(runB));
    });

    // Parse year and month from monthKey (YYYY-MM)
    const [yearStr, monthStr] = monthKey.split('-');
    const year = parseInt(yearStr!, 10);
    const month = parseInt(monthStr!, 10);

    // Create month resource
    const monthResource: JSONAPIMonth = {
      type: 'month',
      id: monthKey,
      attributes: {
        year,
        month,
      },
      relationships: {
        events: {
          data: events.map(e => ({ type: 'realized-event-date', id: e.id }))
        }
      }
    };

    resources.months.set(monthKey, monthResource);

    // Write month file
    const monthFile = join(monthsDir, `${monthKey}.json`);
    await writeJsonApiDocument(
      monthFile,
      monthResource,
      resources,
      [
        'events.event.hosts',
        'events.event.organizers',
        'events.event.owner',
        'events.event.occurrences',
        'events.event.location',
        'events.event.owner.contacts',
      ]
    );

    console.log(`Wrote month ${monthKey} (${events.length} events)`);
  }
}

function mapForType(resources: ProcessedResources, type: string): Map<string, JSONAPIResource> {
  switch (type) {
    case 'organization':
      return resources.organizations;
    case 'user':
      return resources.users;
    case 'location':
      return resources.locations;
    case 'trail-run':
      return resources.runs;
    case 'realized-event-date':
      return resources.events;
    case 'month':
      return resources.months;
    case 'week':
      return resources.weeks;
    default:
      throw new Error(`Unknown resource type: ${type}`);
  }
}

/**
 * a mapping of relationship names to resource types
 */
const schemas = {
  organization: {
    runs: 'trail-run',
    contacts: 'user',
  },
  user: {},
  location: {},
  'trail-run': {
    hosts: 'organization',
    organizers: 'user',
    owner: 'organization',
    occurrences: 'realized-event-date',
  },
  'realized-event-date': {
    event: 'trail-run',
  },
  month: {
    events: 'realized-event-date',
  },
  week: {
    events: 'realized-event-date',
  },
} as Record<string, Record<string, string>>;

function buildIncludesMap(type: string, includes: string[], resources: ProcessedResources, all: Map<string, Set<string>> = new Map()): Map<string, Set<string>> {
  const paths = all.get(type) || new Set<string>();
  all.set(type, paths);

  for (const include of includes) {
    const [level1, ...rest] = include.split('.');
    paths.add(level1!);

    if (rest.length > 0) {
      const relatedType = schemas[type]?.[level1!]!;
      if (!relatedType) {
        throw new Error(`Unknown relationship '${level1}' for resource type '${type}'`);
      }
      buildIncludesMap(relatedType, [rest.join('.')], resources, all);
    }
  }

  return all;
}
/**
 * Recursively collect all related resources for a JSON:API document
 */
function collectIncludedResources(
  primaryData: Set<JSONAPIResource>,
  resources: ProcessedResources,
  includes: string[]
): JSONAPIResource[] {
  const primaryType = primaryData.values().next().value!.type;
  const included = new Set<JSONAPIResource>();
  const paths = buildIncludesMap(primaryType, includes, resources)
  const primaryPaths = paths.get(primaryType)!;

  for (const resource of primaryData) {
    if ('relationships' in resource) {
      for (const [key, payload] of Object.entries(resource.relationships)) {
        if (!primaryPaths.has(key)) {
          if (payload.links) {
            delete payload.data;
          } else {
            // @ts-expect-error
            delete resource.relationships[key];
          }
          continue;
        }
        if (Array.isArray(payload.data)) {
          for (const ref of payload.data) {
            const map = mapForType(resources, ref.type);
            const relatedResource = map.get(ref.id)!;
            if (!primaryData.has(relatedResource) && !included.has(relatedResource)) {
              if (!relatedResource) {
                throw new Error(`Related resource for ${resource.type}:${resource.id} not found: ${ref.type}:${ref.id}`);
              }
              included.add(relatedResource);
            }
          }
        } else if (payload.data) {
          const map = mapForType(resources, payload.data.type);
          const relatedResource = map.get(payload.data.id)!;
          if (!relatedResource) {
            throw new Error(`Related resource for ${resource.type}:${resource.id} not found: ${payload.data.type}:${payload.data.id}`);
          }
          if (!primaryData.has(relatedResource) && !included.has(relatedResource)) {
            included.add(relatedResource);
          }
        }
      }
    }
  }

  for (const resource of included) {
    const includePaths = paths.get(resource.type);
    if ('relationships' in resource) {
      for (const [key, payload] of Object.entries(resource.relationships)) {
        if (!includePaths?.has(key)) {
          if (payload.links) {
            delete payload.data;
          } else {
            // @ts-expect-error
            delete resource.relationships[key];
          }
          continue;
        }
        if (Array.isArray(payload.data)) {
          for (const ref of payload.data) {
            const map = mapForType(resources, ref.type);
            const relatedResource = map.get(ref.id)!;
            if (!primaryData.has(relatedResource) && !included.has(relatedResource)) {
              included.add(relatedResource);
            }
          }
        } else if (payload.data) {
          const map = mapForType(resources, payload.data.type);
          const relatedResource = map.get(payload.data.id)!;
          if (!primaryData.has(relatedResource) && !included.has(relatedResource)) {
            included.add(relatedResource);
          }
        }
      }
    }
  }

  return Array.from(included.values());
}

/**
 * Write a JSON:API document with proper included resources
 */
async function writeJsonApiDocument(
  filePath: string,
  primaryData: Map<string, JSONAPIResource> | JSONAPIResource,
  resources: ProcessedResources,
  includes: string[]
): Promise<void> {
  const included = collectIncludedResources(primaryData instanceof Map ? new Set(primaryData.values()) : new Set([primaryData]), resources, includes);

  const document: {
    data: JSONAPIResource[] | JSONAPIResource;
    included?: JSONAPIResource[];
  } = {
    data: primaryData instanceof Map ? Array.from(primaryData.values()) : primaryData ,
  };

  if (included.length > 0) {
    document.included = included;
  }

  await writeFile(filePath, JSON.stringify(document, null, 2), 'utf-8');
  console.log(`✅ Written: ${filePath}`);
}

function calculateRunOccurrences(
  runData: JSONAPITrailRun,
  resources: ProcessedResources
): void {
  const recurrence = runData.attributes.recurrence;

  // Get the nearest Sunday in the past (or today if today is Sunday)
  const today = new Date();
  today.setHours(0, 0, 0, 0); // Normalize to midnight first

  const dayOfWeek = today.getDay(); // 0 = Sunday, 1 = Monday, ..., 6 = Saturday

  // Calculate the start date (nearest Sunday in the past or today)
  const startDate = new Date(today);
  if (dayOfWeek !== 0) {
    // Go back dayOfWeek days to reach the previous Sunday
    startDate.setTime(today.getTime() - (dayOfWeek * 24 * 60 * 60 * 1000));
  }

  // Calculate end date (371 days from start)
  const endDate = new Date(startDate.getTime() + (371 * 24 * 60 * 60 * 1000));

  const occurrences: string[] = [];

  // Handle different recurrence types
  if (recurrence.frequency === 'once') {
    assert(`Recurrence of type 'once' must have a date`, recurrence.date);

    // we ignore the occurrence if the date is out of range
    const eventDate = new Date(recurrence.date);
    if (eventDate >= startDate && eventDate < endDate) {
      const eventId = createEventOccurrence(runData.id, recurrence.date, resources);
      occurrences.push(eventId);
    }

  } else if (recurrence.frequency === 'weekly') {
    assert(`Recurrence of type 'weekly' must have a day`, recurrence.day !== null);

    const targetDay = recurrence.day;
    const interval = recurrence.interval;

    // For intervals > 1, we need a start date to establish the pattern
    if (interval > 1) {
      assert(`Recurrence of type 'weekly' with interval > 1 must have a date`, recurrence.date);
    }

    let currentDate: Date;

    if (recurrence.date) {
      // Start from the specified first occurrence date
      currentDate = new Date(recurrence.date);
      currentDate.setHours(0, 0, 0, 0);

      // Verify it matches the expected day of week
      assert(
        `Weekly recurrence date ${recurrence.date} must match day ${targetDay}`,
        currentDate.getDay() === targetDay
      );

      // If the first occurrence is before our startDate, fast-forward to the first occurrence within range
      if (currentDate < startDate) {
        // Calculate how many intervals have passed since the first occurrence
        const daysSinceFirst = Math.floor((startDate.getTime() - currentDate.getTime()) / (24 * 60 * 60 * 1000));
        const weeksSinceFirst = Math.floor(daysSinceFirst / 7);

        // Round up to the next interval boundary
        const intervalsToSkip = Math.ceil(weeksSinceFirst / interval);

        // Fast-forward to that occurrence
        currentDate = new Date(currentDate.getTime() + (intervalsToSkip * interval * 7 * 24 * 60 * 60 * 1000));
      }

      // If the first occurrence is after our endDate, skip this run entirely
      if (currentDate >= endDate) {
        // No occurrences in range
        currentDate = endDate; // This will cause the while loop to not execute
      }
    } else {
      // No specific start date, so find the first occurrence of the target day on or after startDate
      currentDate = new Date(startDate);
      const daysUntilTarget = (targetDay - currentDate.getDay() + 7) % 7;
      currentDate = new Date(currentDate.getTime() + (daysUntilTarget * 24 * 60 * 60 * 1000));
    }

    // Generate occurrences every 'interval' weeks
    while (currentDate < endDate) {
      const dateStr = formatDate(currentDate);
      const eventId = createEventOccurrence(runData.id, dateStr, resources);
      occurrences.push(eventId);

      // Move to next occurrence (interval weeks later)
      currentDate = new Date(currentDate.getTime() + (interval * 7 * 24 * 60 * 60 * 1000));
    }
  } else if (recurrence.frequency === 'monthly') {
    assert(`Recurrence of type 'monthly' must have a day`, recurrence.day !== null);
    assert(`Recurrence of type 'monthly' must have a weekNumber`, recurrence.weekNumber !== null);

    const targetDay = recurrence.day;
    const weekNumber = recurrence.weekNumber;
    const interval = recurrence.interval;

    // For intervals > 1, we need a start date to establish the pattern
    if (interval > 1) {
      assert(`Recurrence of type 'monthly' with interval > 1 must have a date`, recurrence.date);
    }

    let currentMonth: Date;

    if (recurrence.date) {
      // Start from the month of the specified first occurrence date
      const firstOccurrence = new Date(recurrence.date);
      firstOccurrence.setHours(0, 0, 0, 0);

      // Verify the date matches the expected pattern
      const expectedDate = getNthWeekdayOfMonth(
        firstOccurrence.getFullYear(),
        firstOccurrence.getMonth(),
        targetDay,
        weekNumber
      );
      assert(
        `Monthly recurrence date ${recurrence.date} must match the ${weekNumber}${getOrdinalSuffix(weekNumber)} ${getDayName(targetDay)} of the month`,
        expectedDate && formatDate(expectedDate) === recurrence.date
      );

      currentMonth = new Date(firstOccurrence.getFullYear(), firstOccurrence.getMonth(), 1);

      // If the first occurrence is before our startDate, fast-forward to the first occurrence within range
      if (firstOccurrence < startDate) {
        const monthsSinceFirst =
          (startDate.getFullYear() - firstOccurrence.getFullYear()) * 12 +
          (startDate.getMonth() - firstOccurrence.getMonth());

        // Round up to the next interval boundary
        const intervalsToSkip = Math.ceil(monthsSinceFirst / interval);

        // Fast-forward to that month
        currentMonth = new Date(firstOccurrence.getFullYear(), firstOccurrence.getMonth() + (intervalsToSkip * interval), 1);
      }
    } else {
      // No specific start date, so start from the current month
      currentMonth = new Date(startDate.getFullYear(), startDate.getMonth(), 1);
    }

    while (currentMonth < endDate) {
      const occurrenceDate = getNthWeekdayOfMonth(
        currentMonth.getFullYear(),
        currentMonth.getMonth(),
        targetDay,
        weekNumber
      );

      if (occurrenceDate && occurrenceDate >= startDate && occurrenceDate < endDate) {
        const dateStr = formatDate(occurrenceDate);
        const eventId = createEventOccurrence(runData.id, dateStr, resources);
        occurrences.push(eventId);
      }

      // Move to next month (interval months later)
      currentMonth.setMonth(currentMonth.getMonth() + interval);
    }
  } else if (recurrence.frequency === 'annually') {
    // Annual recurrence
    if (recurrence.holiday) {
      // Handle floating holidays
      const currentYear = startDate.getFullYear();
      const endYear = endDate.getFullYear();

      for (let year = currentYear; year <= endYear; year++) {
        const holidayDate = getFloatingHolidayDate(year, recurrence.holiday);
        if (holidayDate && holidayDate >= startDate && holidayDate < endDate) {
          const dateStr = formatDate(holidayDate);
          const eventId = createEventOccurrence(runData.id, dateStr, resources);
          occurrences.push(eventId);
        }
      }
    } else if (recurrence.date) {
      // Annual recurrence on a specific date (e.g., same date every year)
      const baseDate = new Date(recurrence.date);
      const currentYear = startDate.getFullYear();
      const endYear = endDate.getFullYear();

      for (let year = currentYear; year <= endYear; year++) {
        const eventDate = new Date(year, baseDate.getMonth(), baseDate.getDate());
        if (eventDate >= startDate && eventDate < endDate) {
          const dateStr = formatDate(eventDate);
          const eventId = createEventOccurrence(runData.id, dateStr, resources);
          occurrences.push(eventId);
        }
      }
    } else if (recurrence.day !== null && recurrence.weekNumber !== null && recurrence.monthNumber !== null) {
      // Annual recurrence on a specific week and day of a specific month
      // (e.g., 3rd Thursday of November every year)
      assert(`Recurrence of type 'annually' with day/weekNumber must have monthNumber`, recurrence.monthNumber !== null);

      const targetMonth = recurrence.monthNumber - 1; // Convert from 1-12 to 0-11
      const targetDay = recurrence.day;
      const weekNumber = recurrence.weekNumber;

      const currentYear = startDate.getFullYear();
      const endYear = endDate.getFullYear();

      for (let year = currentYear; year <= endYear; year++) {
        const occurrenceDate = getNthWeekdayOfMonth(year, targetMonth, targetDay, weekNumber);
        if (occurrenceDate && occurrenceDate >= startDate && occurrenceDate < endDate) {
          const dateStr = formatDate(occurrenceDate);
          const eventId = createEventOccurrence(runData.id, dateStr, resources);
          occurrences.push(eventId);
        }
      }
    } else {
      throw new Error(`Invalid annual recurrence configuration`);
    }
  }

  // Update the run's occurrences relationship
  runData.relationships.occurrences.data = occurrences.map(id => ({
    type: 'realized-event-date',
    id
  }));
}

/**
 * Format a date as YYYY-MM-DD
 */
function formatDate(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/**
 * Get ordinal suffix for a number (1st, 2nd, 3rd, 4th, etc.)
 */
function getOrdinalSuffix(n: number): string {
  const j = n % 10;
  const k = n % 100;
  if (j === 1 && k !== 11) return 'st';
  if (j === 2 && k !== 12) return 'nd';
  if (j === 3 && k !== 13) return 'rd';
  return 'th';
}

/**
 * Get day name from day number
 */
function getDayName(day: number): string {
  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  return days[day] || 'Unknown';
}

/**
 * Create an event occurrence and add it to resources
 */
function createEventOccurrence(
  runId: string,
  dateStr: string,
  resources: ProcessedResources
): string {
  const eventId = `${runId}-${dateStr}`;
  // Parse date string (YYYY-MM-DD) as local time, not UTC
  const parts = dateStr.split('-').map(Number);
  assert(`Invalid date string format: ${dateStr}`, parts.length === 3 && parts.every(n => !isNaN(n)));
  const [year, month, day] = parts;
  const eventDate = new Date(year!, month! - 1, day);

  // Calculate week numbers for both Monday and Sunday start days
  const { week: weekNumberMonday } = getWeekNumber(eventDate, 1);
  const { week: weekNumberSunday } = getWeekNumber(eventDate, 0);

  const eventData: JSONAPIRealizedEventDate = {
    type: 'realized-event-date',
    id: eventId,
    attributes: {
      date: dateStr,
      weekNumberMonday,
      weekNumberSunday,
    },
    relationships: {
      event: {
        data: { type: 'trail-run', id: runId }
      }
    }
  };

  resources.events.set(eventId, eventData);
  return eventId;
}

/**
 * Get the nth occurrence of a weekday in a month
 * @param year - The year
 * @param month - The month (0-11)
 * @param dayOfWeek - Day of week (0 = Sunday, 6 = Saturday)
 * @param weekNumber - Which occurrence (1 = first, 2 = second, etc.)
 */
function getNthWeekdayOfMonth(
  year: number,
  month: number,
  dayOfWeek: number,
  weekNumber: number
): Date | null {
  // Start from the first day of the month
  const firstDay = new Date(year, month, 1);

  // Find the first occurrence of the target weekday
  const firstOccurrence = new Date(firstDay);
  const daysUntilTarget = (dayOfWeek - firstDay.getDay() + 7) % 7;
  firstOccurrence.setDate(1 + daysUntilTarget);

  // Add weeks to get to the nth occurrence
  const nthOccurrence = new Date(firstOccurrence);
  nthOccurrence.setDate(firstOccurrence.getDate() + ((weekNumber - 1) * 7));

  // Verify it's still in the same month
  if (nthOccurrence.getMonth() !== month) {
    return null;
  }

  return nthOccurrence;
}

/**
 * Get the date of a floating holiday for a given year
 */
function getFloatingHolidayDate(year: number, holiday: string): Date | null {
  switch (holiday) {
    case 'Thanksgiving Day':
      // 4th Thursday of November
      return getNthWeekdayOfMonth(year, 10, 4, 4); // November is month 10

    case 'Summer Solstice': {
      // Hard-coded dates for summer solstice (June 20 or 21) for the next 10 years
      const summerSolsticeDates: Record<number, number> = {
        2026: 21, // June 21
        2027: 21, // June 21
        2028: 20, // June 20
        2029: 21, // June 21
        2030: 21, // June 21
        2031: 21, // June 21
        2032: 20, // June 20
        2033: 21, // June 21
        2034: 21, // June 21
        2035: 21, // June 21
        2036: 20, // June 20
      };

      const day = summerSolsticeDates[year];
      return day ? new Date(year, 5, day) : null; // June is month 5
    }

    case 'Winter Solstice': {
      // Hard-coded dates for winter solstice (December 21 or 22) for the next 10 years
      const winterSolsticeDates: Record<number, number> = {
        2026: 21, // December 21
        2027: 21, // December 21
        2028: 21, // December 21
        2029: 21, // December 21
        2030: 21, // December 21
        2031: 22, // December 22
        2032: 21, // December 21
        2033: 21, // December 21
        2034: 21, // December 21
        2035: 22, // December 22
      };

      const day = winterSolsticeDates[year];
      return day ? new Date(year, 11, day) : null; // December is month 11
    }

    default:
      throw new Error(`Unsupported floating holiday: ${holiday}`);
  }
}

/**
 * Pretty print the compiled data
 */
export function printData(data: AggregateData): void {
  console.log('═'.repeat(80));
  console.log('ORGANIZATIONS');
  console.log('═'.repeat(80));
  for (const [id, org] of data.organizations) {
    console.log(`[${id}] ${org.name}`);
    if (org.website) console.log(`    Website: ${org.website}`);
    if (org.stravaId) console.log(`    Strava Club: ${org.stravaId}`);
    if (org.contacts.length > 0) console.log(`    Contacts: ${org.contacts.join(', ')}`);
    if (org.descriptionHtml) console.log(`    ✓ Has description`);
    console.log('');
  }

  console.log('═'.repeat(80));
  console.log('USERS');
  console.log('═'.repeat(80));
  for (const [id, user] of data.users) {
    console.log(`[${id}] ${user.firstName} ${user.lastName}`);
    if (user.email) console.log(`    Email: ${user.email}`);
    if (user.stravaId) console.log(`    Strava: ${user.stravaId}`);
    if (user.descriptionHtml) console.log(`    ✓ Has description`);
    console.log('');
  }

  console.log('═'.repeat(80));
  console.log('LOCATIONS');
  console.log('═'.repeat(80));
  for (const [id, location] of data.locations) {
    console.log(`[${id}] ${location.name}`);
    console.log(`    Region: ${location.region}`);
    console.log(`    Coordinates: ${location.latitude}, ${location.longitude}`);
    if (location.address) {
      console.log(`    Address: ${location.address.street}, ${location.address.city}, ${location.address.state} ${location.address.zip}`);
    }
    if (location.descriptionHtml) console.log(`    ✓ Has description`);
    console.log('');
  }

  console.log('═'.repeat(80));
  console.log('RUNS');
  console.log('═'.repeat(80));
  for (const [id, run] of data.runs) {
    const org = data.organizations.get(run.organizationId);
    console.log(`[${id}] ${run.title}`);
    console.log(`    Organization: ${org?.name || run.organizationId}`);
    const location = data.locations.get(run.location);
    console.log(`    Location: ${location?.name || run.location}`);
    console.log(`    Recurrence: ${run.recurrence.frequency} on day ${run.recurrence.day}`);
    console.log(`    Run Options: ${run.runs.length}`);
    run.runs.forEach((option, idx) => {
      const name = option.name || run.title;
      console.log(`      ${idx + 1}. ${name} - ${option.distance}, ${option.vert}`);
    });
    if (run.descriptionHtml) console.log(`    ✓ Has description`);
    console.log('');
  }
}

// Run if executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  compile()
    .then((data) => {
      console.log('✅ Compilation complete!\n');

      // Print data if requested
      if (process.argv.includes('--print')) {
        printData(data);
      }
    })
    .catch((error) => {
      console.error('❌ Compilation failed:', error);
      process.exit(1);
    });
}
