import Component from '@glimmer/component';

import { checkServiceWorker } from '#app/core/preferences.ts';
import { service } from '@ember/service';
import type PortalsService from '#app/services/ux/portals.ts';
import type HistoryService from '#app/services/history.ts';
import type Owner from '@ember/owner';

void checkServiceWorker();

export default class Application extends Component {
  @service('ux/portals') portals!: PortalsService;
  @service history!: HistoryService;

  constructor(owner: Owner, args: object) {
    super(owner, args);
    this.history.track();
  }

  <template>
    {{this.portals.takeover}}
    {{outlet}}
  </template>
}
