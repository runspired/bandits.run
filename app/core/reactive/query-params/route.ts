import Route from '@ember/routing/route';
import type { QueryParams } from './service';
import { service } from '@ember/service';
import { dependentKeyCompat } from '@ember/object/compat';
import type { QPController } from './controller';
import type { ControllerQueryParam } from '@ember/controller';

interface QPSource {
  prefix: string | null;
  mappings: Record<string, string> | null;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  source: (target: any) => object,
}

export class QPRoute extends Route {
  @service('query-params') declare params: QueryParams;
  controllerName = '-qp';
  declare _qpControllerParams: ControllerQueryParam[];

  qp(scope: string, source: QPSource | QPSource[], serviceProp: string = 'params') {
    const sources = Array.isArray(source) ? source : [source];
    const routeConfig: Record<string, RouteParamConfig> = {};
    const controllerConfig: ControllerQueryParam[] = [];
    const keyedSources = {};

    /**
     * Build query param config for each source
     * and merge into a single config object
     *
     * @example
     *
     * if in the `application` route, then the following
     * call:
     *
     * ```ts
     * queryParams = this.qp([
     *   {
     *     prefix: 'table',
     *     mappings: { page: 'pg', perPage: 'pp' },
     *     source: ReactiveThingA,
     *   },
     *   {
     *     prefix: null,
     *     mappings: null,
     *     source: ReactiveThingB,
     *   }
     * ]);
     * ```
     *
     * Will produce:
     *
     * ```ts
     * {
     *   'params.state.application.table.page': { as: 'table.pg', refreshModel: true, replace: true },
     *   'params.state.application.table.perPage': { as: 'table.pp', refreshModel: true, replace: true },
     *   'params.state.application.searchTerm': { as: 'searchTerm', refreshModel: true, replace: true },
     * }
     * ```
     */
    for (const option of sources) {
      const { route, controller } = buildRouteParams(this, scope, keyedSources, option, serviceProp);
      Object.assign(routeConfig, route);
      controllerConfig.push(...controller);
    }

    /**
     * Add the sources to the services's tracked sources
     * so it can manage updates
     */
    this.params.state[scope] = keyedSources;
    this._qpControllerParams = controllerConfig;

    return routeConfig;
  }

  setupController(controller: QPController, model: unknown) {
    super.setupController(controller, model);
    controller.queryParams = this._qpControllerParams;
  }
}

type RouteParamConfig = {
  as: string;
  refreshModel: boolean;
  replace: boolean;
}

function buildRouteParams(route: Route, scope: string, sourceDirectory: Record<string, unknown>, source: QPSource, serviceProp: string) {
  const routeConfig: Record<string, RouteParamConfig> = {};
  const controllerConfig: ControllerQueryParam[] = [];
  const { prefix, mappings, source: svc } = source;
  const keys = mappings ? Object.keys(mappings) : Object.keys(svc);
  const namespace = prefix ? prefix : '@route';
  const desc = {
    get() {
      const controller = route.controllerFor(scope);
      const result = svc(controller.model || {});
      return result;
    }
  };
  const newDesc = dependentKeyCompat(sourceDirectory, namespace, desc);
  Object.defineProperty(sourceDirectory, namespace, newDesc);

  keys.forEach(key => {
    const paramName = mappings && mappings[key] ? mappings[key] : key;
    const asName = prefix ? `${prefix}.${paramName}` : paramName;
    const qpKey = `${serviceProp}.state.${scope}.${namespace}.${key}`;
    routeConfig[qpKey] = { as: asName, refreshModel: false, replace: true };
    controllerConfig.push(qpKey);
  });

  return { route: routeConfig, controller: controllerConfig };
}
