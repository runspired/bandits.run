import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';

export default class HamburgerMenu extends Component<{
  Blocks: {
    default: [];
  };
}> {
  @tracked isOpen = false;

  toggleMenu = () => {
    this.isOpen = !this.isOpen;
  };

  <template>
    <div class="hamburger-menu-container">
      <button
        class="hamburger-button {{if this.isOpen 'open'}}"
        {{on "click" this.toggleMenu}}
        type="button"
        aria-label="Menu"
        aria-expanded={{if this.isOpen "true" "false"}}
      >
        <span class="hamburger-line"></span>
        <span class="hamburger-line"></span>
        <span class="hamburger-line"></span>
      </button>

      {{! Menu Overlay }}
      {{#if this.isOpen}}
        <div class="menu-overlay {{if this.isOpen 'open'}}">
          <nav class="menu-content">
            <ul class="menu-links">
              {{yield}}
            </ul>
          </nav>
        </div>
      {{/if}}
    </div>
  </template>
}
