import type { Recurrence, RunOption } from '#app/data/run.ts';

/**
 * Extracts the hostname (domain and TLD) from a URL, removing www subdomain
 */
export function getHostname(url: string): string {
  try {
    const urlObj = new URL(url);
    let hostname = urlObj.hostname;
    // Remove www. subdomain if present
    if (hostname.startsWith('www.')) {
      hostname = hostname.substring(4);
    }
    return hostname;
  } catch {
    // If URL parsing fails, return the original string
    return url;
  }
}

/**
 * Get a human-readable recurrence description
 */
export function getRecurrenceDescription(recurrence: Recurrence): string {
  const days = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  if (recurrence.frequency === 'weekly') {
    const dayName = recurrence.day !== null ? days[recurrence.day] : '';
    if (recurrence.interval === 1) {
      return `Every ${dayName}`;
    }
    return `Every ${recurrence.interval} weeks on ${dayName}`;
  }

  if (
    recurrence.frequency === 'monthly' &&
    recurrence.weekNumber !== null &&
    recurrence.day !== null
  ) {
    const weekOrdinal = ['', 'first', 'second', 'third', 'fourth', 'fifth'][
      recurrence.weekNumber
    ];
    return `${weekOrdinal} ${days[recurrence.day]} of each month`;
  }

  return recurrence.frequency;
}

/**
 * Get a friendly category label
 */
export function getCategoryLabel(category: RunOption['category']): string {
  switch (category) {
    case 'no-drop':
      return 'No-Drop';
    case 'pace-groups':
      return 'Pace Groups';
    case 'at-your-own-pace':
      return 'At Your Own Pace';
    default:
      return category;
  }
}

/**
 * Concatenate multiple strings together
 */
export function concat(...strings: (string | null | undefined)[]): string {
  return strings.filter(Boolean).join('');
}
