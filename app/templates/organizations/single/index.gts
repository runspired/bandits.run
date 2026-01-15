import Component from '@glimmer/component';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import type RouterService from '@ember/routing/router-service';
import { Request } from '@warp-drive/ember';
import ThemedPage from '#layout/themed-page.gts';
import { pageTitle } from 'ember-page-title';
import type { TrailRun } from '#app/data/run.ts';
import FaIcon from '#ui/fa-icon.gts';
import { faGlobe, faEnvelope, faPhone } from '@fortawesome/free-solid-svg-icons';
import { faInstagram, faStrava, faMeetup } from '@fortawesome/free-brands-svg-icons';
import { Tabs, type TabTransition } from '#ux/tabs.gts';
import type { Future } from '@warp-drive/core/request';
import type { ReactiveDataDocument } from '@warp-drive/core/reactive';
import type { Organization } from '#app/data/organization.ts';
import { htmlSafe } from '@ember/template';
import { getOrganizationRuns } from '#api/GET';
import RunPreview from '#entities/run-preview.gts';
import SocialGraph from '#app/components/seo/social-graph.gts';
import { getHostname } from '#app/utils/helpers.ts';
import { or } from '#app/utils/comparison.ts';

function getOrganizationDescription(org: Organization): string {
  return org.description || `${org.name} is a trail running organization in the SF Bay Area. Join group runs, connect with fellow trail runners, and explore amazing trails!`;
}

function getOrganizationKeywords(org: Organization): string {
  return `trail running, ${org.name}, running group, SF Bay Area, trail running community`;
}

function getOrganizationUrl(organizationId: string): string {
  return `https://bandits.run/#/organizations/${organizationId}`;
}

export default class OrganizationSingleRoute extends Component<{
  Args: {
    model: {
      organization: Future<ReactiveDataDocument<Organization>>;
      organizationId: string;
    };
  };
}> {
  @service declare router: RouterService;

  @tracked tab: string | null = null;

  get activeTab(): string | null {
    // Get the tab from query params
    const currentRoute = this.router.currentRoute;
    const tabParam = currentRoute?.queryParams?.tab;
    return typeof tabParam === 'string' ? tabParam : null;
  }

  handleTabChange = (transition: TabTransition) => {
    // Update the query param when tab changes
    this.router.transitionTo({ queryParams: { tab: transition.to || null } });
  };

  /**
   * Sort runs by next occurrence date, with runs without future occurrences at the end
   */
  sortRunsByNextOccurrence = (runs: TrailRun[]): TrailRun[] => {
    return [...runs].sort((a, b) => {
      const nextA = a.nextOccurrence;
      const nextB = b.nextOccurrence;

      // If neither has a next occurrence, maintain original order
      if (!nextA && !nextB) return 0;
      // If only A has no next occurrence, put it after B
      if (!nextA) return 1;
      // If only B has no next occurrence, put it after A
      if (!nextB) return -1;
      // Both have next occurrences, sort by date
      return nextA.localeCompare(nextB);
    });
  };

  <template>
    {{pageTitle "Organization | Bandits"}}

    <Request @request={{@model.organization}}>
      <:loading> <h2>Loading organization...</h2> </:loading>              <:error as |error|>
        <div class="error-box">
          <h2>Whoops!</h2>
          <p>We weren't able to load this organization!</p>
          <p class="error-message">{{error.message}}</p>
        </div>
      </:error>
      <:content as |response|>
        {{#let response.data as |org|}}
          {{pageTitle org.name " | Bandits"}}
          <SocialGraph
            @title={{org.name}}
            @description={{getOrganizationDescription org}}
            @url={{getOrganizationUrl @model.organizationId}}
            @type="website"
            @keywords={{getOrganizationKeywords org}}
          />
          <ThemedPage>
            <:header>
              {{org.name}}
            </:header>
            <:default>
              <Tabs @activeSlug={{this.activeTab}} @onTabChange={{this.handleTabChange}} as |Tab|>
                <Tab @slug="overview">
                  <:title>Overview</:title>
                  <:body>
                    <div class="org-overview">
                      {{#if org.descriptionHtml}}
                        <div class="org-about markdown-content">
                          {{htmlSafe org.descriptionHtml}}
                        </div>
                      {{else if org.description}}
                        <div class="org-about">
                          <p>{{org.description}}</p>
                        </div>
                      {{/if}}

                      <div class="org-info-grid">
                        {{#if (or org.website org.email org.phoneNumber)}}
                          <div class="org-info-card">
                            <h3>Contact</h3>
                            <ul class="org-info-list">
                              {{#if org.website}}
                                <li>
                                  <a
                                    href="{{org.website}}"
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    class="org-info-link"
                                  >
                                    <FaIcon @icon={{faGlobe}} @fixedWidth={{true}} />
                                    <span>{{getHostname org.website}}</span>
                                  </a>
                                </li>
                              {{/if}}
                              {{#if org.email}}
                                <li>
                                  <a href="mailto:{{org.email}}" class="org-info-link">
                                    <FaIcon @icon={{faEnvelope}} @fixedWidth={{true}} />
                                    <span>{{org.email}}</span>
                                  </a>
                                </li>
                              {{/if}}
                              {{#if org.phoneNumber}}
                                <li>
                                  <a href="tel:{{org.phoneNumber}}" class="org-info-link">
                                    <FaIcon @icon={{faPhone}} @fixedWidth={{true}} />
                                    <span>{{org.phoneNumber}}</span>
                                  </a>
                                </li>
                              {{/if}}
                            </ul>
                          </div>
                        {{/if}}

                        {{#if (or org.stravaHandle org.stravaId org.instagramHandle org.meetupId)}}
                          <div class="org-info-card">
                            <h3>Social</h3>
                            <ul class="org-info-list">
                              {{#if org.stravaHandle}}
                                <li>
                                  <a
                                    href="https://www.strava.com/clubs/{{org.stravaHandle}}"
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    class="org-info-link"
                                  >
                                    <FaIcon @icon={{faStrava}} @fixedWidth={{true}} />
                                    <span>@{{org.stravaHandle}}</span>
                                  </a>
                                </li>
                              {{else if org.stravaId}}
                                <li>
                                  <a
                                    href="https://www.strava.com/clubs/{{org.stravaId}}"
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    class="org-info-link"
                                  >
                                    <FaIcon @icon={{faStrava}} @fixedWidth={{true}} />
                                    <span>Strava</span>
                                  </a>
                                </li>
                              {{/if}}
                              {{#if org.instagramHandle}}
                                <li>
                                  <a
                                    href="https://www.instagram.com/{{org.instagramHandle}}"
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    class="org-info-link"
                                  >
                                    <FaIcon @icon={{faInstagram}} @fixedWidth={{true}} />
                                    <span>@{{org.instagramHandle}}</span>
                                  </a>
                                </li>
                              {{/if}}
                              {{#if org.meetupId}}
                                <li>
                                  <a
                                    href="https://www.meetup.com/{{org.meetupId}}"
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    class="org-info-link"
                                  >
                                    <FaIcon @icon={{faMeetup}} @fixedWidth={{true}} />
                                    <span>Meetup</span>
                                  </a>
                                </li>
                              {{/if}}
                            </ul>
                          </div>
                        {{/if}}
                      </div>
                    </div>
                  </:body>
                </Tab>
                <Tab @slug="runs">
                  <:title>Runs</:title>
                  <:body>
                    <Request @query={{getOrganizationRuns @model.organizationId}}>
                      <:loading> <h2>Loading runs...</h2> </:loading>
                      <:content as |response|>
                        {{#let response.data as |runs|}}
                          {{#if runs}}
                            <div class="runs-list">
                              {{#each (this.sortRunsByNextOccurrence runs) as |run|}}
                                <RunPreview @run={{run}} @organizationId={{@model.organizationId}} />
                              {{/each}}
                            </div>
                          {{else}}
                            <p>No runs found for this organization.</p>
                          {{/if}}
                        {{/let}}
                      </:content>
                      <:error as |error|>
                        <div class="error-box">
                          <h2>Whoops!</h2>
                          <p>We weren't able to load the runs!</p>
                          <p class="error-message">{{error.message}}</p>
                        </div>
                      </:error>
                    </Request>
                  </:body>
                </Tab>
              </Tabs>
            </:default>
          </ThemedPage>
        {{/let}}
      </:content>
    </Request>
  </template>
}
