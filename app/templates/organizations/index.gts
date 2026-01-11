import { Request } from '@warp-drive/ember';
import { withReactiveResponse } from '@warp-drive/core/request';
import ThemedPage from '#app/components/themed-page.gts';
import { pageTitle } from 'ember-page-title';
import type { Organization } from '#app/data/organization.ts';
import FaIcon from '#app/components/fa-icon.gts';
import { faGlobe } from '@fortawesome/free-solid-svg-icons';
import { faInstagram, faStrava } from '@fortawesome/free-brands-svg-icons';

const query = withReactiveResponse<Organization[]>({
  url: '/api/organization.json',
});

<template>
  {{pageTitle "Bandits | Community Organizations"}}

  <ThemedPage>
    <Request @query={{query}}>
      <:loading> <h2>Gathering the trail community...</h2> </:loading>
      <:content as |response|>
        <div class="schedule">
          <h3 class="section-title">Trail Running Organizations</h3>
          {{#each response.data as |org|}}
            <div class="day-schedule">
              <h3>{{org.name}}</h3>
              <div class="day-events">
                {{#if org.description}}
                  <div class="org-description">
                    {{!-- template-lint-disable no-triple-curlies --}}
                    {{org.description}}
                  </div>
                {{/if}}
                <ul class="org-details">
                  {{#if org.website}}
                    <li class="org-detail">
                      <a href="{{org.website}}" target="_blank" rel="noopener noreferrer">
                        <FaIcon @icon={{faGlobe}} /> {{org.website}}
                      </a>
                    </li>
                  {{/if}}
                  {{#if org.stravaHandle}}
                    <li class="org-detail">
                      <a href="https://www.strava.com/clubs/{{org.stravaHandle}}" target="_blank" rel="noopener noreferrer">
                        <FaIcon @icon={{faStrava}} /> @{{org.stravaHandle}}
                      </a>
                    </li>
                  {{/if}}
                  {{#if org.instagramHandle}}
                    <li class="org-detail">
                      <a href="https://www.instagram.com/{{org.instagramHandle}}" target="_blank" rel="noopener noreferrer">
                        <FaIcon @icon={{faInstagram}} /> @{{org.instagramHandle}}
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
                      <a href="tel:{{org.phoneNumber}}">{{org.phoneNumber}}</a>
                    </li>
                  {{/if}}
                  {{#if org.meetupId}}
                    <li class="org-detail">
                      <span class="detail-label">Meetup:</span>
                      <a href="https://www.meetup.com/{{org.meetupId}}" target="_blank" rel="noopener noreferrer">{{org.meetupId}}</a>
                    </li>
                  {{/if}}
                </ul>
              </div>
            </div>
          {{/each}}
        </div>
      </:content>
      <:error as |error|>
        <div class="error-box">
          <h2>Whoops!</h2>
          <p>We weren't able to load the trail running organizations!</p>
          <p class="error-message">{{error.message}}</p>
        </div>
      </:error>
    </Request>
  </ThemedPage>

</template>
