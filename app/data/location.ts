import { withDefaults } from "@warp-drive/core/reactive";
import { objectSchema } from "@warp-drive/core/types/schema/fields";
import type { Type } from "@warp-drive/core/types/symbols";

export interface Address {
  street: string;
  city: string;
  state: string;
  zip: string;
}

export interface Location {
  id: string;
  $type: 'location';
  name: string;
  latitude: number | null;
  longitude: number | null;
  region: string | null;
  address: Address | null;
  googleMapsLink: string | null;
  [Type]: 'location';
}

export const LocationSchema = withDefaults({
  type: 'location',
  fields: [
    { name: 'name', kind: 'field' },
    { name: 'latitude', kind: 'field' },
    { name: 'longitude', kind: 'field' },
    { name: 'region', kind: 'field' },
    { name: 'address', kind: 'schema-object', type: 'address' },
    { name: 'googleMapsLink', kind: 'field' },
  ]
});

export const AddressObjectSchema = objectSchema({
  type: 'address',
  identity: null,
  fields: [
    { name: 'street', kind: 'field' },
    { name: 'city', kind: 'field' },
    { name: 'state', kind: 'field' },
    { name: 'zip', kind: 'field' },
  ]
})
