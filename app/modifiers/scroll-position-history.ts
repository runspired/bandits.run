import { assert } from "@ember/debug";
import { registerDestructor } from "@ember/destroyable";
import { service } from "@ember/service";

import Modifier from "ember-modifier";

import type ScrollPositionHistory from "../services/scroll-position-history.ts";

function cleanup(instance: ScrollModifier) {
  const { _element, handler } = instance;

  if (_element && handler) {
    _element.removeEventListener("scroll", handler);

    instance._element = null;
    instance.handler = null;
  }
}

export default class ScrollModifier extends Modifier<{
  Args: {
    Positional: [string];
  };
}> {
  @service declare scrollPositionHistory: ScrollPositionHistory;
  _element: Element | null = null;
  scrollBoxId!: string;
  handler: null | ((event: Event) => void) = null;

  modify(element: Element, [scrollBoxId]: [string]) {
    this._element = element;
    this.scrollBoxId = scrollBoxId;
    assert(`Did not expect to be reinitialized`, !this.handler);
    const { positions } = this.scrollPositionHistory;
    if (positions[scrollBoxId]) {
      element.scrollTop = positions[scrollBoxId];
    }

    this.handler = (event: Event) => {
      const { target } = event;
      const scrollTop = (target as HTMLElement).scrollTop || 0;
      positions[scrollBoxId] = scrollTop;
    };
    element.addEventListener("scroll", this.handler, {
      passive: true,
      capture: true,
    });
    registerDestructor(this, cleanup);
  }
}
