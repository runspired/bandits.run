import { Request } from '@warp-drive/ember';
import { withReactiveResponse } from '@warp-drive/core/request';
import ThemedPage from '#app/components/themed-page.gts';
import { pageTitle } from 'ember-page-title';
import type { Organization } from '#app/data/organization.ts';
import FaIcon from '#app/components/fa-icon.gts';
import { faGlobe } from '@fortawesome/free-solid-svg-icons';
import { faInstagram, faMeetup, faStrava } from '@fortawesome/free-brands-svg-icons';
import VtLink from '#app/components/vt-link.gts';
import { getHostname } from '#app/utils/helpers.ts';

const query = withReactiveResponse<Organization[]>({
  url: '/api/organization.json',
});

<template>
  {{pageTitle "Bandits | Community Organizations"}}

  <ThemedPage>
    <:header>Trail Organizations</:header>
    <:default>
      <Request @query={{query}}>
        <:loading> <h2>Gathering the trail community...</h2> </:loading>
        <:content as |response|>
          <div class="runs-list">
            <h3 class="section-title">Find Your Community</h3>
            {{#each response.data as |org|}}
              <div class="run-card org-card-compact">
                <div class="org-compact-header">
                  <h3 class="run-title"><VtLink @route="organizations.single" @model={{org.id}}>{{org.name}}</VtLink></h3>
                  {{#if org.description}}
                    <span class="org-compact-description">
                      {{!-- template-lint-disable no-triple-curlies --}}
                      {{org.description}}
                    </span>
                  {{/if}}
                </div>

                <div class="org-compact-links">
                  {{#if org.website}}
                    <a href="{{org.website}}" target="_blank" rel="noopener noreferrer" class="org-compact-link">
                      <FaIcon @icon={{faGlobe}} /> {{getHostname org.website}}
                    </a>
                  {{/if}}
                  {{#if org.stravaHandle}}
                    <a href="https://www.strava.com/clubs/{{org.stravaHandle}}" target="_blank" rel="noopener noreferrer" class="org-compact-link">
                      <FaIcon @icon={{faStrava}} /> @{{org.stravaHandle}}
                    </a>
                  {{else if org.stravaId}}
                    <a href="https://www.strava.com/clubs/{{org.stravaId}}" target="_blank" rel="noopener noreferrer" class="org-compact-link">
                      <FaIcon @icon={{faStrava}} /> Strava
                    </a>
                  {{/if}}
                  {{#if org.instagramHandle}}
                    <a href="https://www.instagram.com/{{org.instagramHandle}}" target="_blank" rel="noopener noreferrer" class="org-compact-link">
                      <FaIcon @icon={{faInstagram}} /> @{{org.instagramHandle}}
                    </a>
                  {{/if}}
                  {{#if org.meetupId}}
                    <a href="https://www.meetup.com/{{org.meetupId}}" target="_blank" rel="noopener noreferrer" class="org-compact-link">
                      <FaIcon @icon={{faMeetup}} /> @{{org.meetupId}}
                    </a>
                  {{/if}}
                  {{#if org.email}}
                    <a href="mailto:{{org.email}}" class="org-compact-link">
                      Email: {{org.email}}
                    </a>
                  {{/if}}
                  {{#if org.phoneNumber}}
                    <a href="tel:{{org.phoneNumber}}" class="org-compact-link">
                      Phone: {{org.phoneNumber}}
                    </a>
                  {{/if}}
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
    </:default>
  </ThemedPage>

</template>
