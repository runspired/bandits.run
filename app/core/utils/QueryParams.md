# Query Params

Whenever possible, the state of the application should be
serialized to one of the server, local storage, session storage, or the url so that users can return to the same
state at will.

Best practice is to use the url whenever you want to enable the user to share or save current application state for use later or with someone else.

The core query params module makes this easy for Ember
applications, abstracting away many of the harder nuances
of params serialization and ensuring your application state
stays healthy.

Params are always backed by either a reactive local storage or session storage value, with synchronization automatically managed for you. That way your state is always persisted, whether it is currently in the url or not.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Core Concepts](#core-concepts)
- [API Reference](#api-reference)
- [Advanced Usage](#advanced-usage)
- [Examples](#examples)

---

## Overview

The `#core/` query-params solution provides:

- **Automatic URL Synchronization**: Reactive storage properties automatically sync with URL query parameters
- **Browser Storage Persistence**: Values persist across page loads via localStorage/sessionStorage
- **Type-Safe Serialization**: Configure how values convert between JavaScript types and URL strings
- **Prettification**: Routes pick the name they want a param to appear as, and control of value serialization, deserialization and comparison enables storing prettified versions of the raw value in storage.
- **Smart Defaults**: Only non-default values appear in URLs to keep them clean
- **Grouped Parameters**: Control multiple parameters with a single toggle (e.g., map view controls lat/lng/zoom)
- **Hybrid Initialization**: Intelligently prioritize URL params, storage values, or server defaults

---

## Installation

The package is available via the `#core/` import path:

```ts
import { SessionResource, field } from '#core/utils/storage-resource';
import { param, BooleanParam, NumberParam, DecimalDegreeParam } from '#core/utils/params';
import { QPRoute } from '#core/reactive/query-params/route';
```

---

## Quick Start

### 1. Create a Storage Resource

Define a class with properties that should be persisted.
Here's a simple example with `lat,lng` for a map's center
point.

```ts
import { SessionResource, field } from '#core/utils/storage-resource';

@SessionResource((coord: Coord) => `coords:${coord.id}`)
class Coord {
  constructor(id: string) {
    this.id = id;
  }
  @field id: string;

  @field
  lat: number = 0.0

  @field
  lng: number = 0.0
}
```

### 2. Give fields param capabilities

```ts
import { SessionResource, field } from '#core/utils/storage-resource';
import { param, DecimalDegreeParam, NumberParam } from '#core/utils/params';

@SessionResource((coord: Coord) => `coords:${coord.id}`)
class Coord {
  constructor(id: string) {
    this.id = id;
  }
  @field id: string;

  @param(DecimalDegreeParam(() => 0))
  @field
  lat: number = 0.0

  @param(DecimalDegreeParam(() => 0))
  @field
  lng: number = 0.0

  @param(NumberParam(() => 14, 14))
  @field
  zoom: number = 14
}

const Coords = new Map<string, Coord>();
export function getCoord(id: string) {
  if (!Coords.has(id)) {
    Coords.set(id, new Coord(id));
  }

  return Coords.get(id)!;
}
```

### 3. Connect to Route

Wire up the storage resource to your Ember route. This
entails changing to the QPRoute base class.

Each source is a function that receives the model, enabling
dynamic lookup of params sources based on the current model.

```ts
import { QPRoute } from '#core/reactive/query-params/route';

export default class SearchRoute extends QPRoute {
  queryParams = this.qp('search', {
    prefix: 'm',
    mappings: {
      lat: 'lat',
      lng: 'lng',
      zoom: 'z'
    },
    source: (model: { someId: number }) => getCoord(model.someId)
  });
}
```

More than one source is possible by passing an array of source
configs as the second argument to `qp`.

### 4. Use in Your Application

The URL will automatically update when properties change:

```ts
// URL: <my-route>/?m.lat=-123.54321&m.lng=78.12345&m.z=13
```

---

## Core Concepts

### Storage Resources

Storage Resources are classes decorated with `@SessionResource` or `@LocalResource` that automatically persist their state to browser storage.

- **`@SessionResource(id)`**: Persists to sessionStorage (cleared when tab closes)
- **`@LocalResource(id)`**: Persists to localStorage (persists across browser sessions)

The `id` parameter can be:
- A string for singleton resources: `@SessionResource('user-preferences')`
- A function for multiple instances: `@SessionResource((map: MapState) => `map-state:${map.id}`)`

### Fields

Properties decorated with `@field` are automatically synchronized with browser storage:

```ts
@SessionResource('my-state')
class MyState {
  @field
  username: string = 'guest';

  @field
  count: number = 0;
}
```

When you update `myState.username = 'alice'`, it's automatically saved to sessionStorage.

### Query Parameters

Add the `@param()` decorator to make a field also sync with URL query parameters:

```ts
@SessionResource('filters')
class Filters {
  @param(BooleanParam())
  @field
  active: boolean = false;
}
```

The `@param()` decorator requires a `ParamConfig` that defines how to:
- **Serialize**: Convert the value to a URL string (or `null` to omit)
- **Deserialize**: Parse the URL string back to the original type
- **Compare**: Check if URL and local values match
- **Check defaults**: Determine if a value is the default (to omit from URL)

### QPRoute

`QPRoute` is an extended Ember Route class that connects storage resources to Ember's query param system:

```ts
export default class MyRoute extends QPRoute {
  queryParams = this.qp('routeName', {
    prefix: 'map',           // URL prefix: ?map.zoom=10
    mappings: {              // Field -> URL param name
      zoom: 'z',
      latitude: 'lat'
    },
    source: (model) => getMyResource(model.id)
  });
}
```

---

## API Reference

### Decorators

#### `@param(config: ParamConfig)`

Marks a `@field` as a query parameter with custom serialization logic.

**Parameters:**
- `config: ParamConfig` - Configuration object defining serialization behavior

**Example:**
```ts
@param({
  serialize: (value: boolean) => value ? '1' : null,
  deserialize: (urlValue: string) => urlValue === '1',
  compare: (urlValue: string, localValue: boolean) => (urlValue === '1') === localValue,
  isDefault: (urlValue: string) => urlValue !== '1',
})
@field
myFlag: boolean = false;
```

#### `@SessionResource(id: string | KeyFn)`

Decorates a class to persist its fields in sessionStorage.

**Parameters:**
- `id` - Unique identifier (string) or key function for multi-instance resources

**Example:**
```ts
@SessionResource('app-settings')
class AppSettings {
  @field theme: 'light' | 'dark' = 'light';
}
```

#### `@LocalResource(id: string | KeyFn)`

Decorates a class to persist its fields in localStorage.

**Parameters:**
- `id` - Unique identifier (string) or key function for multi-instance resources

**Example:**
```ts
@LocalResource('user-preferences')
class UserPreferences {
  @field fontSize: number = 14;
}
```

#### `@field`

Marks a property for automatic browser storage persistence.

**Example:**
```ts
@SessionResource('state')
class State {
  @field counter: number = 0;
  @field('local') crossSessionValue: string = ''; // Override storage type
}
```

### ParamConfig Factories

Pre-built configurations for common parameter types.

#### `BooleanParam()`

Creates a config for boolean fields that serialize to `'1'` or omit from URL.

**Example:**
```ts
@param(BooleanParam())
@field
isActive: boolean = false;
```

**URL Behavior:**
- `true` → `?isActive=1`
- `false` → param omitted from URL

#### `NumberParam(getDefault)`

Creates a config for numeric fields with default value checking.

**Parameters:**
- `getDefault: () => number` - Function returning the default value (omit if value equals default)

**Example:**
```ts
@param(NumberParam(
  function(this: MapState) { return this.defaultZoom; },
  12
))
@field
zoom: number = 12;

@field
defaultZoom: number = 12;
```

**URL Behavior:**
- Value equals default → omitted from URL
- Value differs from default → `?zoom=15`

#### `DecimalDegreeParam(getDefault, precision?)`

Creates a config for decimal degree coordinates (latitude/longitude) with epsilon-based comparison.

**Parameters:**
- `getDefault: () => number` - Function returning the default value
- `precision: number` - Decimal places (default: 5, ~1.1 meter precision)

**Example:**
```ts
@param(DecimalDegreeParam(
  function(this: MapState) { return this.defaultLat; }
))
@field
lat: number = 0;

@field
defaultLat: number = 0;
```

**URL Behavior:**
- Serializes to 5 decimal places: `?lat=40.71278`
- Uses epsilon comparison for float equality

### QPRoute

#### `qp(scope: string, source: QPSource | QPSource[], serviceProp?: string)`

Configure query parameters for a route with one or more storage resource sources.

**Parameters:**
- `scope: string` - Route name (typically matches route name)
- `source: QPSource | QPSource[]` - Configuration object(s) defining param sources
- `serviceProp: string` - Service property name (default: 'params')

**QPSource Interface:**
```ts
interface QPSource {
  prefix: string | null;           // URL prefix for all params (null for none)
  mappings?: Record<string, string>; // Field name -> URL param name
  groups?: Record<string, GroupConfig>; // Grouped parameter configurations
  source: (model: any) => object;   // Function returning the storage resource
}
```

**GroupConfig Interface:**
```ts
interface GroupConfig {
  control: string;                  // Field name that controls this group
  mappings: Record<string, string>; // Field name -> URL param name for group members
}
```

**Example:**
```ts
export default class MyRoute extends QPRoute {
  queryParams = this.qp('myRoute', {
    prefix: 'search',
    mappings: {
      query: 'q',
      page: 'pg'
    },
    source: () => searchState
  });
}
```

---

## Advanced Usage

### Grouped Parameters

Control multiple parameters with a single boolean field. When the control field is falsy, grouped params won't appear in the URL.

**Use Case:** Map view controls (when map is inactive, don't show lat/lng/zoom in URL)

```ts
@SessionResource((map: MapState) => `map-state:${map.id}`)
class MapState {
  @param(BooleanParam())
  @field
  active: boolean = false;  // Control field

  @param(NumberParam(() => 12))
  @field
  zoom: number = 12;

  @param(DecimalDegreeParam(() => 0))
  @field
  lat: number = 0;

  @param(DecimalDegreeParam(() => 0))
  @field
  lng: number = 0;
}
```

**Route Configuration:**
```ts
export default class MapRoute extends QPRoute {
  queryParams = this.qp('map', {
    prefix: '',
    groups: {
      fs: {  // Group name becomes URL param for control field
        control: 'active',
        mappings: {
          zoom: 'z',
          lat: 'lat',
          lng: 'lng'
        }
      }
    },
    source: (model) => getMapState(model.id)
  });
}
```

**URL Behavior:**
- `active = false` → URL: `/map`
- `active = true` → URL: `/map?fs=1&z=12&lat=40.71278&lng=-74.00594`
- Setting `active = false` removes all grouped params from URL

### Multi-Instance Resources

Use a key function to create multiple instances of a resource, each with its own storage:

```ts
@SessionResource((map: MapState) => `map-state:${map.id}`)
class MapState {
  id: string;

  constructor(id: string) {
    this.id = id;
  }

  @param(DecimalDegreeParam(() => this.defaultLat))
  @field
  lat: number = 0;

  @field
  defaultLat: number = 0;
}
```

**Storage Keys:**
- Instance 1 (id='main'): `persisted:map-state:main:lat`
- Instance 2 (id='overview'): `persisted:map-state:overview:lat`

### Multiple Parameter Sources

Combine parameters from different storage resources in a single route:

```ts
export default class DashboardRoute extends QPRoute {
  queryParams = this.qp('dashboard', [
    {
      prefix: 'table',
      mappings: { page: 'pg', perPage: 'pp' },
      source: () => tableState
    },
    {
      prefix: null,
      mappings: { searchTerm: 'q' },
      source: () => searchState
    }
  ]);
}
```

**URL Result:** `/dashboard?table.pg=2&table.pp=50&q=hello`

### Custom ParamConfig

Create custom serialization logic for complex types:

```ts
interface DateRange {
  start: Date;
  end: Date;
}

function DateRangeParam(): ParamConfig {
  return {
    serialize: (value: DateRange) => {
      if (!value.start || !value.end) return null;
      return `${value.start.toISOString()},${value.end.toISOString()}`;
    },
    deserialize: (urlValue: string) => {
      const [start, end] = urlValue.split(',');
      return { start: new Date(start), end: new Date(end) };
    },
    compare: (urlValue: string, localValue: DateRange) => {
      const deserialized = DateRangeParam().deserialize(urlValue) as DateRange;
      return deserialized.start.getTime() === localValue.start.getTime() &&
             deserialized.end.getTime() === localValue.end.getTime();
    },
    isDefault: (urlValue: string) => {
      // Define what constitutes a "default" range
      return urlValue === '';
    }
  };
}
```

### Storage Type Overrides

Override storage type for specific fields:

```ts
@SessionResource('my-state')
class MyState {
  @field
  sessionValue: string = '';  // Uses sessionStorage (from decorator)

  @field('local')
  persistentValue: string = '';  // Overrides to use localStorage
}
```

---

## Examples

### Example 1: Simple Search Filters

```ts
// 1. Define storage resource
@SessionResource('search-filters')
class SearchFilters {
  @param(BooleanParam())
  @field
  showArchived: boolean = false;

  @param(NumberParam(() => 1, 1))
  @field
  page: number = 1;

  @field  // Not a param, won't appear in URL
  lastSearchTime: number = 0;
}

// 2. Configure route
export default class SearchRoute extends QPRoute {
  queryParams = this.qp('search', {
    prefix: '',
    mappings: {
      showArchived: 'archived',
      page: 'pg'
    },
    source: () => searchFilters
  });
}

// 3. Use in component/controller
searchFilters.showArchived = true;
searchFilters.page = 2;
// URL: /search?archived=1&pg=2
```

### Example 2: Map with Grouped Controls

```ts
// 1. Define map state
@SessionResource((map: MapState) => `map-state:${map.id}`)
class MapState {
  id: string;

  constructor(id: string) {
    this.id = id;
  }

  @param(BooleanParam())
  @field
  active: boolean = false;

  @param(NumberParam(() => this.defaultZoom, 12))
  @field
  zoom: number = 12;

  @param(DecimalDegreeParam(() => this.defaultLat))
  @field
  lat: number = 40.7128;

  @param(DecimalDegreeParam(() => this.defaultLng))
  @field
  lng: number = -74.0060;

}

// 2. Configure route with grouped params
export default class RunRoute extends QPRoute {
  queryParams = this.qp('run', {
    prefix: '',
    groups: {
      fs: {  // 'fs' becomes the URL param name for the control field
        control: 'active',
        mappings: {
          zoom: 'z',
          lat: 'lat',
          lng: 'lng'
        }
      }
    },
    source: (model) => getMapState(`trail-run:${model.runId}`)
  });

  model(params) {
    const mapState = getMapState(`trail-run:${params.runId}`);

    // Initialize with server data
    mapState.initialize({
      lat: 40.7128,
      lng: -74.0060,
      zoom: 13
    });

    return { runId: params.runId, mapState };
  }
}

// 3. Toggle map view
mapState.active = true;
// URL: /run?fs=1&z=13&lat=40.71280&lng=-74.00600

mapState.zoom = 15;
// URL: /run?fs=1&z=15&lat=40.71280&lng=-74.00600

mapState.active = false;
// URL: /run (all map params removed)
```

### Example 3: Dashboard with Multiple Sources

```ts
// 1. Define separate concerns
@SessionResource('table-state')
class TableState {
  @param(NumberParam(() => 1, 1))
  @field
  page: number = 1;

  @param(NumberParam(() => 25, 25))
  @field
  perPage: number = 25;
}

@SessionResource('search-state')
class SearchState {
  @param({
    serialize: (v: string) => v || null,
    deserialize: (v: string) => v,
    compare: (url: string, local: string) => url === local,
    isDefault: (v: string) => !v
  })
  @field
  query: string = '';
}

// 2. Combine in route
export default class DashboardRoute extends QPRoute {
  queryParams = this.qp('dashboard', [
    {
      prefix: 'tbl',
      mappings: { page: 'pg', perPage: 'pp' },
      source: () => tableState
    },
    {
      prefix: null,
      mappings: { query: 'q' },
      source: () => searchState
    }
  ]);
}

// 3. Independent control
tableState.page = 3;
searchState.query = 'ember';
// URL: /dashboard?tbl.pg=3&q=ember

tableState.perPage = 50;
// URL: /dashboard?tbl.pg=3&tbl.pp=50&q=ember
```

---

## Best Practices

1. **Use Grouped Parameters for Related State**: When multiple params depend on a single boolean toggle, use groups to keep URLs clean.

2. **Choose Storage Type Wisely**:
   - Use `@SessionResource` for transient UI state (filters, pagination)
   - Use `@LocalResource` for persistent preferences (theme, display settings)

3. **Provide Sensible Defaults**: Use `getDefault` functions in param configs to omit default values from URLs.

4. **Keep URL Param Names Short**: Use concise mappings (`zoom: 'z'`, `page: 'pg'`) to keep URLs readable.

5. **Use Precision Appropriately**: For coordinates, 5 decimal places (~1.1m) is usually sufficient. Adjust as needed.

6. **Test Storage Persistence**: Verify that storage values survive page refreshes and that URL params take precedence on load.
