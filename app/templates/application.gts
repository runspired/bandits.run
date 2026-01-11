import { tracked } from '@glimmer/tracking';

class ColorSchemeManager {
  @tracked colorScheme: 'light only' | 'dark only' | null = null;

  initializeColorScheme() {
    const preferredScheme = globalThis.localStorage.getItem(
      'preferred-color-scheme'
    );
    if (preferredScheme === 'dark') {
      this.colorScheme = 'dark only';

      document.body.style.colorScheme = 'dark only';

      document.body.classList.add('dark-mode');
    } else if (preferredScheme === 'light') {
      this.colorScheme = 'light only';

      document.body.style.colorScheme = 'light only';

      document.body.classList.add('light-mode');
    } else {
      // get the user's system preference
      const prefersDark = globalThis.matchMedia('(prefers-color-scheme: dark)')
        .matches;
      if (prefersDark) {
        this.colorScheme = 'dark only';
      } else {
        this.colorScheme = 'light only';
      }
    }
  }

  toggleColorScheme = () => {
    if (this.colorScheme === 'light only') {
      this.colorScheme = 'dark only';

      document.body.style.colorScheme = 'dark only';

      document.body.classList.remove('light-mode');

      document.body.classList.add('dark-mode');
      globalThis.localStorage.setItem('preferred-color-scheme', 'dark');
    } else {
      this.colorScheme = 'light only';

      document.body.style.colorScheme = 'light only';

      document.body.classList.remove('dark-mode');

      document.body.classList.add('light-mode');
      globalThis.localStorage.setItem('preferred-color-scheme', 'light');
    }
  };

  get isDarkMode() {
    return this.colorScheme === 'dark only';
  }
}

export const colorSchemeManager = new ColorSchemeManager();
export const toggleColorScheme = colorSchemeManager.toggleColorScheme;
export function initializeColorScheme() {
  colorSchemeManager.initializeColorScheme();
}
export default <template>
  {{(initializeColorScheme)}}
  {{outlet}}
</template>
