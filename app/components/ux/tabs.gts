import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import type { WithBoundArgs } from '@glint/template';
import './tabs.css';
import { assert } from '@ember/debug';

interface SingleTabSignature {
  Args: {
    slug: string;
    register: (tab: Tab) => void;
    isActive: (tab: Tab) => boolean;
  };
  Blocks: {
    body: [];
    title: [boolean];
  };
}
class Tab extends Component<SingleTabSignature> {
  title = document.createElement('div');
  body = document.createElement('div');
  private _ = this.args.register(this);

  get isActive() {
    return this.args.isActive(this);
  }

  <template>
    {{#in-element this.title}}{{yield to="title"}}{{/in-element}}
    {{#if this.isActive}}
      {{#in-element this.body}}{{yield to="body"}}{{/in-element}}
    {{/if}}
  </template>
}

interface TabsSignature {
  Args: {
    activeSlug?: string | null;
    onTabChange?: (change: TabTransition) => void;
  };
  Blocks: {
    default: [tabComponent: WithBoundArgs<typeof Tab, 'register' | 'isActive'>];
  };
}

function prefixSlug(prefix: string, slug: string, type: 'control' | 'panel'): string {
  return `${prefix}-${slug}-${type}`;
}

export interface TabTransition {
  from: string | null;
  to: string;
}

export class Tabs extends Component<TabsSignature> {
  @tracked tabs: Tab[] = [];
  // ensure we respond to external changes to activeSlug
  @tracked _activeSlug: string | null = null;
  get activeSlug() {
    return this.args.activeSlug ?? this._activeSlug;
  }
  set activeSlug(value: string | null) {
    this._activeSlug = value;
  }

  slugPrefix = `tab-${Math.random().toString(36).substring(2, 8)}`;

  @cached
  get activeTab(): Tab {
    const { activeSlug, tabs } = this;
    const tab = activeSlug ? tabs.find(tab => tab.args.slug === activeSlug) : tabs[0];

    assert('No tabs have been registered', tabs.length > 0);
    assert(
      `No tab found with slug "${activeSlug}", available slugs are: ${tabs
        .map(tab => tab.args.slug)
        .join(', ')}`,
      tab !== undefined
    );

    return tab;
  }

  #hasEverRendered: boolean = false;
  #isUpdating: boolean = false;
  async #update() {
    if (!this.#hasEverRendered) return;
    if (this.#isUpdating) return;
    this.#isUpdating = true;
    // wait for the next tick to ensure all tabs are registered
    await Promise.resolve();
    this.#isUpdating = false;

    // trigger recomputation
    // eslint-disable-next-line no-self-assign
    this.tabs = this.tabs;
  }

  hasRenderedOnce = () =>{
    this.#hasEverRendered = true;
  }

  /**
   * Register a new tab
   */
  register = (tab: Tab): void => {
    const { tabs } = this;
    tabs.push(tab);

    void this.#update();
  };

  /**
   * Set the active tab
   */
  activateTab = (tab: Tab): void => {
    const newSlug = tab.args.slug;
    if (this.activeSlug === newSlug) return;

    // Notify parent of upcoming tab change
    this.args.onTabChange?.({ from: this.activeSlug, to: newSlug });
    this.activeSlug = newSlug;
  };

  /**
   * Check if a tab is active
   */
  isActive = (tab: Tab): boolean => {
    return this.activeSlug === tab.args.slug;
  }

  <template>
    <div ...attributes>
      {{yield (component Tab register=this.register isActive=this.isActive)}}
      {{(this.hasRenderedOnce)}}

      <ul role="tablist">
        {{#each this.tabs as |tab|}}
          <li class="{{if tab.isActive 'active'}}" role="presentation">
            <button
              type="button"
              class="tab-button"
              role="tab"
              aria-selected="{{tab.isActive}}"
              id={{prefixSlug this.slugPrefix tab.args.slug "control"}}
              aria-controls={{prefixSlug this.slugPrefix tab.args.slug "panel"}}
              {{on "click" (fn this.activateTab tab)}}
            >
              {{tab.title}}
            </button>
          </li>
        {{/each}}
      </ul>

      <section
        class="tab-content"
        role="tabpanel"
        id={{prefixSlug this.slugPrefix this.activeTab.args.slug "panel"}}
        aria-labelledby={{prefixSlug this.slugPrefix this.activeTab.args.slug "control"}}
      >
        {{this.activeTab.body}}
      </section>
    </div>
  </template>
}
