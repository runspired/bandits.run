import { toggleColorScheme } from '#app/templates/application.gts';
import type { TOC } from '@ember/component/template-only';
import { on } from '@ember/modifier';
import HamburgerMenu from './hamburger-menu.gts';
import FaIcon from './fa-icon.gts';
import { LinkTo } from '@ember/routing';
import VtLink from './vt-link.gts';
import { faHome, faUsers, faPalette } from '@fortawesome/free-solid-svg-icons';

// Import BackButton as a value to use in template
import BackButton from './back-button.gts';

const ThemedPage: TOC<{
  Blocks: {
    default: [];
  };
}> = <template>
  <section class="page" ...attributes>
    <div class="landscape-container">

      <div class="sky">
        <div class="logo-header">
          <div class="logo-header-text">
            <h1
              class="title"
              role="button"
              aria-roledescription="toggle color scheme"
              {{on "click" toggleColorScheme}}
            >Bay Bandits</h1>
            <h2 class="subtitle">Trail Running Community</h2>
          </div>
          <div class="header-controls">
            <BackButton />
            <HamburgerMenu>
              <VtLink @route="index"><FaIcon @icon={{faHome}} /> Home</VtLink>
              <VtLink @route="organizations.index"><FaIcon @icon={{faUsers}} />
                Organizations</VtLink>
              <LinkTo @route="branding"><FaIcon @icon={{faPalette}} />
                Branding</LinkTo>
            </HamburgerMenu>
          </div>
        </div>
        <div class="content-area">
        {{yield}}
        </div>
      </div>

      <svg
        class="hill-svg back-hill"
        viewBox="0 0 1440 320"
        preserveAspectRatio="none"
      >
        <path
          d="M0,160L120,176C240,192,480,224,720,224C960,224,1200,192,1320,176L1440,160L1440,320L1320,320C1200,320,960,320,720,320C480,320,240,320,120,320L0,320Z"
        ></path>
      </svg>

      <svg
        class="hill-svg front-hill"
        viewBox="0 0 1440 320"
        preserveAspectRatio="none"
      >
        <path
          d="M0,224L80,213.3C160,203,320,181,480,181.3C640,181,800,203,960,213.3C1120,224,1280,224,1360,224L1440,224L1440,320L1360,320C1280,320,1120,320,960,320C800,320,640,320,480,320C320,320,160,320,80,320L0,320Z"
        ></path>
      </svg>

      <div class="tree-container">
        <div class="tree tree-left-0"></div>
        <div class="tree tree-left-1"></div>
        <div class="tree tree-left-2"></div>
        <div class="tree tree-left-3"></div>
        <div class="tree tree-right-0"></div>
        <div class="tree tree-right-1"></div>
        <div class="tree tree-right-2"></div>
        <div class="tree tree-right-3"></div>
        <div class="tree tree-right-4"></div>
      </div>
    </div>
  </section>
</template>;

export default ThemedPage;
