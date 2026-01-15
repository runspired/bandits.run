# MapLibre GL JS Integration

This project now uses MapLibre GL JS for rendering vector map tiles from OpenStreetMap US.

## Components

### MapLibreBoundary
Handles async loading of MapLibre GL JS library and styles.

### MapLibreMap
Main map component that renders vector tiles.

### MapLibreMarker
Component for adding markers to the map.

### MapLibreBackgroundMap
Pre-configured component for static background maps.

## Usage Examples

### Basic Map with Vector Tiles

```gts
import MapLibreBoundary from '#maps/maplibre-boundary.gts';
import MapLibreMap from '#maps/maplibre-map.gts';
import MapLibreMarker from '#maps/maplibre-marker.gts';

<template>
  <MapLibreBoundary>
    <MapLibreMap
      @lat={{40.7128}}
      @lng={{-74.0060}}
      @zoom={{13}}
      as |map|
    >
      <MapLibreMarker
        @context={{map}}
        @lat={{40.7128}}
        @lng={{-74.0060}}
        @title="New York City"
      />
    </MapLibreMap>
  </MapLibreBoundary>
</template>
```

### Background Map (Non-interactive)

```gts
import MapLibreBackgroundMap from '#maps/maplibre-background-map.gts';

<template>
  <MapLibreBackgroundMap
    @lat={{40.7128}}
    @lng={{-74.0060}}
    @zoom={{12}}
    @markerTitle="Location Name"
  />
</template>
```

### Custom Styled Map

You can create your own style JSON or modify the default one at:
`/app/assets/map-styles/openstreetmap-us-vector.json`

```gts
<MapLibreMap
  @lat={{40.7128}}
  @lng={{-74.0060}}
  @zoom={{13}}
  @style="/assets/map-styles/custom-style.json"
  as |map|
>
  {{! Your markers and layers }}
</MapLibreMap>
```

### Using Custom Marker HTML

```gts
import MapLibreMarker from '#maps/maplibre-marker.gts';

export default class MyComponent extends Component {
  markerElement = null;

  createMarker = modifier((element) => {
    this.markerElement = element;
  });

  <template>
    <MapLibreBoundary>
      <MapLibreMap @lat={{@lat}} @lng={{@lng}} as |map|>
        <div {{this.createMarker}} style="display: none;">
          <div class="custom-marker">📍</div>
        </div>

        <MapLibreMarker
          @context={{map}}
          @lat={{@lat}}
          @lng={{@lng}}
          @element={{this.markerElement}}
        />
      </MapLibreMap>
    </MapLibreBoundary>
  </template>
}
```

## Vector Tile Sources

The default style uses OpenStreetMap US vector tiles:

- **Base Map**: `https://tiles.openstreetmap.us/vector/openmaptiles/{z}/{x}/{y}.mvt`
- **Trails**: `https://tiles.openstreetmap.us/vector/trails/{z}/{x}/{y}.mvt`
- **Contours**: `https://tiles.openstreetmap.us/vector/contours-feet/{z}/{x}/{y}.mvt`
- **Hillshade (raster)**: `https://tiles.openstreetmap.us/raster/hillshade/{z}/{x}/{y}.jpg`

## Style Customization

The style JSON at [/app/assets/map-styles/openstreetmap-us-vector.json](app/assets/map-styles/openstreetmap-us-vector.json) includes:

- Background and hillshade layers
- Land cover (grass, woods)
- Parks and natural areas
- Waterways and water bodies
- Buildings
- Contour lines (elevation)
- Roads and highways
- Trails (hiking paths)
- Place labels (cities, towns)

You can modify any layer properties following the [MapLibre Style Specification](https://maplibre.org/maplibre-style-spec/).

## Benefits of Vector Tiles

1. **Smaller file sizes** - Vector tiles are typically 20-50% smaller than raster tiles
2. **Smooth zooming** - Crisp rendering at any zoom level
3. **Dynamic styling** - Change colors, fonts, and visibility at runtime
4. **Better performance** - Hardware-accelerated WebGL rendering
5. **Rotation and 3D** - Rotate maps and add 3D terrain/buildings
6. **Data access** - Query map features and interact with individual elements

## Migration from Leaflet

To migrate existing Leaflet code:

1. Replace `LeafletBoundary` with `MapLibreBoundary`
2. Replace `LeafletMap` with `MapLibreMap`
3. Replace `LeafletMarker` with `MapLibreMarker`
4. Remove `@tileUrl` prop (now using vector style)
5. Update event handlers (MapLibre uses different event signatures)

### Event Handler Changes

**Leaflet:**
```gts
<LeafletMap
  @onClick={{this.handleClick}}
/>

handleClick = (event: L.LeafletMouseEvent) => {
  console.log(event.latlng.lat, event.latlng.lng);
}
```

**MapLibre:**
```gts
<MapLibreMap
  @onClick={{this.handleClick}}
/>

handleClick = (lng: number, lat: number) => {
  console.log(lat, lng);
}
```

## Resources

- [MapLibre GL JS Documentation](https://maplibre.org/maplibre-gl-js/docs/)
- [MapLibre Style Specification](https://maplibre.org/maplibre-style-spec/)
- [OpenStreetMap US Tileservice](https://tiles.openstreetmap.us/)
- [OpenTrailMap GitHub](https://github.com/osmus/OpenTrailMap)
