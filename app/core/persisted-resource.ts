import { assert } from '@ember/debug';
import { getLocalStorage } from './reactive-storage';
import { get } from '@ember/helper';

/**
 * Symbol used to store persistence metadata on classes
 */
const PERSISTED_RESOURCE_META = Symbol('PersistedResourceMeta');

function initMeta(target: object): PersistedResourceMeta {
  let meta = (target as Record<symbol, PersistedResourceMeta>)[PERSISTED_RESOURCE_META];
  if (!meta) {
    meta = {
      id: '',
      fields: new Set(),
    };
    (target as Record<symbol, PersistedResourceMeta>)[PERSISTED_RESOURCE_META] = meta;
  }
  return meta;
}

/**
 * Metadata attached to persisted resource classes
 */
interface PersistedResourceMeta {
  id: string;
  fields: Set<string>;
}

/**
 * Load persisted field
 */
function getField(id: string, key: string): Record<string, unknown> | null {
  const stored = getLocalStorage().getItem(`persisted:${id}:${key}`);
  if (stored) {
    return JSON.parse(stored) as Record<string, unknown>;
  }
  return null;
}
/**
 * Update persisted field
 */
function setField(id: string, key: string, value: string | boolean | null | number | Record<string, unknown> | unknown[]): void {
  getLocalStorage().setItem(`persisted:${id}:${key}`, JSON.stringify(value));
}

function getResourceMeta(target: object): PersistedResourceMeta {
  const meta = (target as Record<symbol, PersistedResourceMeta>)[PERSISTED_RESOURCE_META];
  assert('PersistedResourceMeta not found on target. Did you forget to add @PersistedResource() decorator?', meta !== undefined);
  return meta;
}

/**
 * Decorator which transforms a class into a persisted resource.
 *
 * Persisted resources must be singletons.
 */
export function PersistedResource(id: string): ClassDecorator {
  // eslint-disable-next-line @typescript-eslint/no-unsafe-function-type
  return function (target: Function) {
    getResourceMeta(target.prototype).id = id;
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
 */
export function field(
  target: object,
  key: string,
  _descriptor?: PropertyDescriptor
): void {
  const meta = initMeta(target);
  meta.fields.add(key);

  return {
    configurable: true,
    enumerable: true,
    get(this: object): unknown {
      return getField(meta.id, key);
    },
    set(this: object, value: unknown) {
      setField(meta.id, key, value as string);
    },
  } as unknown as void;
}
