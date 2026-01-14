import Component from '@glimmer/component';

import { checkServiceWorker } from '#app/core/preferences.ts';
import { service } from '@ember/service';
import type PortalsService from '#app/services/ux/portals.ts';

void checkServiceWorker();

export default class Application extends Component {
  @service('ux/portals') portals!: PortalsService;

  <template>
    {{this.portals.takeover}}
    {{outlet}}
  </template>
}
