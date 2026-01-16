import HamburgerMenu from '#ui/hamburger-menu.gts';
import FaIcon from '#ui/fa-icon.gts';
import DownloadButton from '#ui/download-button.gts';
import { LinkTo } from '@ember/routing';
import VtLink from '#core/vt-link.gts';
import {
  faHome,
  faUsers,
  faPalette,
  faSun,
  faGear,
  faMoon,
} from '@fortawesome/free-solid-svg-icons';
import { faGithub } from '@fortawesome/free-brands-svg-icons';
import { on } from '@ember/modifier';
import { scopedClass } from 'ember-scoped-css';
import { getTheme } from '#app/core/site-theme.ts';
import { fn } from '@ember/helper';
import Component from '@glimmer/component';
import { getDevicePreferences } from '#app/core/preferences.ts';
import { service } from '@ember/service';
import type RouterService from '@ember/routing/router-service';

function createScrollElement(): HTMLDivElement {
  const div = document.createElement('div');
  div.classList.add(scopedClass('sky'));
  return div;
}

class ThemedPage extends Component<{
  Blocks: {
    header: [];
    default: [HTMLDivElement];
  };
}> {
  @service declare router: RouterService;

  theme = getTheme();
  preferences = getDevicePreferences();
  scrollElement = createScrollElement();

  handleDownloadClick = () => {
    if (this.preferences.isProcessing) return;

    if (this.preferences.downloadForOffline) {
      // Already downloaded - navigate to settings page
      this.router.transitionTo('settings');
    } else {
      // Not downloaded yet - start installation
      void this.preferences.installPWA();
    }
  };

  <template>
    <section class="page" ...attributes>
      <div class="landscape-container">
        {{this.scrollElement}}

        {{#in-element this.scrollElement}}
          <div class="logo-header {{if (has-block 'header') 'page-title'}}">
            <div class="logo-header-text">
              {{#if (has-block "header")}}
                <h1 class="title">
                  <LinkTo @route="index" class={{scopedClass "link"}}>{{yield
                      to="header"
                    }}</LinkTo>
                </h1>
              {{else}}
                <h1 class="title">
                  <LinkTo @route="index" class={{scopedClass "link"}}>Bay Bandits</LinkTo>
                </h1>
              {{/if}}
            </div>
            <div class="header-controls">
              <div class="mode-toggle">
                {{! template-lint-disable require-presentational-children }}
                <div
                  class="toggle-track {{if this.theme.isDarkMode 'checked'}}"
                  {{on "click" (fn this.theme.updateThemePreference (if this.theme.isDarkMode 'light' 'dark'))}}
                  role="switch"
                  tabindex="0"
                  aria-label="Toggle dark mode"
                  aria-checked={{if this.theme.isDarkMode "true" "false"}}
                >
                  <span class="toggle-knob" aria-hidden="true">
                    {{#if this.theme.isDarkMode}}
                      <FaIcon @icon={{faMoon}} />
                    {{else}}
                      <FaIcon @icon={{faSun}} />
                    {{/if}}
                  </span>
                </div>
              </div>
              <HamburgerMenu>
                <:header>
                  <DownloadButton @status={{this.preferences.downloadStatus}} @onClick={{this.handleDownloadClick}} />
                </:header>
                <:default>
                <VtLink @route="index"><FaIcon @icon={{faHome}} /> Home</VtLink>
                <VtLink @route="organizations"><FaIcon @icon={{faUsers}} />
                  Organizations</VtLink>
                <LinkTo @route="branding"><FaIcon @icon={{faPalette}} />
                  Branding</LinkTo>
                <LinkTo @route="settings"><FaIcon @icon={{faGear}} /> Settings</LinkTo>
                <a href="https://github.com/runspired/bandits.run" target="_blank" rel="noopener noreferrer"><FaIcon @icon={{faGithub}} /> GitHub</a>
                </:default>
              </HamburgerMenu>
            </div>
          </div>

          <div class="content-area">
            {{yield this.scrollElement}}
          </div>
        {{/in-element}}

        <svg
          class="hill-svg back-hill"
          viewBox="0 0 1440 320"
          preserveAspectRatio="none"
        >
          <path
            d="M0,160L120,176C240,192,480,224,720,224C960,224,1200,192,1320,176L1440,160L1440,320L1320,320C1200,320,960,320,720,320C480,320,240,320,120,320L0,320Z"
          ></path>
        </svg>

        <svg
          class="hill-svg front-hill"
          viewBox="0 0 1440 320"
          preserveAspectRatio="none"
        >
          <path
            d="M0,224L80,213.3C160,203,320,181,480,181.3C640,181,800,203,960,213.3C1120,224,1280,224,1360,224L1440,224L1440,320L1360,320C1280,320,1120,320,960,320C800,320,640,320,480,320C320,320,160,320,80,320L0,320Z"
          ></path>
        </svg>

        <div class="tree-container">
          <div class="tree tree-left-0"></div>
          <div class="tree tree-left-1"></div>
          <div class="tree tree-left-2"></div>
          <div class="tree tree-left-3"></div>
          <div class="tree tree-right-0"></div>
          <div class="tree tree-right-1"></div>
          <div class="tree tree-right-2"></div>
          <div class="tree tree-right-3"></div>
          <div class="tree tree-right-4"></div>
        </div>
      </div>
    </section>
  </template>
}

export default ThemedPage;
