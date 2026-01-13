import type Store from '#app/services/store.ts';
import Route from '@ember/routing/route';
import { service } from '@ember/service';
import { getOrganization, getOrganizationRuns } from '#api/GET';

export default class OrganizationsSingleIndexRoute extends Route {
  @service declare store: Store;

  queryParams = {
    tab: {
      refreshModel: false
    }
  };

  model(queryParams: { tab?: string }) {
    const params = this.paramsFor('organizations.single');
    const organizationId = params.organization_id;

    // if the runs tab is selected, kick off the runs request as well
    if (queryParams.tab === 'runs') {
      void this.store.request(getOrganizationRuns(organizationId as string));
    }

    return {
      organization: this.store.request(getOrganization(organizationId as string)),
      organizationId
    }
  }
}
