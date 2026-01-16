import { assert } from '@ember/debug';
import { effect, PersistedResource } from './persisted-resource';
import { matchMedia } from './reactive-match-media';

@PersistedResource('site-theme')
class SiteTheme {
  /**
   * The root HTML element (for applying color-scheme styles)
   * This will typically be document.documentElement or document.body
   */
  #rootElement: HTMLElement;
  constructor(rootElement: HTMLElement) {
    this.#rootElement = rootElement;
    this._syncDOM();
  }

  /**
   * User's theme preference ('light', 'dark', or null for system preference)
   */
  @effect(syncThemeToDOM)
  explicitThemePreference: 'light' | 'dark' | null = null;

  @matchMedia('(prefers-color-scheme: dark)')
  systemPrefersDarkMode: boolean = false;

  get isDarkMode(): boolean {
    if (this.explicitThemePreference === 'dark') {
      return true;
    } else if (this.explicitThemePreference === 'light') {
      return false;
    } else {
      return this.systemPrefersDarkMode;
    }
  }

  /**
   * Computed theme value
   */
  get theme(): 'light' | 'dark' {
    if (this.explicitThemePreference) {
      return this.explicitThemePreference;
    } else {
      return this.systemPrefersDarkMode ? 'dark' : 'light';
    }
  }

  /**
   * Computed color scheme string for CSS use
   */
  get colorScheme(): 'light only' | 'dark only' {
    if (this.theme === 'dark') {
      return 'dark only';
    } else {
      return 'light only';
    }
  }

  /**
   * An action to update the user's explicit theme preference.
   *
   * Pass `null` to revert to system preference.
   */
  updateThemePreference = (theme: 'light' | 'dark' | null): void => {
    this.explicitThemePreference = theme;
    this._syncDOM();
  };

  /**
   * Initialize the SiteTheme, ensuring the root element has the correct
   * color-scheme style applied.
   */
  private _syncDOM() {
    this.#rootElement.style.colorScheme = this.colorScheme;
    this.#rootElement.classList.add(`${this.theme}-mode`);
    this.#rootElement.classList.remove(this.theme === 'dark' ? 'light-mode' : 'dark-mode');

    // also apply to documentElement for global styles
    if (this.#rootElement === document.body) {
      document.documentElement.style.colorScheme = this.colorScheme;
      document.documentElement.classList.add(`${this.theme}-mode`);
      document.documentElement.classList.remove(this.theme === 'dark' ? 'light-mode' : 'dark-mode');
    }
  }
}

let themeInstance: SiteTheme | null = null;
/**
 * Get the {@link SiteTheme} singleton instance.
 *
 */
export function getTheme(): SiteTheme {
  assert('SiteTheme has not been initialized yet', themeInstance);
  return themeInstance;
}

/**
 * Initialize the {@link SiteTheme} singleton instance
 * with the given root HTML element.
 *
 * This must be called before {@link getTheme} is invoked.
 *
 * Defaults to document.body if not provided.
 */
export function initializeTheme(rootElement: HTMLElement = document.body): void {
  assert('SiteTheme has already been initialized', !themeInstance);
  if (!themeInstance) {
    themeInstance = new SiteTheme(rootElement);
  }
}

function syncThemeToDOM(): void {
  console.log('syncThemeToDOM called');
  const theme = getTheme();
  // @ts-expect-error Private method
  theme._syncDOM();
}
