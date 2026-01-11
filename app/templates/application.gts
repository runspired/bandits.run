import { tracked } from '@glimmer/tracking';

class ColorSchemeManager {
  @tracked colorScheme: 'light only' | 'dark only' | null = null;

  initializeColorScheme() {
    const preferredScheme = globalThis.localStorage.getItem(
      'preferred-color-scheme'
    );
    if (preferredScheme === 'dark') {
      this.colorScheme = 'dark only';
      // eslint-disable-next-line no-undef
      document.body.style.colorScheme = 'dark only';
      // eslint-disable-next-line no-undef
      document.body.classList.add('dark-mode');
    } else if (preferredScheme === 'light') {
      this.colorScheme = 'light only';
      // eslint-disable-next-line no-undef
      document.body.style.colorScheme = 'light only';
      // eslint-disable-next-line no-undef
      document.body.classList.add('light-mode');
    }
  }

  toggleColorScheme = () => {
    if (this.colorScheme === 'light only') {
      this.colorScheme = 'dark only';
      // eslint-disable-next-line no-undef
      document.body.style.colorScheme = 'dark only';
      // eslint-disable-next-line no-undef
      document.body.classList.remove('light-mode');
      // eslint-disable-next-line no-undef
      document.body.classList.add('dark-mode');
      globalThis.localStorage.setItem('preferred-color-scheme', 'dark');
    } else {
      this.colorScheme = 'light only';
      // eslint-disable-next-line no-undef
      document.body.style.colorScheme = 'light only';
      // eslint-disable-next-line no-undef
      document.body.classList.remove('dark-mode');
      // eslint-disable-next-line no-undef
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
