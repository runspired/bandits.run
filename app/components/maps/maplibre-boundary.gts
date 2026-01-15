import type { TOC } from '@ember/component/template-only';
import { assert } from '@ember/debug';
import { Await } from '@warp-drive/ember';
import type maplibregl from 'maplibre-gl';

let MapLibre: typeof maplibregl | null = null;

export async function loadMapLibre() {
  await import('maplibre-gl/dist/maplibre-gl.css');
  const maplibre = await import('maplibre-gl');
  MapLibre = maplibre.default;
  return maplibre.default;
}

export function getMapLibre() {
  assert(`Expected MapLibre to be loaded`, MapLibre !== null);
  return MapLibre;
}

<template>
  <Await @promise={{(loadMapLibre)}}>
    <:pending>
      <div>Loading map...</div>
    </:pending>
    <:error>
      <div>Error loading map.</div>
    </:error>
    <:success>
      {{yield}}
    </:success>
  </Await>
</template> satisfies TOC<{
  Blocks: {
    default: [];
  };
}>;
