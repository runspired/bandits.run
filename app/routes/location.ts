import Route from '@ember/routing/route';

export default class OrganizationsSingleIndexRoute extends Route {

  model(params: { location_id: string }) {

    return {
      location: params.location_id,
    }
  }
}
