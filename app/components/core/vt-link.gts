import Component from '@glimmer/component';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import type ViewTransitionService from '#app/services/view-transition.ts';
import type RouterService from '@ember/routing/router-service';

interface VtLinkSignature {
  Element: HTMLAnchorElement;
  Args: {
    route: string;
    model?: unknown;
    models?: unknown[];
    query?: Record<string, unknown>;
    disabled?: boolean;
  };
  Blocks: {
    default: [];
  };
}

/**
 * View Transition Link Component
 * A link component that uses the View Transitions API for smooth page transitions
 *
 * Usage:
 *   <VtLink @route="organizations.single" @model={{org.id}}>
 *     {{org.name}}
 *   </VtLink>
 */
export default class VtLink extends Component<VtLinkSignature> {
  @service('view-transition') declare viewTransition: ViewTransitionService;
  @service declare router: RouterService;

  get href(): string {
    const { route, models, model, query } = this.args;
    const routeModels = models || (model ? [model] : []);

    try {
      // Generate URL for the route
      return this.router.urlFor(route, ...routeModels, {
        queryParams: query || {},
      });
    } catch {
      return '#';
    }
  }

  get isActive(): boolean {
    const { route } = this.args;
    return this.router.isActive(route);
  }

  handleClick = (event: MouseEvent) => {
    // Allow default behavior if disabled
    if (this.args.disabled) {
      event.preventDefault();
      return;
    }

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

    // Prevent default navigation
    event.preventDefault();

    const { route, models, model } = this.args;
    const routeModels = models || (model ? [model] : []);

    // Use view transition service
    void this.viewTransition.transitionTo(route, ...routeModels);
  };

  <template>
    <a
      href={{this.href}}
      role="link"
      class="{{if @disabled 'disabled'}} {{if this.isActive 'active'}}"
      aria-disabled={{if @disabled "true"}}
      aria-current={{if this.isActive "page"}}
      {{on "click" this.handleClick}}
      ...attributes
    >
      {{yield}}
    </a>
  </template>
}
