import Route from '@ember/routing/route';
import type { QueryParams } from './service';
import { service } from '@ember/service';
import { dependentKeyCompat } from '@ember/object/compat';
import type { QPController } from './controller';
import type { ControllerQueryParam } from '@ember/controller';
import { getParamCompanion } from '../../utils/-storage-infra';
import type RouterService from '@ember/routing/router-service';

export interface GroupConfig {
  control: string;  // The field name that controls this group
  mappings: Record<string, string>;
}

export interface QPSource {
  prefix: string | null;
  mappings?: Record<string, string>;
  groups?: Record<string, GroupConfig>;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  source: (target: any) => object,
}

export interface RouteParamConfig {
  as: string;
  refreshModel: boolean;
  replace: boolean;
}

export class QPRoute extends Route {
  @service('query-params') declare params: QueryParams;
  @service declare router: RouterService;

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

function buildRouteParams(route: Route, scope: string, sourceDirectory: Record<string, unknown>, source: QPSource, serviceProp: string) {
  const routeConfig: Record<string, RouteParamConfig> = {};
  const controllerConfig: ControllerQueryParam[] = [];
  const { prefix, mappings, groups, source: svc } = source;
  const namespace = prefix ? prefix : '@route';

  // Build a flat mapping of all params and track control relationships
  const allMappings: Record<string, string> = {};
  const groupControlMap: Record<string, string> = {};  // fieldName -> controlFieldName

  // Process groups first
  if (groups) {
    for (const [groupName, groupConfig] of Object.entries(groups)) {
      // Track which field controls each member of this group
      for (const fieldName of Object.keys(groupConfig.mappings)) {
        groupControlMap[fieldName] = groupConfig.control;
      }

      // Add all mappings from this group
      Object.assign(allMappings, groupConfig.mappings);

      // Ensure control param is included with group name as URL name
      if (!allMappings[groupConfig.control]) {
        allMappings[groupConfig.control] = groupName;
      }
    }
  }

  // Add ungrouped mappings (if any)
  if (mappings) {
    Object.assign(allMappings, mappings);
  }

  // Property descriptor that resolves the StorageResource and returns its param companion
  const desc = {
    get() {
      // eslint-disable-next-line ember/no-private-routing-service
      const activeTransition = route._router._routerMicrolib.activeTransition;
      const routeParams = activeTransition ? activeTransition.routeInfos?.find(ri => ri.name === scope)?.params : route.paramsFor(scope)

      const storageResource = svc(routeParams || {});

      // Return the param companion object which handles serialization
      // Pass the group control map so it knows which params are controlled
      const params = getParamCompanion(storageResource, groupControlMap);
      return params;
    }
  };
  const newDesc = dependentKeyCompat(sourceDirectory, namespace, desc);
  Object.defineProperty(sourceDirectory, namespace, newDesc);

  // Determine which keys to expose as query params
  const keys = Object.keys(allMappings);

  for (const key of keys) {
    const paramName = allMappings[key];
    if (!paramName) {
      continue; // Skip if no URL name is defined
    }
    const asName = prefix ? `${prefix}.${paramName}` : paramName;
    const qpKey = `${serviceProp}.state.${scope}.${namespace}.${key}`;
    routeConfig[qpKey] = { as: asName, refreshModel: false, replace: true };
    controllerConfig.push(qpKey);
  }

  return { route: routeConfig, controller: controllerConfig };
}
