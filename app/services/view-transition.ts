import { service } from '@ember/service';
import Service from '@ember/service';
import type Router from '@ember/routing/router-service';
import { tracked } from '@glimmer/tracking';
import type Owner from '@ember/owner';

/**
 * Service to manage View Transitions API for page navigation
 * Provides forward/backward navigation animations
 */
export default class ViewTransitionService extends Service {
  @service declare router: Router;

  @tracked private navigationHistory: string[] = [];
  @tracked private currentIndex = -1;
  private isPopState = false;
  private isProgrammaticTransition = false;


  constructor(owner: Owner) {
    super(owner);

    // Track navigation history
    this.router.on('routeDidChange', () => {
      const currentURL = this.router.currentURL || '/';
      console.log('Route changed to:', currentURL);
      console.log('Is PopState:', this.isPopState);
      console.log('Is Programmatic:', this.isProgrammaticTransition);

      // Only track history for programmatic transitions (not browser back/forward)
      if (!this.isPopState || this.isProgrammaticTransition) {
        this.addToHistory(currentURL);
      }

      this.isPopState = false;
      this.isProgrammaticTransition = false;
    });

    // Listen for browser back/forward
    if (typeof window !== 'undefined') {
      window.addEventListener('popstate', () => {
        this.isPopState = true;
      });
    }
  }

  /**
   * Add a URL to the navigation history
   * Removes any forward history when navigating to a new route
   */
  private addToHistory(url: string): void {
    // Remove any forward history when navigating to a new route
    this.navigationHistory = this.navigationHistory.slice(0, this.currentIndex + 1);
    this.navigationHistory.push(url);
    // eslint-disable-next-line no-self-assign
    this.navigationHistory = this.navigationHistory;
    this.currentIndex = this.navigationHistory.length - 1;
    console.log(this.navigationHistory, this.currentIndex, url);
  }

  /**
   * Determines if the navigation is forward or backward
   */
  private getNavigationDirection(targetURL: string): 'forward' | 'backward' | null {
    const currentURL = this.router.currentURL || '/';

    // Check if going back in history
    const previousIndex = this.navigationHistory.lastIndexOf(targetURL, this.currentIndex - 1);
    if (previousIndex !== -1 && previousIndex < this.currentIndex) {
      return 'backward';
    }

    // Check if going forward in history
    const forwardIndex = this.navigationHistory.indexOf(targetURL, this.currentIndex + 1);
    if (forwardIndex !== -1 && forwardIndex > this.currentIndex) {
      return 'forward';
    }

    // Default to forward for new routes
    if (currentURL !== targetURL) {
      return 'forward';
    }

    return null;
  }

  /**
   * Performs a route transition with View Transition API
   */
  async transitionTo(routeName: string, ...models: unknown[]): Promise<void> {
    // Build the target URL for direction detection
    const targetURL = this.router.urlFor(routeName, ...models);
    const direction = this.getNavigationDirection(targetURL);

    if (!direction || !this.supportsViewTransitions()) {
      // Fallback to regular transition
      this.isProgrammaticTransition = true;
      this.router.transitionTo(routeName, ...models);
      return;
    }

    // Apply direction class to document element
    document.documentElement.classList.add(direction);

    try {
      // Use View Transitions API
      // The callback must be synchronous - just trigger the transition
      if ('startViewTransition' in document) {
        const transition = (document as Document & {
          startViewTransition: (callback: () => void) => { finished: Promise<void> }
        }).startViewTransition(() => {
          // Synchronously trigger the route transition
          this.isProgrammaticTransition = true;
          this.router.transitionTo(routeName, ...models);
        });

        // Wait for the transition to complete
        await transition.finished;
      } else {
        // Fallback if not supported
        this.isProgrammaticTransition = true;
        this.router.transitionTo(routeName, ...models);
      }
    } catch (error) {
      console.error('View transition failed:', error);
    } finally {
      // Clean up direction class
      document.documentElement.classList.remove(direction);
    }
  }

  /**
   * Performs a URL transition with View Transition API
   */
  async transitionToURL(url: string): Promise<void> {
    const direction = this.getNavigationDirection(url);

    if (!direction || !this.supportsViewTransitions()) {
      // Fallback to regular transition
      this.isProgrammaticTransition = true;
      this.router.transitionTo(url);
      return;
    }

    // Apply direction class to document element
    document.documentElement.classList.add(direction);

    try {
      // Use View Transitions API
      // The callback must be synchronous - just trigger the transition
      if ('startViewTransition' in document) {
        const transition = (document as Document & {
          startViewTransition: (callback: () => void) => { finished: Promise<void> }
        }).startViewTransition(() => {
          // Synchronously trigger the route transition
          this.isProgrammaticTransition = true;
          this.router.transitionTo(url);
        });

        // Wait for the transition to complete
        await transition.finished;
      } else {
        // Fallback if not supported
        this.isProgrammaticTransition = true;
        this.router.transitionTo(url);
      }
    } catch (error) {
      console.error('View transition failed:', error);
    } finally {
      // Clean up direction class
      document.documentElement.classList.remove(direction);
    }
  }

  /**
   * Check if browser supports View Transitions API
   */
  private supportsViewTransitions(): boolean {
    if (typeof document === 'undefined') {
      return false;
    }

    return 'startViewTransition' in document;
  }

  /**
   * Manually trigger a view transition with a callback
   */
  async withTransition(
    callback: () => void | Promise<void>,
    direction: 'forward' | 'backward' = 'forward'
  ): Promise<void> {
    if (!this.supportsViewTransitions()) {
      await callback();
      return;
    }

    document.documentElement.classList.add(direction);

    try {
      if ('startViewTransition' in document) {
        const transition = (document as Document & {
          startViewTransition: (callback: () => void | Promise<void>) => { finished: Promise<void> }
        }).startViewTransition(async () => {
          await callback();
        });

        await transition.finished;
      } else {
        await callback();
      }
    } finally {
      document.documentElement.classList.remove(direction);
    }
  }

  /**
   * Navigate back in the history stack
   * Pops the most recent URL from history and transitions to it
   */
  async goBack(): Promise<void> {
    // Need at least 2 items in history (current + previous)
    if (this.navigationHistory.length < 2 || this.currentIndex < 1) {
      // No history to go back to
      return;
    }

    // Get the previous URL
    const previousURL = this.navigationHistory[this.currentIndex - 1];

    // Update the index before navigation
    this.currentIndex--;

    // Apply backward direction class
    document.documentElement.classList.add('backward');

    try {
      if (this.supportsViewTransitions() && 'startViewTransition' in document) {
        const transition = (document as Document & {
          startViewTransition: (callback: () => void) => { finished: Promise<void> }
        }).startViewTransition(() => {
          // Synchronously trigger the route transition
          this.isProgrammaticTransition = true;
          this.router.transitionTo(previousURL);
        });

        await transition.finished;
      } else {
        // Fallback without transitions
        this.isProgrammaticTransition = true;
        this.router.transitionTo(previousURL);
      }
    } catch (error) {
      console.error('View transition failed:', error);
    } finally {
      document.documentElement.classList.remove('backward');
    }
  }

  /**
   * Check if we can navigate back
   */
  get canGoBack(): boolean {
    return this.navigationHistory.length >= 2 && this.currentIndex >= 1;
  }
}
