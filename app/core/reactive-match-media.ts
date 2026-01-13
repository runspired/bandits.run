import { trackedObject } from "@ember/reactive/collections";

const MediaQueries: Record<string, boolean> = trackedObject({});
function addMediaQueryListener(query: string): boolean {
  // Initialize on first access
  if (MediaQueries[query] === undefined) {
    const mediaQueryList = window.matchMedia(query);
    MediaQueries[query] = mediaQueryList.matches;

    // Set up the change listener
    const listener = (event: MediaQueryListEvent) => {
      MediaQueries[query] = event.matches;
    };

    mediaQueryList.addEventListener('change', listener);
    return mediaQueryList.matches;
  }
  return MediaQueries[query];
}
/**
 * Decorator which marks a field as being populated via `window.matchMedia`.
 *
 * The field's value will be a boolean indicating whether the media query matches.
 *
 * The field will automatically reactively update when the media query's
 * match status changes.
 *
 * ---
 *
 * **Example:**
 *
 * ```ts
 * class DeviceService {
 *   @matchMedia('(prefers-color-scheme: dark)')
 *   prefersDarkMode: boolean = false;
 * }
 */
export function matchMedia(query: string): PropertyDecorator {
  return function (_target: object, _propertyKey: string | symbol): PropertyDescriptor {

    return {
      configurable: true,
      enumerable: true,
      get(this: object): boolean {
         return addMediaQueryListener(query);
      },
    };
  } as PropertyDecorator;
}
