import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';
import type * as L from 'leaflet';
import FaIcon from '#ui/fa-icon.gts';
import { faCropSimple, faCheck, faTimes, faTrash } from '@fortawesome/free-solid-svg-icons';
import './polygon-selector.css';

export interface PolygonPoint {
  lat: number;
  lng: number;
}

interface PolygonSelectorSignature {
  Args: {
    /**
     * Leaflet map instance
     */
    map: L.Map;

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
 * Interactive polygon drawing tool for map crop selection
 *
 * Allows users to click on a map to define a custom polygon area for tile caching.
 * Features:
 * - Click to add points
 * - Hover preview of next point
 * - Visual feedback with line and fill
 * - Edit mode to move/delete points
 * - Complete or cancel actions
 */
export default class PolygonSelector extends Component<PolygonSelectorSignature> {
  @tracked points: PolygonPoint[] = this.args.initialPoints ?? [];
  @tracked isDrawing: boolean = true;
  @tracked hoveredPoint: PolygonPoint | null = null;
  @tracked draggedPointIndex: number | null = null;

  polygon: L.Polygon | null = null;
  polyline: L.Polyline | null = null;
  previewLine: L.Polyline | null = null;
  markers: L.CircleMarker[] = [];
  mapClickHandler: ((e: L.LeafletMouseEvent) => void) | null = null;
  mapMoveHandler: ((e: L.LeafletMouseEvent) => void) | null = null;
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
    this.mapClickHandler = (e: L.LeafletMouseEvent) => {
      if (this.isDrawing && this.draggedPointIndex === null) {
        this.addPoint(e.latlng.lat, e.latlng.lng);
      }
    };
    map.on('click', this.mapClickHandler);

    // Add mousemove handler for preview
    this.mapMoveHandler = (e: L.LeafletMouseEvent) => {
      if (this.isDrawing && this.points.length > 0) {
        this.updatePreview(e.latlng.lat, e.latlng.lng);
      }
    };
    map.on('mousemove', this.mapMoveHandler);

    // If we have initial points (loaded from args), render them in edit mode
    if (this.hasInitialPoints) {
      this.isDrawing = false;
      this.renderPolygon();
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

    // Remove all map elements
    if (this.polygon) {
      map.removeLayer(this.polygon);
    }
    if (this.polyline) {
      map.removeLayer(this.polyline);
    }
    if (this.previewLine) {
      map.removeLayer(this.previewLine);
    }
    this.markers.forEach(marker => map.removeLayer(marker));
    this.markers = [];
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
    if (!this.isDrawing && this.previewLine) {
      this.args.map.removeLayer(this.previewLine);
      this.previewLine = null;
    }
  }

  @action
  clearPolygon() {
    this.points = [];
    this.isDrawing = true;
    this.cleanup();
    this.initializeDrawing();
  }

  updatePreview(lat: number, lng: number) {
    if (this.points.length === 0) return;

    const lastPoint = this.points[this.points.length - 1]!;
    const previewPoints: [number, number][] = [
      [lastPoint.lat, lastPoint.lng],
      [lat, lng]
    ];

    // If we have at least 3 points, also show line back to start
    if (this.points.length >= 2) {
      const firstPoint = this.points[0]!;
      previewPoints.push([firstPoint.lat, firstPoint.lng]);
    }

    if (this.previewLine) {
      this.previewLine.setLatLngs(previewPoints);
    } else {
      // @ts-expect-error - Leaflet types are available at runtime
      this.previewLine = L.polyline(previewPoints, {
        color: '#3b82f6',
        weight: 2,
        opacity: 0.5,
        dashArray: '5, 10'
      }).addTo(this.args.map);
    }
  }

  renderPolygon() {
    const map = this.args.map;

    // Clear existing layers
    if (this.polygon) map.removeLayer(this.polygon);
    if (this.polyline) map.removeLayer(this.polyline);
    this.markers.forEach(marker => map.removeLayer(marker));
    this.markers = [];

    if (this.points.length === 0) return;

    const latLngs: [number, number][] = this.points.map(p => [p.lat, p.lng]);

    if (this.points.length >= 3) {
      // Draw filled polygon
      // @ts-expect-error - Leaflet types are available at runtime
      this.polygon = L.polygon(latLngs, {
        color: '#3b82f6',
        fillColor: '#3b82f6',
        fillOpacity: 0.2,
        weight: 2
      }).addTo(map);
    } else if (this.points.length === 2) {
      // Draw line for 2 points
      // @ts-expect-error - Leaflet types are available at runtime
      this.polyline = L.polyline(latLngs, {
        color: '#3b82f6',
        weight: 2
      }).addTo(map);
    }

    // Add markers for each point
    this.points.forEach((point, index) => {
      // @ts-expect-error - Leaflet types are available at runtime
      const marker = L.circleMarker([point.lat, point.lng], {
        radius: 6,
        fillColor: '#3b82f6',
        fillOpacity: 1,
        color: '#fff',
        weight: 2
      }).addTo(map);

      // Add click handler to remove point (when not drawing)
      marker.on('click', (e) => {
        if (!this.isDrawing) {
          // @ts-expect-error - Leaflet types are available at runtime
          L.DomEvent.stopPropagation(e);
          this.removePoint(index);
        }
      });

      // Add drag handlers (when not drawing)
      if (!this.isDrawing) {
        marker.on('mousedown', () => {
          this.draggedPointIndex = index;
          map.dragging.disable();
        });
      }

      this.markers.push(marker);
    });

    // Add map-level handlers for dragging
    if (!this.isDrawing) {
      const dragHandler = (e: any) => {
        if (this.draggedPointIndex !== null) {
          const newPoints = [...this.points];
          newPoints[this.draggedPointIndex] = {
            lat: e.latlng.lat,
            lng: e.latlng.lng
          };
          this.points = newPoints;
          this.renderPolygon();
        }
      };

      const dragEndHandler = () => {
        this.draggedPointIndex = null;
        map.dragging.enable();
      };

      map.on('mousemove', dragHandler);
      map.on('mouseup', dragEndHandler);
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
