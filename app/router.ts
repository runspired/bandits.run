import EmberRouter from '@embroider/router';
import config from 'bandits-web/config/environment';

export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}

Router.map(function () {
  this.route('branding');
  this.route('settings');
  this.route('organizations');
  this.route('organization', { path: 'org/:organization_id'});
  this.route('run', { path: '/runs/:org_slug/:run_slug' });
  this.route('explore');
  this.route('location', { path: '/location/:location_id' });
  this.route('contact', { path: '/contact/:runner_id' });
  this.route('not-found', { path: '/*path' });
});
