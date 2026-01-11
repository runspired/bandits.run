import Component from '@glimmer/component';
import { modifier } from 'ember-modifier';
import * as L from 'leaflet';
import { MapContext } from './leaflet-map.gts';

interface LeafletPopupSignature {
  Element: HTMLDivElement;
  Args: {
    context: object;
    lat: number;
    lng: number;
    content?: string;
    maxWidth?: number;
    minWidth?: number;
    autoClose?: boolean;
    closeOnClick?: boolean;
    offset?: L.PointExpression;
  };
  Blocks: {
    default?: [];
  };
}

export default class LeafletPopupComponent extends Component<LeafletPopupSignature> {
  setupPopup = modifier((element: HTMLElement) => {
    const map = MapContext.get(this.args.context);
    if (!map) {
      console.error('LeafletPopup: No map found in context');
      return;
    }

    const {
      lat,
      lng,
      content,
      maxWidth = 300,
      minWidth = 50,
      autoClose = true,
      closeOnClick = true,
      offset,
    } = this.args;

    const popupOptions: L.PopupOptions = {
      maxWidth,
      minWidth,
      autoClose,
      closeOnClick,
      offset,
    };

    const popup = L.popup(popupOptions)
      .setLatLng([lat, lng])
      .setContent(content || element.innerHTML)
      .openOn(map);

    return () => {
      popup.remove();
    };
  });

  <template>
    <div style="display: none;" {{this.setupPopup}}>
      {{yield}}
    </div>
  </template>
}
