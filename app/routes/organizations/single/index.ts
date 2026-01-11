import type { Organization } from '#app/data/organization.ts';
import type { TrailRun } from '#app/data/run.ts';
import type Store from '#app/services/store.ts';
import Route from '@ember/routing/route';
import { service } from '@ember/service';
import { withReactiveResponse } from '@warp-drive/core/request';

export function getOrganization(organization: string) {
  return withReactiveResponse<Organization>({
    url: `/api/organization/${organization}.json`,
    method: 'GET',
  });
}

export function getOrganizationRuns(organization: string) {
  return withReactiveResponse<TrailRun[]>({
    url: `/api/organization/${organization}/runs.json`,
    method: 'GET',
  });
}

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
