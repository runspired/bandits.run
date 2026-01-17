import { QPRoute } from '#app/core/reactive/query-params/route.ts';
import { getOrganizationRun } from '#app/data/api/get.ts';
import { getMapStateById } from '#app/data/run.ts';
import type Store from '#app/services/store.ts';
import { getOrgId } from '#app/utils/org.ts';
import { service } from '@ember/service';

export default class OrganizationsSingleRunRoute extends QPRoute {
  @service declare store: Store;

  queryParams = this.qp('run', {
    prefix: '',
    mappings: {
      'activeParam': 'fs',
      'zoomParam': 'z',
      'latParam': 'lat',
      'lngParam': 'lng'
    },
    source: (model: { runId: string }) => {
      return getMapStateById(`trail-run:${model.runId}`);
    }
  });

  model(params: { org_slug: string, run_slug: string; }) {
    const organizationId = getOrgId(params.org_slug);
    const runId = organizationId + '-' + params.run_slug;

    return {
      run: this.store.request(getOrganizationRun(organizationId, runId)),
      organizationId,
      runId,
    }
  }
}
