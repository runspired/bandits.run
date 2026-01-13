import { assert } from "@ember/debug";

export function both(a: unknown, b: unknown): boolean {
  return !!(a && b);
}

/**
 * Logical OR operation: returns the first truthy param
 * or the last param if all are falsy
 */
export function or(...args: unknown[]): boolean {
    assert(
    `You must pass at least two params to the or helper`,
    args.length > 1
  );
  return args.some(Boolean);
}

/**
 * Logical NOR operation: returns true if all params are falsy
 */
export function nor(...args: unknown[]): boolean {
  assert(
    `You must pass at least two params to the nor helper`,
    args.length > 1
  );
  return args.every((arg) => !arg);
}

export function eq(a: unknown, b: unknown): boolean {
  return a === b;
}

export function neq(a: unknown, b: unknown): boolean {
  return a !== b;
}

export function and(...args: unknown[]): boolean {
  return args.every(Boolean);
}

export function not(value: unknown): boolean {
  return !value;
}

export function ifEven<A, B>(v: number, a: A, b: B): A | B {
  return v % 2 === 0 ? a : b;
}

export function excludeNull<T>(value: T | null): T {
  assert('Value is not null', value !== null);
  return value;
}
