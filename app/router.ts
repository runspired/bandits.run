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
      this.route('runs', { path: '/:organization_id/runs' }, function () {
        this.route('index', { path: '/' });
        this.route('single', { path: '/:run_id' });
      });
    });
  });
});
