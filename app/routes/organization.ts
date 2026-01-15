import type Store from '#app/services/store.ts';
import Route from '@ember/routing/route';
import { service } from '@ember/service';
import { getOrganization, getOrganizationRuns } from '#api/GET';
import { getOrgId } from '#app/utils/org.ts';

export default class OrganizationsSingleIndexRoute extends Route {
  @service declare store: Store;

  queryParams = {
    tab: {
      refreshModel: false
    }
  };

  model(params: { organization_id: string; tab?: string }) {
    const organizationId = getOrgId(params.organization_id as string);

    // if the runs tab is selected, kick off the runs request as well
    if (params.tab === 'runs') {
      void this.store.request(getOrganizationRuns(organizationId as string));
    }

    return {
      organization: this.store.request(getOrganization(organizationId as string)),
      organizationId
    }
  }
}
