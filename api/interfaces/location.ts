export interface Location {
  name: string;
  latitude: number;
  longitude: number;
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
