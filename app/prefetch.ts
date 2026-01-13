/**
 * Initialize specific requests sooner.
 */
import { getCurrentWeek } from '#api/GET';

function prefetch(url: string) {
  const link = document.createElement('link');
  link.rel = 'prefetch';
  link.as = 'fetch';
  link.href = url;
  link.crossOrigin = 'anonymous';
  document.head.appendChild(link);
}

// match `<host>/` and `<host>/#/`
if (window.location.hash === '' || window.location.hash === '#/') {
  const req = getCurrentWeek();
  prefetch(req.url!);
}
