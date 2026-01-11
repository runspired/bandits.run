import Component from '@glimmer/component';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import FaIcon from './fa-icon.gts';
import { faArrowLeft } from '@fortawesome/free-solid-svg-icons';
import type ViewTransitionService from '../services/view-transition';

/**
 * Back Button Component
 * Shows a back arrow button that pops from the navigation history stack
 * Only visible when there's history to go back to
 */
export default class BackButton extends Component {
  @service('view-transition') declare viewTransition: ViewTransitionService;

  handleBack = (event: MouseEvent) => {
    event.preventDefault();
    void this.viewTransition.goBack();
  };

  <template>
    {{#if this.viewTransition.canGoBack}}
      <button
        class="back-button"
        {{on "click" this.handleBack}}
        type="button"
        aria-label="Go back"
      >
        <FaIcon @icon={{faArrowLeft}} />
      </button>
    {{/if}}
  </template>
}
