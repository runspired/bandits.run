import Service from '@ember/service';
import { field, SessionResource } from '@trail-run/core/reactive/storage-resource';

@SessionResource('scroll-positions')
export default class extends Service {
  @field
  scrollPositions: Record<string, number> = {};

  get positions() {
    return this.scrollPositions;
  }
  set positions(value: Record<string, number>) {
    console.log('Updating scroll positions:', value);
    this.scrollPositions = { ...value };
  }
}
