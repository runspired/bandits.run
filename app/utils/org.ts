import { assert } from "@ember/debug";

/**
 * lookup the slug for an organization ID
 *
 * takes the place of needing an API for query
 * by slug.
 */
export const ORG_LOOKUP_SLUG_TABLE: Record<string, string> = {
  '1': 'bay-bandits',
  '2': 'beer-bucket-runners',
  '3': 'salmon-run-club',
  '4': 'berkeley-run-club',
  '5': 'sfrc',
  '6': 'marin-running-club'
}

/**
 * lookup the organization ID for a slug
 * takes the place of needing an API for query
 * by slug.
 */
export const ORG_LOOKUP_ID_TABLE: Record<string, string> = {
  'bay-bandits': '1',
  'beer-bucket-runners': '2',
  'salmon-run-club': '3',
  'berkeley-run-club': '4',
  'sfrc': '5',
  'marin-running-club': '6'
}

export function getOrgId(slug: string): string {
  assert(`Unknown organization slug: ${slug}`, slug in ORG_LOOKUP_ID_TABLE);
  return ORG_LOOKUP_ID_TABLE[slug]!;
}

export function getOrgSlug(id: string): string {
  assert(`Unknown organization id: ${id}`, id in ORG_LOOKUP_SLUG_TABLE);
  return ORG_LOOKUP_SLUG_TABLE[id]!;
}

export function getRunSlug(runId: string): string {
  const parts = runId.split('-');
  // remove the first part which is the numeric ID
  parts.shift();
  return parts.join('-');
}
