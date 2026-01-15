import { getOrganizationRun } from '#app/data/api/get.ts';
import type Store from '#app/services/store.ts';
import { getOrgId } from '#app/utils/org.ts';
import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class OrganizationsSingleRunRoute extends Route {
  @service declare store: Store;

  queryParams = {
    fullscreen: {
      refreshModel: false
    },
    zoom: {
      refreshModel: false
    },
    lat: {
      refreshModel: false
    },
    lng: {
      refreshModel: false
    }
  };

  model(params: { org_slug: string, run_slug: string; fullscreen?: string; zoom?: string; lat?: string; lng?: string }) {
    const organizationId = getOrgId(params.org_slug as string);
    const runId = organizationId + '-' + params.run_slug;

    return {
      run: this.store.request(getOrganizationRun(organizationId, runId)),
      organizationId,
      runId,
      fullscreen: params.fullscreen === 'true' ? true : false,
      lat: params.lat ? parseFloat(params.lat) : undefined,
      lng: params.lng ? parseFloat(params.lng) : undefined,
      zoom: params.zoom ? parseInt(params.zoom) : undefined
    }
  }
}
