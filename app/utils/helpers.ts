import type { Recurrence, RunOption } from '#app/data/run.ts';
import { assert } from '@ember/debug';


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

export function excludeNull<T>(value: T | null): T {
  assert('Value is not null', value !== null);
  return value;
}

export function eq(a: unknown, b: unknown): boolean {
  return a === b;
}

export function neq(a: unknown, b: unknown): boolean {
  return a !== b;
}

export function and(...args: unknown[]): boolean {
  return args.every(Boolean);
}

export function or(...args: unknown[]): boolean {
  return args.some(Boolean);
}

/**
 * Format a date string as a friendly date
 *
 * E.g., "2024-07-04" -> "Thursday, July 4, 2024"
 */
export function formatFriendlyDate(dateStr: string): string {
  // Parse date as local timezone to avoid off-by-one errors
  const [year, month, day] = dateStr.split('-').map(Number);
  const date = new Date(year ?? 2000, (month ?? 1) - 1, day ?? 1);
  const options: Intl.DateTimeFormatOptions = {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  };
  return date.toLocaleDateString('en-US', options);
}

/**
 * Formats a meet time (HH:MM) into a locale-specific time string
 */
export function formatRunTime(meetTime: string) {
  const date = new Date(`1970-01-01T${meetTime}:00`);
  return date.toLocaleTimeString(undefined, {
    hour: 'numeric',
    minute: meetTime.includes(':') ? '2-digit' : undefined,
  });
}

/**
 * Formats a day number (0-6) into a weekday name
 * in appropriate locale.
 */
export function formatDay(day: 0 | 1 | 2 | 3 | 4 | 5 | 6) {
  const date = new Date();
  // Set to the desired day of the week
  date.setDate(date.getDate() + ((day + 7 - date.getDay()) % 7));
  return date.toLocaleDateString(undefined, { weekday: 'long' });
}

export function getFirstDayOfWeek(): number {
  const pref = globalThis.localStorage.getItem('preferred-first-day-of-week');
  return pref ? parseInt(pref, 10) : 1;
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
 * Format 24hr time to 12hr time
 */
export function formatTime(time24: string): string {
  const [hoursStr, minutesStr] = time24.split(':');
  const hours = Number(hoursStr ?? 0);
  const minutes = Number(minutesStr ?? 0);
  const period = hours >= 12 ? 'PM' : 'AM';
  const hours12 = hours % 12 || 12;
  const minutesFormatted = minutes.toString().padStart(2, '0');
  return `${hours12}:${minutesFormatted} ${period}`;
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
