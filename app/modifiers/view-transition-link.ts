import { registerDestructor } from '@ember/destroyable';
import { service } from '@ember/service';
import Modifier from 'ember-modifier';
import type ViewTransitionService from '../services/view-transition';
import type RouterService from '@ember/routing/router-service';

interface ViewTransitionLinkSignature {
  Element: HTMLAnchorElement;
  Args: {
    Named: {
      route?: string;
      model?: unknown;
      models?: unknown[];
    };
  };
}

/**
 * Modifier that adds View Transition API support to links
 * Usage: <a {{view-transition-link route="some.route" model=someModel}}>Click me</a>
 * Or: <a href="/some/path" {{view-transition-link}}>Click me</a>
 */
export default class ViewTransitionLinkModifier extends Modifier<ViewTransitionLinkSignature> {
  @service('view-transition') declare viewTransition: ViewTransitionService;
  @service declare router: RouterService;

  private element?: HTMLAnchorElement;
  private handleClick?: (event: MouseEvent) => void;

  modify(
    element: HTMLAnchorElement,
    _positional: [],
    named: ViewTransitionLinkSignature['Args']['Named']
  ): void {
    this.element = element;

    // Remove previous event listener if exists
    if (this.handleClick) {
      this.element.removeEventListener('click', this.handleClick);
    }

    // Create new click handler
    this.handleClick = (event: MouseEvent) => {
      // Only handle left clicks without modifier keys
      if (
        event.button !== 0 ||
        event.ctrlKey ||
        event.metaKey ||
        event.shiftKey ||
        event.altKey ||
        event.defaultPrevented
      ) {
        return;
      }

      // Check if target="_blank" or similar
      if (element.target && element.target !== '_self') {
        return;
      }

      // Prevent default navigation
      event.preventDefault();

      // Determine navigation type
      if (named.route) {
        // Named route transition
        const models = named.models || (named.model ? [named.model] : []);
        void this.viewTransition.transitionTo(named.route, ...models);
      } else if (element.href) {
        // URL-based transition
        const url = new URL(element.href);
        const path = url.pathname + url.search + url.hash;
        void this.viewTransition.transitionToURL(path);
      }
    };

    // Add event listener
    this.element.addEventListener('click', this.handleClick);

    // Register cleanup
    registerDestructor(this, () => {
      if (this.element && this.handleClick) {
        this.element.removeEventListener('click', this.handleClick);
      }
    });
  }
}
