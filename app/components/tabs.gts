import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import './tabs.css';

class Tab extends Component<{
  Args: {
    registerTab: (tab: Tab) => boolean;
    id?: string;
  };
  Blocks: {
    body: [];
    label: [];
  };
}> {
  id = this.args.id;
  @tracked isActive = this.args.registerTab(this);
  label = globalThis.document.createElement('div');
  body = globalThis.document.createElement('div');

  <template>
    {{#in-element this.label}}
      {{yield to="label"}}
    {{/in-element}}
    {{#if this.isActive}}
      {{#in-element this.body}}
        {{yield to="body"}}
      {{/in-element}}
    {{/if}}
  </template>
}

export class Tabs extends Component<{
  Args: {
    activeId?: string | null;
    onTabChange?: (id: string | undefined) => void;
  };
}> {
  tabs: Tab[] = [];
  register = (tab: Tab): boolean => {
    this.tabs.push(tab);

    // If activeId is provided and matches this tab's id, make it active
    if (this.args.activeId && tab.id === this.args.activeId) {
      this.activeTab = tab;
      return true;
    }

    // Otherwise, make the first tab active
    const isActive = this.tabs.length === 1 && !this.args.activeId;
    if (isActive) {
      this.activeTab = tab;
    }
    return isActive;
  };

  @tracked activeTab: Tab | null = null;

  setActiveTab = (tab: Tab) => {
    if (this.activeTab) {
      this.activeTab.isActive = false;
    }
    tab.isActive = true;
    this.activeTab = tab;

    // Notify parent of tab change
    if (this.args.onTabChange) {
      this.args.onTabChange(tab.id);
    }
  };

  <template>
    {{yield (component Tab registerTab=this.register)}}
    <div class="tabs">
      <ul class="tab-labels">
        {{#each this.tabs as |tab|}}
          <li class="tab-label {{if tab.isActive 'active'}}">
            <button
              type="button"
              class="tab-button"
              {{on "click" (fn this.setActiveTab tab)}}
            >
              {{tab.label}}
            </button>
          </li>
        {{/each}}
      </ul>
      <div class="tab-bodies">
        {{#if this.activeTab}}
          <div class="tab-body">
            {{this.activeTab.body}}
          </div>
        {{/if}}
      </div>
    </div>
  </template>
}
