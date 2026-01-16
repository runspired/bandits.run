import Service, { service } from '@ember/service';
import type RouterService from '@ember/routing/router-service';
import { field, PersistedResource } from '#app/core/persisted-resource.ts';
import { getTheme } from '#app/core/site-theme.ts';

@PersistedResource('route-history')
class HistoryService extends Service {
  @service declare router: RouterService;

  @field
  latestRoute: string | null = null;

  track() {
    if (getTheme().isRunningAsInstalledApp) {
      if (this.latestRoute) {
        // Navigate to the last route
        this.router.replaceWith(this.latestRoute);
      }
    }

    // Listen to Ember's route changes and read from window
    this.router.on('routeDidChange', () => {
      // store the url minus the hostname
      const url = location.pathname + location.search + location.hash;
      this.latestRoute = url;
    });
  }
}

export default HistoryService;
