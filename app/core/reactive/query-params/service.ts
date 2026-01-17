import { trackedObject } from '@ember/reactive/collections';
import Service from '@ember/service';

export class QueryParams extends Service {
  state = trackedObject<Record<string, unknown>>({});
}
