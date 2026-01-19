import { assert } from "@ember/debug";
import type { ParamConfig } from './params';

import { getLocalStorage, getSessionStorage } from '../reactive/storage';
import { dependentKeyCompat } from '@ember/object/compat';
import { isDevelopingApp, macroCondition } from "@embroider/macros";

const debugStorage = false;

interface InternalParamConfig extends ParamConfig {
  initialized?: boolean;
}

export interface ValueTransition<T = unknown> {
  key: string;
  from: T;
  to: T;
}

/**
 * Metadata attached to persisted resource classes
 */
export interface StorageResourceMeta {
  id: string;
  pkFn: KeyFn | null;
  type: 'local-resource' | 'session-resource';
  typeOverrides: Map<string, 'local-storage' | 'session-storage'> | null;
  fields: Map<string, null | ((update: ValueTransition<string>) => void)>;
  initializers: Map<string, (() => unknown) | null>;
  paramConfigs: Map<string, InternalParamConfig> | null;
  paramCompanion: object | null;
  instances: WeakMap<object, StorageResourceMeta> | null;
}

/**
 * A function which generates a unique primary-key
 * string for a given LocalResource or SessionResource
 * instance.
 *
 * Use functions when you want to create more than
 * one instance of a resource type, each with its own
 * persisted data.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type KeyFn = (obj: any) => string;



/**
 * Symbol used to store persistence metadata on classes
 */
const PERSISTED_RESOURCE_META = Symbol('StorageResourceMeta');

/**
 * Setup persisted resource metadata on target
 * if not already present
 */
export function initMeta(target: object): StorageResourceMeta {
  let meta = (target as Record<symbol, StorageResourceMeta>)[PERSISTED_RESOURCE_META];
  if (!meta) {
    meta = {
      id: '',
      pkFn: null,
      type: '' as 'local-resource' | 'session-resource',
      fields: new Map(),
      initializers: new Map(),
      paramConfigs: null,
      paramCompanion: null,
      instances: null,
      typeOverrides: null,
    };
    (target as Record<symbol, StorageResourceMeta>)[PERSISTED_RESOURCE_META] = meta;
  }
  return meta;
}

export function useMeta(meta: StorageResourceMeta, instance: object): StorageResourceMeta {
  // If a primary key function is defined, use it to generate
  // a unique ID for this instance
  if (meta.id === '' && meta.pkFn) {
    // we are in an instance context
    meta.instances = meta.instances ?? new WeakMap();
    let instanceMeta = meta.instances.get(instance);
    if (!instanceMeta) {
      instanceMeta = { ...meta };
      const pk = meta.pkFn(instance);
      assert('Primary key function must return a non-empty string.', typeof pk === 'string' && pk.length > 0);
      instanceMeta.id = pk;
      meta.instances.set(instance, instanceMeta);
    }
    return instanceMeta;
  }

  assert('StorageResourceMeta must have a valid id.', typeof meta.id === 'string' && meta.id.length > 0);
  return meta;
}

/**
 * Load storage field
 */
export function getField(meta: StorageResourceMeta, key: string, overrideType: 'local-storage' | 'session-storage' | null): Record<string, unknown> | null {
  const type = overrideType || meta.type;
  const storage = type === 'local-resource' ? getLocalStorage() : getSessionStorage();
  const stored = storage.getItem(keyFor(meta, key));
  if (macroCondition(isDevelopingApp())) {
    if (debugStorage) {
      console.log(`field.get(${meta.id}:${key})`, stored ? JSON.parse(stored) : null);
    }
  }
  if (stored) {
    return JSON.parse(stored) as Record<string, unknown>;
  } else {
    // No stored value, check for initializer
    const initializer = meta.initializers.get(key);
    if (initializer) {
      const value = initializer();
      if (value !== undefined) {
        return value as Record<string, unknown>;
      }
    }
  }
  return null;
}

function keyFor(meta: StorageResourceMeta, key: string): string {
  return `persisted:${meta.id}:${key}`;
}

export function peekField(meta: StorageResourceMeta, key: string, overrideType: 'local-storage' | 'session-storage' | null): unknown {
  const type = overrideType || meta.type;
  const storage = type === 'local-resource' ? getLocalStorage() : getSessionStorage();
  const stored = storage.peekItem(keyFor(meta, key));
  if (macroCondition(isDevelopingApp())) {
    if (debugStorage) {
      console.log(`field.get(${meta.id}:${key})`, stored ? JSON.parse(stored) : null);
    }
  }
  if (stored) {
    return JSON.parse(stored) as Record<string, unknown>;
  }
  return null;
}

export function initializeFields(instance: object, source: object): void {
  // we need to initialize the fields without reading from their reactive state
  // we also only want to initialize the field if it is still at its default value
  // as otherwise we are likely overwriting a persisted value or url value
  const baseMeta = getResourceMeta(instance);
  const meta = useMeta(baseMeta, instance);

  for (const [key, _] of meta.fields.entries()) {
    if (key in source) {
      // get the new value from source
      const newValue = (source as Record<string, unknown>)[key];

      // get the current default value from the field initializer
      const initializer = meta.initializers.get(key);
      let defaultValue: unknown = null;
      if (initializer) {
        defaultValue = initializer.call(instance);
      }

      // get the overrideType
      const overrideType = meta.typeOverrides?.get(key) ?? null;
      const type = overrideType || meta.type;

      // get the current stored value, without triggering reactivity
      const currentValue = peekField(meta, keyFor(meta, key), overrideType);

      // if there is no current value, silently update the field
      const storage = type === 'local-resource' ? localStorage : sessionStorage;
      storage.setItem(keyFor(meta, key), JSON.stringify(newValue));
      // only initialize if current value matches default value
      // or we have no persisted value yet.
      if (currentValue === defaultValue) {
        setField(meta, keyFor(meta, key), newValue as string, overrideType);
      }
    }
  }
}

/**
 * Update storage field
 */
export function setField(meta: StorageResourceMeta, key: string, value: string | boolean | null | number | Record<string, unknown> | unknown[], overrideType: 'local-storage' | 'session-storage' | null): void {
  const type = overrideType || meta.type;
  const storage = type === 'local-resource' ? getLocalStorage() : getSessionStorage();
  storage.setItem(keyFor(meta, key), JSON.stringify(value));
   if (macroCondition(isDevelopingApp())) {
    if (debugStorage) {
      console.log(`field.set(${meta.id}:${key})`, JSON.stringify(value));
    }
  }
}

function getResourceMeta(target: object): StorageResourceMeta {
  const meta = (target as Record<symbol, StorageResourceMeta>)[PERSISTED_RESOURCE_META];
  assert('StorageResourceMeta not found on target. Did you forget to use the @LocalResource() or @SessionResource() decorator?', meta !== undefined);
  return meta;
}

export function _createStorageResource(id: string | KeyFn, type: 'local-resource' | 'session-resource'): ClassDecorator {
  // eslint-disable-next-line @typescript-eslint/no-unsafe-function-type
  return function (target: Function) {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
    const meta = getResourceMeta(target.prototype);
    meta.id = typeof id === 'string' ? id : '';
    meta.pkFn = typeof id === 'function' ? id : null;
    meta.type = type;
    if (meta.pkFn !== null) {
        // for dynamic instances, we install effects only once
        // fields have been defined and a key created for the
        // instance.
        // for this, we defer effect installation until
        // until object instantiation by wrapping the constructor
        // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access
        const originalConstructor = target.prototype.constructor;
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
        target.prototype.constructor = function DynamicStorageInitializer(...args: unknown[]) {
          // eslint-disable-next-line @typescript-eslint/no-unsafe-call
          const instance = new originalConstructor(...args) as object;
          void installEffectsForDynamicInstance(meta, instance);
          return instance;
        };
    }
  };
}

async function installEffectsForDynamicInstance(meta: StorageResourceMeta, instance: object): Promise<void> {
  await Promise.resolve();
  for (const [key, value] of meta.fields.entries()) {
    if (typeof value === 'function') {
      void installEffect(useMeta(meta, instance), key);
    }
  }
}

export function setupField(
  target: object,
  key: string,
  orgDesc?: PropertyDescriptor,
  type?: 'local' | 'session'
): void {
  const meta = initMeta(target);
  meta.fields.set(key, null);
  const overrideType = type === 'local' ? 'local-storage' : type === 'session' ? 'session-storage' : null;
  if (overrideType) {
    meta.typeOverrides = meta.typeOverrides || new Map<string, 'local-storage' | 'session-storage'>();
    meta.typeOverrides.set(key, overrideType);
  }
  // @ts-expect-error initializer does exist
  const initializer = (orgDesc?.initializer || null) as (() => unknown) | null;
  meta.initializers.set(key, initializer);

  const desc = {
    configurable: true,
    enumerable: true,
    get(this: object): unknown {
      return getField(useMeta(meta, this), key, overrideType);
    },
    set(this: object, value: unknown) {
      setField(useMeta(meta, this), key, value as string, overrideType);
    },
  };

  return dependentKeyCompat(target, key, desc) as unknown as void;
}

export async function installEffect(meta: StorageResourceMeta, key: string): Promise<void> {
  await Promise.resolve();
  const effect = meta.fields.get(key) as <K>(v: ValueTransition<K>) => void;
  const storage = meta.type === 'local-resource' ? getLocalStorage() : getSessionStorage();
  storage.setEffect(keyFor(meta, key), (event: StorageEvent) => {
    const oldValue = event.oldValue ? JSON.parse(event.oldValue) as unknown : null;
    const newValue = event.newValue ? JSON.parse(event.newValue) as unknown : null;
    effect({ key, from: oldValue, to: newValue });
  });
}

/**
 * Get or create the param companion object for a StorageResource instance.
 *
 * The companion object contains URL-serialized versions of all @param decorated fields.
 * Each param field gets a corresponding property on the companion that:
 * - Reads: Serializes the storage value to a URL string (returns null if not active)
 * - Writes: Deserializes the URL string and updates the storage value
 *
 * The companion object is reactive using trackedObject, ensuring that changes
 * to the underlying storage fields trigger updates in the query param system.
 *
 * This companion object is what QPRoute will bind to for URL query params.
 *
 * @param instance - The StorageResource instance
 * @param groupControlMap - Optional map of fieldName -> controlFieldName for grouped params
 * @returns The companion object with serialized param properties
 */
export function getParamCompanion(instance: object, groupControlMap?: Record<string, string>): object {
  const meta = getResourceMeta(instance);
  const instanceMeta = useMeta(meta, instance);

  // Return existing companion if already created
  if (instanceMeta.paramCompanion) {
    return instanceMeta.paramCompanion;
  }

  // Create new companion object
  const companion = {};
  instanceMeta.paramCompanion = companion;

  // Install a property for each param
  const paramConfigs = instanceMeta.paramConfigs;
  if (!paramConfigs || paramConfigs.size === 0) {
    return companion;
  }

  for (const [fieldName, config] of paramConfigs.entries()) {
    const controlFieldName = groupControlMap?.[fieldName];

    createParamField(companion, fieldName, config, controlFieldName, instance, meta);
  }

  return companion;
}

function isActiveGroupParam(companion: object, controlFieldName: string): boolean {
  // if the url value for the control param is `null` we are inactive
  const controlValue = (companion as Record<string, unknown>)[controlFieldName];
  return controlValue !== null;
}

/**
 * The default value of a param is determined by:
 * - the getDefault() function if provided, and its return is not undefined
 * - the initializer value provided to the field, if not undefined
 * - null otherwise
 *
 * The value is the deserialized form (i.e., the local storage value type)
 */
function getParamFieldDefaultValue(meta: StorageResourceMeta, config: ParamConfig, fieldName: string, instance: object) {
  const defaultValue = config.getDefault?.(instance);
  if (defaultValue !== undefined) {
    if (macroCondition(isDevelopingApp())) {
      if (debugStorage) {
        console.log(`param(${meta.id}:${fieldName}) default from getDefault():`, defaultValue);
      }
    }
    return defaultValue;
  }

  const initializer = meta.initializers.get(fieldName);
  if (initializer) {
    const initValue = initializer.call(instance);

    if (initValue !== undefined) {
      if (macroCondition(isDevelopingApp())) {
        if (debugStorage) {
          console.log(`param(${meta.id}:${fieldName}) default from initializer():`, initValue);
        }
      }
      return initValue;
    }
  }

  if (macroCondition(isDevelopingApp())) {
    if (debugStorage) {
      console.log(`param(${meta.id}:${fieldName}) default value is null a no undefined value was provided by either getDefault() or initializer().`);
    }
  }
  return null;
}

function createParamField(companion: object, fieldName: string, config: InternalParamConfig, controlFieldName: string | undefined, instance: object, meta: StorageResourceMeta): void {
  const desc = {
    configurable: true,
    enumerable: true,
    get(): string | null {
      // Mark as initialized on first access, but continue with normal logic
      if (!config.initialized) {
        config.initialized = true;
        if (macroCondition(isDevelopingApp())) {
          if (debugStorage) {
            console.log(`param(${meta.id}:${fieldName}) initializing companion field to 'null'`);
          }
        }
        return null;
      }

      // Next, check if this param is part of a group and if its control param is active
      // If not active, return null to indicate inactive state
      if (controlFieldName && !isActiveGroupParam(companion, controlFieldName)) {
        if (macroCondition(isDevelopingApp())) {
          if (debugStorage) {
            console.log(`param(${meta.id}:${fieldName}) is inactive because group control ${controlFieldName} is inactive.`);
          }
        }
        return null;
      }

      // Next, check if the currently stored value is the default
      // value. If so, return null to indicate inactive state
      const defaultValue = getParamFieldDefaultValue(meta, config, fieldName, instance);
      const rawValue = (instance as Record<string, unknown>)[fieldName];

      if (rawValue === defaultValue) {
        if (macroCondition(isDevelopingApp())) {
          if (debugStorage) {
            console.log(`param(${meta.id}:${fieldName}) is inactive because current value matches default.`);
          }
        }
        return null;
      }

      // Serialize to URL format
      const serialized = config.serialize(rawValue, instance);

      // Return null if serialization returns empty, indicating no URL representation
      if (!serialized) {
        if (macroCondition(isDevelopingApp())) {
          if (debugStorage) {
            console.log(`param(${meta.id}:${fieldName}) is inactive because serialization returned empty.`);
          }
        }
        return null;
      }

      if (macroCondition(isDevelopingApp())) {
        if (debugStorage) {
          console.log(`param(${meta.id}:${fieldName}) is active with serialized value:`, serialized);
        }
      }
      return serialized;
    },
    set(urlValue: string | null) {
      /**
       * set will never come from anything except URL deserialization.
       * which is managed by Ember.
       *
       * Our job is to not unnecessarily update the storage resource
       * so we need to run the compare function to see if the
       * incoming URL value is different from the existing local value.
       */

      // If null or empty, skip deserialization
      if (!urlValue) {
        if (macroCondition(isDevelopingApp())) {
          if (debugStorage) {
            console.log(`param(${meta.id}:${fieldName}) set was ignored because urlValue is empty.`);
          }
        }
        return;
      }

      const rawValue = (instance as Record<string, unknown>)[fieldName];

      // Compare incoming URL value with existing local value
      const rawValueSerialized = config.serialize(rawValue, instance);
      if (rawValueSerialized === urlValue) {
        if (macroCondition(isDevelopingApp())) {
          if (debugStorage) {
            console.log(`param(${meta.id}:${fieldName}) set was ignored because urlValue matches existing value.`);
          }
        }
        // No change
        return;
      }

      // Deserialize from URL format
      const newRawValue = config.deserialize(urlValue, instance);

      if (macroCondition(isDevelopingApp())) {
        if (debugStorage) {
          console.log(`param(${meta.id}:${fieldName}) set is updating storage value to:`, newRawValue);
        }
      }

      // Update the storage resource
      (instance as Record<string, unknown>)[fieldName] = newRawValue;
    }
  };

  const newDesc = dependentKeyCompat(companion, fieldName, desc);
  Object.defineProperty(companion, fieldName, newDesc);
}
