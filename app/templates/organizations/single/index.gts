import Component from '@glimmer/component';
import { service } from '@ember/service';
import type RouterService from '@ember/routing/router-service';
import { Request } from '@warp-drive/ember';
import { withReactiveResponse } from '@warp-drive/core/request';
import ThemedPage from '#app/components/themed-page.gts';
import { pageTitle } from 'ember-page-title';
import type { Organization } from '#app/data/organization.ts';
import FaIcon from '#app/components/fa-icon.gts';
import { faGlobe } from '@fortawesome/free-solid-svg-icons';
import { faInstagram, faStrava } from '@fortawesome/free-brands-svg-icons';

/**
 * Extracts the hostname (domain and TLD) from a URL, removing www subdomain
 */
function getHostname(url: string): string {
  try {
    const urlObj = new URL(url);
    let hostname = urlObj.hostname;
    // Remove www. subdomain if present
    if (hostname.startsWith('www.')) {
      hostname = hostname.substring(4);
    }
    return hostname;
  } catch {
    // If URL parsing fails, return the original string
    return url;
  }
}

export default class OrganizationSingleRoute extends Component<{
  Args: {
    model: {
      organization: string;
    };
  };
}> {
  @service declare router: RouterService;

  get query() {
    return withReactiveResponse<Organization>({
      url: `/api/organization/${this.args.model.organization}.json`,
    });
  }

  <template>
    {{pageTitle "Organization | Bandits"}}

    <ThemedPage>
      <Request @query={{this.query}}>
        <:loading> <h2>Loading organization...</h2> </:loading>
        <:content as |response|>
          {{#let response.data as |org|}}
            {{pageTitle org.name " | Bandits"}}
            <div class="schedule">
              <div class="day-schedule">
                <h2>{{org.name}}</h2>
                <div class="day-events">
                  {{#if org.description}}
                    <div class="org-description">
                      {{org.description}}
                    </div>
                  {{/if}}
                  <ul class="org-details">
                    {{#if org.website}}
                      <li class="org-detail">
                        <a
                          href="{{org.website}}"
                          target="_blank"
                          rel="noopener noreferrer"
                        >
                          <FaIcon @icon={{faGlobe}} />
                          {{getHostname org.website}}
                        </a>
                      </li>
                    {{/if}}
                    {{#if org.stravaHandle}}
                      <li class="org-detail">
                        <a
                          href="https://www.strava.com/clubs/{{org.stravaHandle}}"
                          target="_blank"
                          rel="noopener noreferrer"
                        >
                          <FaIcon @icon={{faStrava}} />
                          @{{org.stravaHandle}}
                        </a>
                      </li>
                    {{else if org.stravaId}}
                      <li class="org-detail">
                        <a
                          href="https://www.strava.com/clubs/{{org.stravaId}}"
                          target="_blank"
                          rel="noopener noreferrer"
                        >
                          <FaIcon @icon={{faStrava}} />
                          Strava
                        </a>
                      </li>
                    {{/if}}
                    {{#if org.instagramHandle}}
                      <li class="org-detail">
                        <a
                          href="https://www.instagram.com/{{org.instagramHandle}}"
                          target="_blank"
                          rel="noopener noreferrer"
                        >
                          <FaIcon @icon={{faInstagram}} />
                          @{{org.instagramHandle}}
                        </a>
                      </li>
                    {{/if}}
                    {{#if org.email}}
                      <li class="org-detail">
                        <span class="detail-label">Email:</span>
                        <a href="mailto:{{org.email}}">{{org.email}}</a>
                      </li>
                    {{/if}}
                    {{#if org.phoneNumber}}
                      <li class="org-detail">
                        <span class="detail-label">Phone:</span>
                        <a
                          href="tel:{{org.phoneNumber}}"
                        >{{org.phoneNumber}}</a>
                      </li>
                    {{/if}}
                    {{#if org.meetupId}}
                      <li class="org-detail">
                        <span class="detail-label">Meetup:</span>
                        <a
                          href="https://www.meetup.com/{{org.meetupId}}"
                          target="_blank"
                          rel="noopener noreferrer"
                        >{{org.meetupId}}</a>
                      </li>
                    {{/if}}
                  </ul>
                </div>
              </div>
            </div>
          {{/let}}
        </:content>
        <:error as |error|>
          <div class="error-box">
            <h2>Whoops!</h2>
            <p>We weren't able to load this organization!</p>
            <p class="error-message">{{error.message}}</p>
          </div>
        </:error>
      </Request>
    </ThemedPage>
  </template>
}
