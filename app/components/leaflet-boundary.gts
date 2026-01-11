import type { TOC } from '@ember/component/template-only';
import { assert } from '@ember/debug';
import { Await } from '@warp-drive/ember';

let Leaflet: typeof import('leaflet') | null = null;
export async function loadLeaflet() {
  await import('leaflet/dist/leaflet.css');
  const L = await import('leaflet');
  Leaflet = L;

  initializeLeafletGestures();
  return L;
}

export function getLeaflet() {
  assert(`Expected Leaflet to be loaded`, Leaflet !== null);
  return Leaflet;
}

let initialized = false;
function initializeLeafletGestures(
  config: { duration: string; text: string } = { duration: '', text: '' }
) {
  if (initialized) return;
  initialized = true;
  const leaf = typeof window.L === 'undefined' ? {} : window.L;

  const options = {
    gestureHandling: true,
    gestureHandlingOptions: null,
  };

  if (!isNaN(parseInt(config.duration))) {
    // @ts-expect-error fuck it
    options.gestureHandlingOptions = { duration: config.duration };
  }

  if (config.text) {
    options.gestureHandlingOptions = Object.assign(
      { text: config.text },
      options.gestureHandlingOptions
    );
  }

  // @ts-expect-error fuck it
  // eslint-disable-next-line @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access
  leaf.Map.mergeOptions(options);

  // leaf.Map.addInitHook("addHandler", "gestureHandling", GestureHandling);
}

<template>
  <Await @promise={{(loadLeaflet)}}>
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
