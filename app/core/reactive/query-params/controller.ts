import Controller from '@ember/controller';
import { service } from '@ember/service';
import type { QueryParams } from './service';

export class QPController extends Controller {
  @service('query-params') declare params: QueryParams;
}
