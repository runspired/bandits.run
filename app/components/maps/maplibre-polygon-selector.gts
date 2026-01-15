import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';
import type { Map, MapMouseEvent, LngLat } from 'maplibre-gl';
import FaIcon from '#ui/fa-icon.gts';
import { faCropSimple, faCheck, faTimes, faTrash } from '@fortawesome/free-solid-svg-icons';
import './polygon-selector.css';

export interface PolygonPoint {
  lat: number;
  lng: number;
}

interface MapLibrePolygonSelectorSignature {
  Args: {
    /**
     * MapLibre map instance
     */
    map: Map;

    /**
     * Callback when polygon is complete
     */
    onPolygonComplete: (points: PolygonPoint[]) => void;

    /**
     * Callback when user cancels
     */
    onCancel: () => void;

    /**
     * Initial points for editing existing polygon
     */
    initialPoints?: PolygonPoint[] | null;
  };
}

/**
 * Interactive polygon drawing tool for MapLibre map crop selection
 *
 * Allows users to click on a map to define a custom polygon area for tile caching.
 * Features:
 * - Click to add points
 * - Hover preview of next point
 * - Visual feedback with line and fill
 * - Edit mode to move/delete points
 * - Complete or cancel actions
 */
export default class MapLibrePolygonSelector extends Component<MapLibrePolygonSelectorSignature> {
  @tracked points: PolygonPoint[] = this.args.initialPoints ?? [];
  @tracked isDrawing: boolean = true;
  @tracked draggedPointIndex: number | null = null;

  polygonSourceId = 'polygon-fill';
  polygonLayerId = 'polygon-fill-layer';
  lineSourceId = 'polygon-line';
  lineLayerId = 'polygon-line-layer';
  previewSourceId = 'polygon-preview';
  previewLayerId = 'polygon-preview-layer';
  pointsSourceId = 'polygon-points';
  pointsLayerId = 'polygon-points-layer';

  mapClickHandler: ((e: MapMouseEvent) => void) | null = null;
  mapMoveHandler: ((e: MapMouseEvent) => void) | null = null;
  mapMouseDownHandler: ((e: MapMouseEvent) => void) | null = null;
  mapMouseUpHandler: (() => void) | null = null;
  hasInitialPoints: boolean = (this.args.initialPoints?.length ?? 0) > 0;

  get canComplete(): boolean {
    return this.points.length >= 3;
  }

  get areaText(): string {
    if (this.points.length === 0) return 'Click on the map to start drawing';
    if (this.points.length === 1) return 'Add at least 2 more points';
    if (this.points.length === 2) return 'Add at least 1 more point';
    return `${this.points.length} points selected`;
  }

  setupPolygonDrawing = modifier((_element: HTMLElement) => {
    this.initializeDrawing();

    return () => {
      this.cleanup();
    };
  });

  initializeDrawing() {
    const map = this.args.map;

    // Add click handler for adding points
    this.mapClickHandler = (e: MapMouseEvent) => {
      // Check if we clicked on a point marker
      const features = map.queryRenderedFeatures(e.point, {
        layers: [this.pointsLayerId]
      });

      if (features.length > 0) {
        // Clicked on a point, don't add a new one
        return;
      }

      if (this.isDrawing && this.draggedPointIndex === null) {
        this.addPoint(e.lngLat.lat, e.lngLat.lng);
      }
    };
    map.on('click', this.mapClickHandler);

    // Add mousemove handler for preview and dragging
    this.mapMoveHandler = (e: MapMouseEvent) => {
      if (this.draggedPointIndex !== null) {
        // Update dragged point
        const newPoints = [...this.points];
        newPoints[this.draggedPointIndex] = {
          lat: e.lngLat.lat,
          lng: e.lngLat.lng
        };
        this.points = newPoints;
        this.renderPolygon();
      } else if (this.isDrawing && this.points.length > 0) {
        this.updatePreview(e.lngLat);
      }
    };
    map.on('mousemove', this.mapMoveHandler);

    // Add mousedown handler for starting drag
    this.mapMouseDownHandler = (e: MapMouseEvent) => {
      if (!this.isDrawing) {
        const features = map.queryRenderedFeatures(e.point, {
          layers: [this.pointsLayerId]
        });

        if (features.length > 0) {
          e.preventDefault();
          const index = features[0]?.properties?.index;
          if (typeof index === 'number') {
            this.draggedPointIndex = index;
            map.getCanvas().style.cursor = 'grabbing';
          }
        }
      }
    };
    map.on('mousedown', this.mapMouseDownHandler);

    // Add mouseup handler for ending drag
    this.mapMouseUpHandler = () => {
      if (this.draggedPointIndex !== null) {
        this.draggedPointIndex = null;
        map.getCanvas().style.cursor = '';
      }
    };
    map.on('mouseup', this.mapMouseUpHandler);

    // Add cursor styling for point markers
    map.on('mouseenter', this.pointsLayerId, () => {
      if (!this.isDrawing) {
        map.getCanvas().style.cursor = 'grab';
      }
    });
    map.on('mouseleave', this.pointsLayerId, () => {
      if (!this.isDrawing && this.draggedPointIndex === null) {
        map.getCanvas().style.cursor = '';
      }
    });

    // Initialize sources and layers
    this.initializeLayers();

    // If we have initial points, render them in edit mode
    if (this.hasInitialPoints) {
      this.isDrawing = false;
      this.renderPolygon();
    }
  }

  initializeLayers() {
    const map = this.args.map;

    // Add polygon fill source and layer
    if (!map.getSource(this.polygonSourceId)) {
      map.addSource(this.polygonSourceId, {
        type: 'geojson',
        data: {
          type: 'Feature',
          geometry: {
            type: 'Polygon',
            coordinates: []
          },
          properties: {}
        }
      });
    }

    if (!map.getLayer(this.polygonLayerId)) {
      map.addLayer({
        id: this.polygonLayerId,
        type: 'fill',
        source: this.polygonSourceId,
        paint: {
          'fill-color': '#3b82f6',
          'fill-opacity': 0.2
        }
      });
    }

    // Add polygon line source and layer
    if (!map.getSource(this.lineSourceId)) {
      map.addSource(this.lineSourceId, {
        type: 'geojson',
        data: {
          type: 'Feature',
          geometry: {
            type: 'LineString',
            coordinates: []
          },
          properties: {}
        }
      });
    }

    if (!map.getLayer(this.lineLayerId)) {
      map.addLayer({
        id: this.lineLayerId,
        type: 'line',
        source: this.lineSourceId,
        paint: {
          'line-color': '#3b82f6',
          'line-width': 2
        }
      });
    }

    // Add preview line source and layer
    if (!map.getSource(this.previewSourceId)) {
      map.addSource(this.previewSourceId, {
        type: 'geojson',
        data: {
          type: 'Feature',
          geometry: {
            type: 'LineString',
            coordinates: []
          },
          properties: {}
        }
      });
    }

    if (!map.getLayer(this.previewLayerId)) {
      map.addLayer({
        id: this.previewLayerId,
        type: 'line',
        source: this.previewSourceId,
        paint: {
          'line-color': '#3b82f6',
          'line-width': 2,
          'line-opacity': 0.5,
          'line-dasharray': [2, 2]
        }
      });
    }

    // Add points source and layer
    if (!map.getSource(this.pointsSourceId)) {
      map.addSource(this.pointsSourceId, {
        type: 'geojson',
        data: {
          type: 'FeatureCollection',
          features: []
        }
      });
    }

    if (!map.getLayer(this.pointsLayerId)) {
      map.addLayer({
        id: this.pointsLayerId,
        type: 'circle',
        source: this.pointsSourceId,
        paint: {
          'circle-radius': 6,
          'circle-color': '#3b82f6',
          'circle-stroke-color': '#fff',
          'circle-stroke-width': 2
        }
      });
    }
  }

  cleanup() {
    const map = this.args.map;

    // Remove event listeners
    if (this.mapClickHandler) {
      map.off('click', this.mapClickHandler);
    }
    if (this.mapMoveHandler) {
      map.off('mousemove', this.mapMoveHandler);
    }
    if (this.mapMouseDownHandler) {
      map.off('mousedown', this.mapMouseDownHandler);
    }
    if (this.mapMouseUpHandler) {
      map.off('mouseup', this.mapMouseUpHandler);
    }

    // Remove layers
    if (map.getLayer(this.pointsLayerId)) {
      map.removeLayer(this.pointsLayerId);
    }
    if (map.getLayer(this.previewLayerId)) {
      map.removeLayer(this.previewLayerId);
    }
    if (map.getLayer(this.lineLayerId)) {
      map.removeLayer(this.lineLayerId);
    }
    if (map.getLayer(this.polygonLayerId)) {
      map.removeLayer(this.polygonLayerId);
    }

    // Remove sources
    if (map.getSource(this.pointsSourceId)) {
      map.removeSource(this.pointsSourceId);
    }
    if (map.getSource(this.previewSourceId)) {
      map.removeSource(this.previewSourceId);
    }
    if (map.getSource(this.lineSourceId)) {
      map.removeSource(this.lineSourceId);
    }
    if (map.getSource(this.polygonSourceId)) {
      map.removeSource(this.polygonSourceId);
    }
  }

  @action
  addPoint(lat: number, lng: number) {
    this.points = [...this.points, { lat, lng }];
    this.renderPolygon();
  }

  @action
  removePoint(index: number) {
    this.points = this.points.filter((_, i) => i !== index);
    this.renderPolygon();
  }

  @action
  complete() {
    if (this.canComplete) {
      this.args.onPolygonComplete(this.points);
    }
  }

  @action
  cancel() {
    this.args.onCancel();
  }

  @action
  toggleDrawingMode() {
    this.isDrawing = !this.isDrawing;
    if (!this.isDrawing) {
      // Clear preview when switching to edit mode
      this.updatePreviewSource([]);
    }
  }

  @action
  clearPolygon() {
    this.points = [];
    this.isDrawing = true;
    this.renderPolygon();
  }

  updatePreview(lngLat: LngLat) {
    if (this.points.length === 0) {
      this.updatePreviewSource([]);
      return;
    }

    const lastPoint = this.points[this.points.length - 1]!;
    const previewCoords: [number, number][] = [
      [lastPoint.lng, lastPoint.lat],
      [lngLat.lng, lngLat.lat]
    ];

    // If we have at least 3 points, also show line back to start
    if (this.points.length >= 2) {
      const firstPoint = this.points[0]!;
      previewCoords.push([firstPoint.lng, firstPoint.lat]);
    }

    this.updatePreviewSource(previewCoords);
  }

  updatePreviewSource(coordinates: [number, number][]) {
    const map = this.args.map;
    const source = map.getSource(this.previewSourceId);
    if (source && source.type === 'geojson') {
      source.setData({
        type: 'Feature',
        geometry: {
          type: 'LineString',
          coordinates
        },
        properties: {}
      });
    }
  }

  renderPolygon() {
    const map = this.args.map;

    if (this.points.length === 0) {
      // Clear all layers
      this.updatePolygonSource([]);
      this.updateLineSource([]);
      this.updatePointsSource([]);
      return;
    }

    const coordinates: [number, number][] = this.points.map(p => [p.lng, p.lat]);

    if (this.points.length >= 3) {
      // Update polygon fill
      this.updatePolygonSource([coordinates]);
      // Update polygon outline
      this.updateLineSource([...coordinates, coordinates[0]!]);
    } else if (this.points.length === 2) {
      // Clear polygon, show line only
      this.updatePolygonSource([]);
      this.updateLineSource(coordinates);
    } else {
      // Clear both for single point
      this.updatePolygonSource([]);
      this.updateLineSource([]);
    }

    // Update point markers
    this.updatePointsSource(this.points);
  }

  updatePolygonSource(coordinates: [number, number][][]) {
    const map = this.args.map;
    const source = map.getSource(this.polygonSourceId);
    if (source && source.type === 'geojson') {
      source.setData({
        type: 'Feature',
        geometry: {
          type: 'Polygon',
          coordinates
        },
        properties: {}
      });
    }
  }

  updateLineSource(coordinates: [number, number][]) {
    const map = this.args.map;
    const source = map.getSource(this.lineSourceId);
    if (source && source.type === 'geojson') {
      source.setData({
        type: 'Feature',
        geometry: {
          type: 'LineString',
          coordinates
        },
        properties: {}
      });
    }
  }

  updatePointsSource(points: PolygonPoint[]) {
    const map = this.args.map;
    const source = map.getSource(this.pointsSourceId);
    if (source && source.type === 'geojson') {
      source.setData({
        type: 'FeatureCollection',
        features: points.map((point, index) => ({
          type: 'Feature',
          geometry: {
            type: 'Point',
            coordinates: [point.lng, point.lat]
          },
          properties: {
            index
          }
        }))
      });
    }
  }

  <template>
    <div class="polygon-selector" {{this.setupPolygonDrawing}}>
      <div class="polygon-selector-controls">
        <div class="polygon-selector-info">
          <FaIcon @icon={{faCropSimple}} />
          <span>{{this.areaText}}</span>
        </div>

        <div class="polygon-selector-actions">
          {{#if this.isDrawing}}
            {{#if this.points.length}}
              <button
                type="button"
                class="polygon-selector-button polygon-selector-button--secondary"
                {{on "click" this.clearPolygon}}
                aria-label="Clear polygon"
              >
                <FaIcon @icon={{faTrash}} />
              </button>
            {{/if}}
            {{#if this.canComplete}}
              <button
                type="button"
                class="polygon-selector-button polygon-selector-button--secondary"
                {{on "click" this.toggleDrawingMode}}
                aria-label="Finish drawing"
              >
                Done
              </button>
            {{/if}}
          {{else}}
            <button
              type="button"
              class="polygon-selector-button polygon-selector-button--secondary"
              {{on "click" this.toggleDrawingMode}}
              aria-label="Continue drawing"
            >
              Edit
            </button>
            <button
              type="button"
              class="polygon-selector-button polygon-selector-button--secondary"
              {{on "click" this.clearPolygon}}
              aria-label="Clear polygon"
            >
              <FaIcon @icon={{faTrash}} />
            </button>
          {{/if}}

          <button
            type="button"
            class="polygon-selector-button polygon-selector-button--secondary"
            {{on "click" this.cancel}}
            aria-label="Cancel"
          >
            <FaIcon @icon={{faTimes}} />
          </button>

          {{#unless this.isDrawing}}
            <button
              type="button"
              class="polygon-selector-button polygon-selector-button--primary"
              {{on "click" this.complete}}
              disabled={{unless this.canComplete true}}
              aria-label="Confirm selection"
            >
              <FaIcon @icon={{faCheck}} />
              Confirm
            </button>
          {{/unless}}
        </div>
      </div>
    </div>
  </template>
}
