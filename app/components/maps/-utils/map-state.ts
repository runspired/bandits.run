import {
  field,
  SessionResource,
} from "../../../core/utils/storage-resource";
import {
  param,
  BooleanParam,
  NumberParam,
} from "../../../core/utils/params";
import { tracked } from "@glimmer/tracking";
import { assert } from "@ember/debug";
import { initializeFields } from "#app/core/utils/-storage-infra.ts";

interface CoordSource {
  lat: number;
  lng: number;
}

const RedwoodRegionalPark: CoordSource = {
  lat: 37.800704,
  lng: -122.144621,
};
const CoordPrecision = 5;

@SessionResource((map: MapState) => `map-state:${map.id}`)
class MapState {
  id: string;
  @tracked source: CoordSource | null = null;
  #initialized: boolean = false;

  constructor(id: string) {
    this.id = id;
  }

  @param(BooleanParam())
  @field
  active: boolean = false;

  @param(NumberParam(
    2
  ))
  @field
  zoom: number = 14;

  @param(NumberParam(
    CoordPrecision,
    (instance: MapState) => instance.source?.lat,
  ))
  @field
  lat: number = RedwoodRegionalPark.lat;

  @param(NumberParam(
    CoordPrecision,
    (instance: MapState) => instance.source?.lng,
  ))
  @field
  lng: number = RedwoodRegionalPark.lng;

  initialize(source: CoordSource) {
    assert(`MapState cannot be reinitialized once source has been set`, this.#initialized === false);
    initializeFields(this, source);
    this.source = source;
    this.#initialized = true;
  }
}

export { MapState };
