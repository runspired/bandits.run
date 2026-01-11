import EmberRouter from '@embroider/router';
import config from 'bandits-web/config/environment';

export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}

Router.map(function () {
  this.route('branding');
  this.route('organizations', function () {
    this.route('index', { path: '/' });
    this.route('single', { path: '/:organization_id' }, function () {
      this.route('index', { path: '/' });
      this.route('run', { path: '/runs/:run_id' });
    });
  });
  this.route('location', { path: '/location/:location_id' });
  this.route('contact', { path: '/contact/:runner_id' });
  this.route('not-found', { path: '/*path' });
});
