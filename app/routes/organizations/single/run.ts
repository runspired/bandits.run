import { getOrganizationRun } from '#app/data/api/get.ts';
import type Store from '#app/services/store.ts';
import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class OrganizationsSingleIndexRoute extends Route {
  @service declare store: Store;


  model(routeParams: { run_id: string}) {
    const params = this.paramsFor('organizations.single');
    const organizationId = params.organization_id;
    const runId = routeParams.run_id;

    return {
      run: this.store.request(getOrganizationRun(organizationId as string, runId)),
      organizationId,
      runId,
    }
  }
}
