import Route from '@ember/routing/route';

export default class OrganizationsSingleIndexRoute extends Route {
  queryParams = {
    tab: {
      refreshModel: false
    }
  };

  model() {
    const params = this.paramsFor('organizations.single');

    return {
      organization: params.organization_id,
    }
  }
}
