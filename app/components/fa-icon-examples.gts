/**
 * Font Awesome Icon Usage Examples
 *
 * This file demonstrates how to use Font Awesome icons in your project.
 * You can delete this file after reviewing the examples.
 */

import Component from '@glimmer/component';
import FaIcon from './fa-icon.gts';

// Import icons you want to use
import {
  faHome,
  faUser,
  faEnvelope,
  faCalendar,
  faMapMarkerAlt,
  faBars,
  faTimes,
  faChevronDown,
  faChevronRight,
  faHeart,
  faStar,
} from '@fortawesome/free-solid-svg-icons';

import {
  faHeart as faHeartRegular,
  faStar as faStarRegular,
} from '@fortawesome/free-regular-svg-icons';

import {
  faGithub,
  faTwitter,
  faInstagram,
  faStrava,
} from '@fortawesome/free-brands-svg-icons';

/**
 * Basic Usage Examples:
 *
 * 1. Simple icon:
 *    <FaIcon @icon={{faHome}} />
 *
 * 2. Icon with custom class:
 *    <FaIcon @icon={{faUser}} class="custom-icon" />
 *
 * 3. Fixed-width icon (useful for aligning icons in lists):
 *    <FaIcon @icon={{faEnvelope}} @fixedWidth={{true}} />
 *
 * 4. Icon in a link:
 *    <a href="/home">
 *      <FaIcon @icon={{faHome}} /> Home
 *    </a>
 *
 * 5. Icon in a button:
 *    <button>
 *      <FaIcon @icon={{faBars}} /> Menu
 *    </button>
 *
 * Available Icon Sets:
 * - @fortawesome/free-solid-svg-icons (solid icons)
 * - @fortawesome/free-regular-svg-icons (outlined icons)
 * - @fortawesome/free-brands-svg-icons (brand logos)
 *
 * Browse all available icons at: https://fontawesome.com/icons
 */

export default class FaIconExamples extends Component {
  // Make icons available in template
  faHome = faHome;
  faUser = faUser;
  faEnvelope = faEnvelope;
  faCalendar = faCalendar;
  faMapMarkerAlt = faMapMarkerAlt;
  faBars = faBars;
  faTimes = faTimes;
  faChevronDown = faChevronDown;
  faChevronRight = faChevronRight;
  faHeart = faHeart;
  faStar = faStar;
  faHeartRegular = faHeartRegular;
  faStarRegular = faStarRegular;
  faGithub = faGithub;
  faTwitter = faTwitter;
  faInstagram = faInstagram;
  faStrava = faStrava;

  <template>
    <div class="icon-examples">
      <h2>Font Awesome Icon Examples</h2>

      <section>
        <h3>Solid Icons</h3>
        <div class="icon-grid">
          <div><FaIcon @icon={{this.faHome}} /> Home</div>
          <div><FaIcon @icon={{this.faUser}} /> User</div>
          <div><FaIcon @icon={{this.faEnvelope}} /> Email</div>
          <div><FaIcon @icon={{this.faCalendar}} /> Calendar</div>
          <div><FaIcon @icon={{this.faMapMarkerAlt}} /> Location</div>
          <div><FaIcon @icon={{this.faBars}} /> Menu</div>
          <div><FaIcon @icon={{this.faTimes}} /> Close</div>
          <div><FaIcon @icon={{this.faChevronDown}} /> Down</div>
          <div><FaIcon @icon={{this.faChevronRight}} /> Right</div>
          <div><FaIcon @icon={{this.faHeart}} /> Heart (Solid)</div>
          <div><FaIcon @icon={{this.faStar}} /> Star (Solid)</div>
        </div>
      </section>

      <section>
        <h3>Regular Icons</h3>
        <div class="icon-grid">
          <div><FaIcon @icon={{this.faHeartRegular}} /> Heart (Regular)</div>
          <div><FaIcon @icon={{this.faStarRegular}} /> Star (Regular)</div>
        </div>
      </section>

      <section>
        <h3>Brand Icons</h3>
        <div class="icon-grid">
          <div><FaIcon @icon={{this.faGithub}} /> GitHub</div>
          <div><FaIcon @icon={{this.faTwitter}} /> Twitter</div>
          <div><FaIcon @icon={{this.faInstagram}} /> Instagram</div>
          <div><FaIcon @icon={{this.faStrava}} /> Strava</div>
        </div>
      </section>

      <section>
        <h3>Styled Icons</h3>
        <div class="icon-grid">
          {{!-- template-lint-disable no-inline-styles --}}
          <div style="font-size: 2rem; color: var(--title);">
            <FaIcon @icon={{this.faHeart}} />
          </div>
          <div style="font-size: 3rem; color: var(--subtitle);">
            <FaIcon @icon={{this.faStar}} />
          </div>
        </div>
      </section>
    </div>
  </template>
}
