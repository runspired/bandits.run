import { assert } from '@ember/debug';
import { getLocalStorage, getSessionStorage } from '../reactive/storage';
import { dependentKeyCompat } from '@ember/object/compat';

/**
 * Symbol used to store persistence metadata on classes
 */
const PERSISTED_RESOURCE_META = Symbol('StorageResourceMeta');

/**
 * Setup persisted resource metadata on target
 * if not already present
 */
function initMeta(target: object): StorageResourceMeta {
  let meta = (target as Record<symbol, StorageResourceMeta>)[PERSISTED_RESOURCE_META];
  if (!meta) {
    meta = {
      id: '',
      pkFn: null,
      type: '' as 'local-resource' | 'session-resource',
      fields: new Map(),
      params: null,
      instances: null,
    };
    (target as Record<symbol, StorageResourceMeta>)[PERSISTED_RESOURCE_META] = meta;
  }
  return meta;
}

export interface ValueTransition<T = unknown> {
  key: string;
  from: T;
  to: T;
}

/**
 * Metadata attached to persisted resource classes
 */
interface StorageResourceMeta {
  id: string;
  pkFn: KeyFn | null;
  type: 'local-resource' | 'session-resource';
  fields: Map<string, null | ((update: ValueTransition<string>) => void)>;
  params: Set<string> | null;
  instances: WeakMap<object, StorageResourceMeta> | null;
}

function useMeta(meta: StorageResourceMeta, instance: object): StorageResourceMeta {
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
function getField(meta: StorageResourceMeta, key: string, overrideType: 'local-storage' | 'session-storage' | null): Record<string, unknown> | null {
  const type = overrideType || meta.type;
  const storage = type === 'local-resource' ? getLocalStorage() : getSessionStorage();
  const stored = storage.getItem(`persisted:${meta.id}:${key}`);
  if (stored) {
    //console.log(`field load for persisted:${meta.id}:${key} => `, stored);
    return JSON.parse(stored) as Record<string, unknown>;
  }
  return null;
}

/**
 * Update storage field
 */
function setField(meta: StorageResourceMeta, key: string, value: string | boolean | null | number | Record<string, unknown> | unknown[], overrideType: 'local-storage' | 'session-storage' | null): void {
  const type = overrideType || meta.type;
  const storage = type === 'local-resource' ? getLocalStorage() : getSessionStorage();
  // console.log(`field save for persisted:${meta.id}:${key} => `, value);
  storage.setItem(`persisted:${meta.id}:${key}`, JSON.stringify(value));
}

function getResourceMeta(target: object): StorageResourceMeta {
  const meta = (target as Record<symbol, StorageResourceMeta>)[PERSISTED_RESOURCE_META];
  assert('StorageResourceMeta not found on target. Did you forget to use the @LocalResource() or @SessionResource() decorator?', meta !== undefined);
  return meta;
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
type KeyFn = (obj: any) => string;

/**
 * Decorator which transforms a class into a StorageResource
 * persisted in localStorage.
 *
 * LocalResources must either be singletons or expect all instances
 * to share state unless a primary key function is provided.
 *
 * When a primary key function is provided, each instance
 * will have its own persisted data based on the key generated
 * by the function.
 *
 * The function will be called once per instance during
 * initialization to determine the unique ID for that instance.
 */
export function LocalResource(id: string | KeyFn): ClassDecorator {
  return _createStorageResource(id, 'local-resource');
}

/**
 * Decorator which transforms a class into a StorageResource
 * persisted in sessionStorage.
 *
 * SessionResources must either be singletons or expect all instances
 * to share state unless a primary key function is provided.
 *
 * When a primary key function is provided, each instance
 * will have its own persisted data based on the key generated
 * by the function.
 *
 * The function will be called once per instance during
 * initialization to determine the unique ID for that instance.
 */
export function SessionResource(id: string | KeyFn): ClassDecorator {
  return _createStorageResource(id, 'session-resource');
}

function _createStorageResource(id: string | KeyFn, type: 'local-resource' | 'session-resource'): ClassDecorator {
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
          debugger;
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

/**
 * Decorator which marks a property as a field on
 * a LocalResource or SessionResource
 *
 * The field's value will be initialized from the persisted resource data
 * if available, falling back to the property's default value otherwise.
 *
 * Fields can be of any type that is serializable to and restorable from JSON,
 * but complex types (like objects or arrays) should be handled with care to avoid
 * unintended mutations or reactivity issues.
 *
 * By default, fields are persisted in the storage type defined by the resource decorator
 * (@LocalResource or @SessionResource). However, you can override this behavior
 * by passing 'local' or 'session' as an argument to the decorator.
 *
 * ---
 *
 * **Example:**
 *
 * ```ts
 * @LocalResource('user-settings')
 * class UserSettings {
 *   @field
 *   theme: 'light' | 'dark' = 'light';
 *
 *   @field('session')
 *   sessionToken: string | null = null;
 * }
 * ```
 *
 */
export function field(type: 'local' | 'session'): PropertyDecorator;
export function field(target: object, key: string, descriptor?: PropertyDescriptor): void;
export function field(...args: unknown[]): PropertyDecorator | void {
  if (args.length === 0) {
    assert('field decorator requires at least 1 argument or should be used without parens', true);
    return setupField as PropertyDecorator;
  }
  if (args.length === 1) {
    return setupField as PropertyDecorator;
  }
  if (args.length === 2 || args.length === 3) {
    const [target, key, descriptor] = args as [object, string, PropertyDescriptor | undefined];
    return setupField(target, key, descriptor);
  }
}

export function input(type: 'number' | 'boolean' | 'float'): PropertyDecorator {
  assert('input decorator requires a valid type argument', ['number', 'boolean', 'float'].includes(type));
  return function (
    target: object,
    key: string,
    desc: PropertyDescriptor
  ): void {
    // eslint-disable-next-line @typescript-eslint/unbound-method
    const originalSet = desc.set!;
    desc.set = function (this: object, value: unknown) {
      switch (type) {
        case 'number':
          value = Number(value);
          break;
        case 'boolean':
          value = value === 'false' || value === '' || value === '0' || value === 'undefined' || value === 'null' || value === false || value === 0 || value === null || value === undefined ? 0 : 1;
          break;
        default:
          assert(`Unsupported input type: ${type}`);
      }
      originalSet.call(this, value);
    }
    return desc as unknown as void;
  } as PropertyDecorator;
}

function setupField(
  target: object,
  key: string,
  _descriptor?: PropertyDescriptor,
  type?: 'local' | 'session'
): void {
  const meta = initMeta(target);
  meta.fields.set(key, null);
  const overrideType = type === 'local' ? 'local-storage' : type === 'session' ? 'session-storage' : null;

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

/**
 * Effects are fields that run a side-effecting function.
 *
 * Effects are intended to enable synchronizing get states between
 * tabs or windows that result in needing to synchronize other
 * non-reactive state.
 *
 * For example, when a user selects a light/dark mode theme preference
 * that differs from the system preference, effects can be used to trigger
 * DOM updates on the documentElement necessary to ensure its state is
 * consistent with the persisted resource state and reactive application state.
 *
 * To do this without an effect would require either setting up your own
 * storage event listeners or consuming the reactive state of the property
 * in another effect-like API such as an Ember modifier or React useEffect,
 *
 * Effects *only* run when the stored value changes due to storage events
 * emitted from other tabs or windows. They do not run when the property
 * is updated in the same context.
 *
 * ---
 *
 * **Example:**
 *
 * ```ts
 * @LocalResource('user-preferences')
 * class UserPreferences {
 *   @effect(syncThemeToDOM)
 *   explicitThemePreference: 'light' | 'dark' | null = null;
 *
 *   @matchMedia('(prefers-color-scheme: dark)')
 *   systemPrefersDarkMode: boolean = false;
 * }
 *
 * function syncThemeToDOM(update: ValueTransition<'light' | 'dark' | null>): void {
 *   const newTheme = update.to;
 *   document.documentElement.style.colorScheme = newTheme ?? 'light dark';
 *
 *   if (newTheme === 'dark') {
 *     document.documentElement.classList.add('dark-theme');
 *     document.documentElement.classList.remove('light-theme');
 *   } else if (newTheme === 'light') {
 *     document.documentElement.classList.add('light-theme');
 *     document.documentElement.classList.remove('dark-theme');
 *   } else {
 *     document.documentElement.classList.remove('light-theme');
 *     document.documentElement.classList.remove('dark-theme');
 *   }
 * }
 * ```
 */
export function effect(fn: <K>(update: ValueTransition<K>) => void, type?: 'local' | 'session'): PropertyDecorator {
  const overrideType = type === 'local' ? 'local-storage' : type === 'session' ? 'session-storage' : null;
  return function effectField(
    target: object,
    key: string,
    _descriptor?: PropertyDescriptor
    ): void {
    const meta = initMeta(target);
    meta.fields.set(key, fn);

    // only install the effect if we are not in a primary-keyed instance context
    if (meta.pkFn === null)
      void installEffect(meta, key);

    return {
      configurable: true,
      enumerable: true,
      get(this: object): unknown {
        return getField(useMeta(meta, this), key, overrideType);
      },
      set(this: object, value: unknown) {
        setField(useMeta(meta, this), key, value as string, overrideType);
      },
    } as unknown as void;
  } as unknown as PropertyDecorator;
}

async function installEffect(meta: StorageResourceMeta, key: string): Promise<void> {
  await Promise.resolve();
  const effect = meta.fields.get(key) as <K>(v: ValueTransition<K>) => void;
  const storage = meta.type === 'local-resource' ? getLocalStorage() : getSessionStorage();
  storage.setEffect(`persisted:${meta.id}:${key}`, (event: StorageEvent) => {
    const oldValue = event.oldValue ? JSON.parse(event.oldValue) as unknown : null;
    const newValue = event.newValue ? JSON.parse(event.newValue) as unknown : null;
    effect({ key, from: oldValue, to: newValue });
  });
}
