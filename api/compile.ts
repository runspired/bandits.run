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

import { readdir, readFile } from 'fs/promises';
import { join } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import MarkdownIt from 'markdown-it';
import Shiki from '@shikijs/markdown-it';
import anchor from 'markdown-it-anchor';
import attrs from 'markdown-it-attrs';
import container from 'markdown-it-container';
import type { Organization } from './interfaces/organization.js';
import type { User } from './interfaces/user.js';
import type { Location } from './interfaces/location.js';
import type { TrailRun } from './interfaces/run.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

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
 * Main compile function
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

/**
 * compile into json files with the data in json:api format which we place in /public/api
 *
 * each organization and run-overview will have its own json file
 *
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

  for (const [id, org] of organizations) {

  }



  return aggregateData;
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
