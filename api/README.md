# API Data Management

This directory contains the data models, seed data, and compilation scripts for the bandits.run application.

## Directory Structure

```
api/
├── interfaces/          # TypeScript interfaces for data models
│   ├── location.ts     # Location data model
│   ├── organization.ts # Organization data model
│   ├── run.ts          # TrailRun and RunOption data models
│   └── user.ts         # User data model
├── seeds/              # Seed data files
│   ├── locations/      # Location seed files (numbered)
│   ├── organizations/  # Organization seed files (numbered)
│   ├── runs/           # Run seed files (organized by organization)
│   │   ├── 001_bay-bandits/
│   │   ├── 002_beer-bucket-runners/
│   │   └── ...
│   └── users/          # User seed files (numbered)
└── compile.ts          # Script to compile all seed data
```

## Seed Data Format

### Numbered Files (Organizations, Users, Locations)

Files follow the format: `NNN_slug.ts` where:
- `NNN` is a zero-padded number (e.g., `001`, `002`, `015`)
- The number becomes the entity's ID
- `slug` is a descriptive identifier

Example: `001_bay-bandits.ts` → ID: `"1"`

```typescript
import type { Organization } from "../../interfaces/organization";

export const data = {
  name: "Bay Bandits",
  contacts: ["1"],
  website: "https://bandits.run",
  stravaId: "504077",
  // ...
} satisfies Organization;
```

### Markdown Descriptions (Optional)

Each entity can have an optional markdown description file alongside its TypeScript data file:

- **Organizations**: `001_bay-bandits.md`
- **Users**: `001_chris-thoburn.md`
- **Locations**: `001_skyline-gate.md`
- **Runs**: `runday.md` (in organization subdirectory)

The markdown file should have the same base name as the TypeScript file but with a `.md` extension.

**Markdown Features** (VitePress-inspired):
- Standard markdown syntax
- Syntax highlighting with Shiki (light/dark themes)
- Heading anchor links
- Custom containers: `:::tip`, `:::warning`, `:::danger`, `:::info`, `:::details`
- Tables, lists, blockquotes
- HTML attributes with `{.class #id}` syntax

**Example markdown** (`organizations/001_bay-bandits.md`):

```markdown
# About Bay Bandits

The Bay Bandits is a **trail running community** based in the SF Bay Area.

:::tip No-Drop Policy
All our runs follow a no-drop policy!
:::

## Weekly Runs

We offer runs for all fitness levels:

| Day | Distance | Difficulty |
|-----|----------|-----------|
| Monday | 6-9 mi | Moderate |
| Thursday | 6-8 mi | Easy |
```

The markdown is compiled to HTML during the build process and included in the `descriptionHtml` field.

### Run Files (Nested by Organization)

Run files are organized in subdirectories by organization:
- Directory name format: `NNN_organization-slug/`
- File name format: `run-slug.ts` (no number prefix)
- Run ID format: `{organizationId}-{run-slug}`

Example: `001_bay-bandits/runday.ts` → ID: `"1-runday"`

```typescript
import type { TrailRun } from "../../../interfaces/run";

export const data = {
  title: 'RUNDAY',
  description: '',
  location: '1',
  recurrence: {
    day: 1,
    frequency: 'weekly',
    interval: 1,
    // ...
  },
  hosts: ['1'],
  organizers: ['1'],
  runs: [
    // RunOption objects
  ]
} satisfies TrailRun;
```

## Compiling Seed Data

The `compile.ts` script loads all seed data and organizes it into TypeScript Maps for easy access.

### Usage

**Basic compilation (summary only):**
```bash
pnpm api:compile
```

**Compilation with detailed output:**
```bash
pnpm api:compile --print
```

### Output

The compile script returns a `CompiledData` object:

```typescript
interface CompiledData {
  organizations: Map<string, Organization & { id: string; descriptionHtml?: string }>;
  users: Map<string, User & { id: string; descriptionHtml?: string }>;
  locations: Map<string, Location & { id: string; descriptionHtml?: string }>;
  runs: Map<string, TrailRun & { id: string; organizationId: string; descriptionHtml?: string }>;
}
```

Each entity includes:
- All original data from the seed file
- An `id` field (derived from filename)
- An optional `descriptionHtml` field (compiled from markdown file if present)
- For runs: an additional `organizationId` field

### Using in Code

You can import and use the compile function in your own scripts:

```typescript
import { compile } from './api/compile.ts';

const data = await compile();

// Access data
const bayBandits = data.organizations.get('1');
const skylineGate = data.locations.get('1');
const runday = data.runs.get('1-runday');

// Iterate over all runs
for (const [id, run] of data.runs) {
  const org = data.organizations.get(run.organizationId);
  const location = data.locations.get(run.location);
  console.log(`${run.title} hosted by ${org?.name} at ${location?.name}`);
}
```

## ID References

Throughout the seed data, entities reference each other by ID:

- **User IDs**: Numeric strings (`"1"`, `"2"`, etc.)
- **Organization IDs**: Numeric strings (`"1"`, `"2"`, etc.)
- **Location IDs**: Numeric strings (`"1"`, `"2"`, etc.)
- **Run IDs**: `"{orgId}-{slug}"` format (`"1-runday"`, `"2-thursday-run"`, etc.)

### Examples

```typescript
// A run references a location and organization
{
  location: '1',          // → Skyline Gate
  hosts: ['1'],           // → Bay Bandits
  organizers: ['1', '2'], // → Chris Thoburn, Karen Barnes
}

// An organization references users
{
  contacts: ['1', '2'],   // → Chris Thoburn, Karen Barnes
}
```

## Adding New Data

### Adding a New Organization

1. Create a new file in `api/seeds/organizations/`
2. Use the next available number (e.g., `006_new-org.ts`)
3. Export data that satisfies the `Organization` interface

### Adding a New Run

1. Find or create the organization directory in `api/seeds/runs/`
2. Create a new `.ts` file with a descriptive slug (e.g., `monday-social.ts`)
3. Export data that satisfies the `TrailRun` interface
4. The run's ID will be `{orgId}-{slug}` (e.g., `"1-monday-social"`)

### Adding a New Location or User

Same process as organizations - create a numbered file in the appropriate directory.

## Notes

- All TypeScript files must export a `data` constant
- The `data` must satisfy the corresponding interface type
- IDs are automatically generated from filenames
- The compile script validates and loads all data at once
- Missing files or malformed data will produce warnings but won't stop compilation
