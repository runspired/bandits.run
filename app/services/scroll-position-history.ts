import Service from '@ember/service';

export default class extends Service {
  positions: Record<string, number> = {};
}
