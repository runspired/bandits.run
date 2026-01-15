import type { Recurrence, RunOption } from '#app/data/run.ts';

import { clock } from './clock';


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
  const pref = localStorage.getItem('preferred-first-day-of-week');
  return pref ? parseInt(pref, 10) : 1;
}

/**
 * Get the week number for a given date (Monday as first day)
 * January 1st is always in week 1 (which may be a partial week).
 * The first Monday starts week 2, unless January 1st is a Monday.
 */
export function getWeekNumber(date: Date, day: 'monday' | 'sunday' = 'monday'): number {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);

  const year = d.getFullYear();
  const jan1 = new Date(year, 0, 1);
  const jan1Day = jan1.getDay(); // 0 = Sunday, 1 = Monday, etc.

  // Days since Jan 1 (0-indexed)
  const dayOfYear = Math.floor((d.getTime() - jan1.getTime()) / 86400000);

  const firstDayNum = day === 'monday' ? 1 : 0;

  // If Jan 1 is our first day of the week, week 1 starts on Jan 1
  // Otherwise, week 1 is partial and week 2 starts on the first Monday
  if (jan1Day === firstDayNum) {
    // Jan 1 is the first day of the week - standard week calculation
    return Math.floor(dayOfYear / 7) + 1;
  }

  // Days until first StartDay (if Jan 1 is not StartDay)
  // For instance: for days until first Monday (if Jan 1 is Sunday (0), first Monday is 1 day away)
  // If Jan 1 is Tuesday (2), first Monday is 6 days away, etc.
  const daysUntilFirstStartDay = firstDayNum === 0 ? (jan1Day === 0 ? 0 : 7 - jan1Day) : jan1Day === 1 ? 0 : 8 - jan1Day;;

  if (dayOfYear < daysUntilFirstStartDay) {
    // Still in week 1 (partial week before first StartDay)
    return 1;
  }

  // Days since first StartDay, plus 2 (since first StartDay starts week 2)
  return Math.floor((dayOfYear - daysUntilFirstStartDay) / 7) + 2;
}

/**
 * Get today's date, year, and week number
 * with preferred first day of week
 */
export function getToday() {
  return clock.today;
}

/**
 * Get the next week's date, year, and week number
 * with preferred first day of week
 */
export function getNextWeek() {
  return clock.nextWeek;
}

/**
 * Check if today is Thursday (4) or later in the week (Fri=5, Sat=6, Sun=0)
 * Uses Monday as the start of the week
 */
export function weekHasFourDaysRemaining(): boolean {
  return clock.daysRemainingInWeek <= 4;
}

/**
 * Get the day of week name from a date string (e.g., "2024-07-04" -> "Thursday")
 */
export function getDayOfWeek(dateStr: string): string {
  const [year, month, day] = dateStr.split('-').map(Number);
  const date = new Date(year ?? 2000, (month ?? 1) - 1, day ?? 1);
  return date.toLocaleDateString('en-US', { weekday: 'long' });
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

/**
 * Check if a date string (YYYY-MM-DD) is in the past
 */
export function isPastDate(dateStr: string | null | undefined): boolean {
  if (!dateStr) return false;
  const [year, month, day] = dateStr.split('-').map(Number);
  const date = new Date(year ?? 2000, (month ?? 1) - 1, day ?? 1);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return date < today;
}

/**
 * Check if a date string (YYYY-MM-DD) is today
 */
export function isToday(dateStr: string | null | undefined): boolean {
  if (!dateStr) return false;
  const [year, month, day] = dateStr.split('-').map(Number);
  const date = new Date(year ?? 2000, (month ?? 1) - 1, day ?? 1);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return date.getTime() === today.getTime();
}

/**
 * Concatenate multiple strings together
 */
export function concat(...strings: (string | null | undefined)[]): string {
  return strings.filter(Boolean).join('');
}
