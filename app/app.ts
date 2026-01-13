import '@warp-drive/ember/install';
import Application from 'ember-strict-application-resolver';
import { importSync, isDevelopingApp, macroCondition } from '@embroider/macros';
// import setupInspector from '@embroider/legacy-inspector-support/ember-source-4.12';
import { initializeTheme } from './core/site-theme';
import Router from './router';
import PageTitleService from 'ember-page-title/services/page-title';

const routes = import.meta.glob('./routes/**/*.ts', { eager: true });
const templates = import.meta.glob('./templates/**/*.gts', { eager: true });
const services = import.meta.glob('./services/**/*.ts', { eager: true });

const slimModules = {
  './router': Router,
  ...routes,
  ...templates,
  ...services,
  './services/page-title': PageTitleService,
}

if (macroCondition(isDevelopingApp())) {
  importSync('./deprecation-workflow');
}

initializeTheme();

export default class App extends Application {
  // inspector = setupInspector(this);
  modules = slimModules;
}
