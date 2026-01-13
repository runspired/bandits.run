import { getLocalStorage } from './reactive-storage';

/**
 * Symbol used to store persistence metadata on classes
 */
const PERSISTED_RESOURCE_META = Symbol('PersistedResourceMeta');

/**
 * Metadata attached to persisted resource classes
 */
interface PersistedResourceMeta {
  id: string;
  fields: Set<string>;
  cache: Record<string, unknown> | null;
}

/**
 * Get or create the persisted resource metadata for a class
 */
function getMeta(target: object): PersistedResourceMeta | undefined {
  return (target as Record<symbol, PersistedResourceMeta>)[PERSISTED_RESOURCE_META];
}

/**
 * Load persisted data from localStorage (uncached, for initial load)
 */
function loadFromStorage(id: string): Record<string, unknown> | null {
  const stored = getLocalStorage().getItem(`persisted-resource:${id}`);
    if (stored) {
      return JSON.parse(stored) as Record<string, unknown>;
    }
  return null;
}

/**
 * Get cached data or load from localStorage if not yet cached
 */
function getPersistedData(meta: PersistedResourceMeta): Record<string, unknown> {
  if (meta.cache === null) {
    meta.cache = loadFromStorage(meta.id) ?? {};
  }
  return meta.cache;
}

/**
 * Save data to localStorage
 */
function savePersistedData(id: string, data: Record<string, unknown>): void {
  getLocalStorage().setItem(`persisted-resource:${id}`, JSON.stringify(data));
}

/**
 * Decorator which transforms a class into a persisted resource.
 *
 * Persisted resources must be singletons.
 */
export function PersistedResource(id: string): ClassDecorator {
  // eslint-disable-next-line @typescript-eslint/no-unsafe-function-type
  return function (target: Function) {
    // Attach metadata to the class prototype
    const meta: PersistedResourceMeta = {
      id,
      fields: new Set(),
      cache: null,
    };

    (target.prototype as Record<symbol, PersistedResourceMeta>)[PERSISTED_RESOURCE_META] = meta;
  };
}

/**
 * Creates a persisted field descriptor that wraps an existing accessor descriptor (e.g., from @tracked)
 */
function createAccessorFieldDescriptor(
  propertyKey: string,
  originalDescriptor: PropertyDescriptor
): PropertyDescriptor {
  const initializedInstances = new WeakMap<object, boolean>();

  return {
    configurable: true,
    enumerable: originalDescriptor.enumerable,
    get(this: object): unknown {
      // Initialize from persisted data on first access
      if (!initializedInstances.has(this)) {
        initializedInstances.set(this, true);
        const meta = getMeta(this);
        if (meta) {
          meta.fields.add(propertyKey);
          const data = getPersistedData(meta);
          if (propertyKey in data) {
            // Use the original setter to set the persisted value
            originalDescriptor.set?.call(this, data[propertyKey]);
          }
        }
      }
      return originalDescriptor.get?.call(this) as unknown;
    },
    set(this: object, value: unknown) {
      // Ensure initialization has happened
      if (!initializedInstances.has(this)) {
        initializedInstances.set(this, true);
        const meta = getMeta(this);
        if (meta) {
          meta.fields.add(propertyKey);
        }
      }

      // Call the original setter
      originalDescriptor.set?.call(this, value);

      // Persist the new value
      const meta = getMeta(this);
      if (meta) {
        const data = getPersistedData(meta);
        data[propertyKey] = value;
        savePersistedData(meta.id, data);
      }
    },
  };
}

/**
 * Creates a persisted field descriptor for a plain property (no existing descriptor)
 */
function createPlainFieldDescriptor(propertyKey: string): PropertyDescriptor {
  const initializedInstances = new WeakMap<object, boolean>();
  const storedValues = new WeakMap<object, unknown>();

  return {
    configurable: true,
    enumerable: true,
    get(this: object): unknown {
      // Initialize from persisted data on first access
      if (!initializedInstances.has(this)) {
        initializedInstances.set(this, true);
        const meta = getMeta(this);
        if (meta) {
          meta.fields.add(propertyKey);
          const data = getPersistedData(meta);
          if (propertyKey in data) {
            storedValues.set(this, data[propertyKey]);
            return data[propertyKey];
          }
        }
      }
      return storedValues.get(this);
    },
    set(this: object, value: unknown) {
      // Ensure initialization tracking
      if (!initializedInstances.has(this)) {
        initializedInstances.set(this, true);
        const meta = getMeta(this);
        if (meta) {
          meta.fields.add(propertyKey);
        }
      }

      storedValues.set(this, value);

      // Persist the new value
      const meta = getMeta(this);
      if (meta) {
        const data = getPersistedData(meta);
        data[propertyKey] = value;
        savePersistedData(meta.id, data);
      }
    },
  };
}

/**
 * Decorator which marks a property as a persisted field.
 *
 * The field's value will be initialized from the persisted resource data
 * if available, falling back to the property's default value otherwise.
 *
 * Fields can be of any type that is serializable to and restorable from JSON,
 * but complex types (like objects or arrays) should be handled with care to avoid
 * unintended mutations or reactivity issues.
 *
 * ---
 *
 * **Example:**
 *
 * ```ts
 * @PersistedResource('user-settings')
 * class UserSettings {
 *   @field
 *   theme: 'light' | 'dark' = 'light';
 * }
 * ```
 *
 * The decorator can also be used in conjunction with other
 * property decorators that use the accessor descriptor form.
 *
 * **Example:**
 *
 * ```ts
 * @PersistedResource('app-state')
 * class AppState {
 *   @field
 *   @toggled
 *   isLoggedIn: boolean = false;
 * }
 * ```
 *
 */
export function field(
  _target: object,
  propertyKey: string,
  descriptor?: PropertyDescriptor
): void {
  if (descriptor && (descriptor.get || descriptor.set)) {
    return createAccessorFieldDescriptor(propertyKey, descriptor) as unknown as void;
  }
  return createPlainFieldDescriptor(propertyKey) as unknown as void;
}
