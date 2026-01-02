export interface Location {
  name: string;
  latitude: number | null;
  longitude: number | null;
  region: string | null;
  address: Address | null;
  googleMapsLink: string | null;
}

export interface Address {
  street: string;
  city: string;
  state: string;
  zip: string;
}
