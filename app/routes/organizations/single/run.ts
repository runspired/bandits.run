import { getOrganizationRun } from '#app/data/api/get.ts';
import type Store from '#app/services/store.ts';
import Route from '@ember/routing/route';
import { service } from '@ember/service';

interface OrganizationsSingleRunRouteQueryParams {
  fullscreen?: string;
  zoom?: string;
  lat?: string;
  lng?: string;
}

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

  model(routeParams: { run_id: string; fullscreen?: string; zoom?: string; lat?: string; lng?: string }) {
    const params = this.paramsFor('organizations.single');
    const organizationId = params.organization_id;
    const runId = routeParams.run_id;

    return {
      run: this.store.request(getOrganizationRun(organizationId as string, runId)),
      organizationId,
      runId,
      fullscreen: routeParams.fullscreen === 'true' ? true : false,
      lat: routeParams.lat ? parseFloat(routeParams.lat) : undefined,
      lng: routeParams.lng ? parseFloat(routeParams.lng) : undefined,
      zoom: routeParams.zoom ? parseInt(routeParams.zoom) : undefined
    }
  }
}
