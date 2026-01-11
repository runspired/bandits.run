
let colorScheme: 'light only' | 'dark only' | null = null;

export function initializeColorScheme() {
  const preferredScheme = globalThis.localStorage.getItem(
    'preferred-color-scheme'
  );
  if (preferredScheme === 'dark') {
    colorScheme = 'dark only';
    // eslint-disable-next-line no-undef
    document.body.style.colorScheme = 'dark only';
    // eslint-disable-next-line no-undef
    document.body.classList.add('dark-mode');
  } else if (preferredScheme === 'light') {
    colorScheme = 'light only';
    // eslint-disable-next-line no-undef
    document.body.style.colorScheme = 'light only';
    // eslint-disable-next-line no-undef
    document.body.classList.add('light-mode');
  }
}

export function toggleColorScheme() {
  if (colorScheme === 'light only') {
    colorScheme = 'dark only';
    // eslint-disable-next-line no-undef
    document.body.style.colorScheme = 'dark only';
    // eslint-disable-next-line no-undef
    document.body.classList.remove('light-mode');
    // eslint-disable-next-line no-undef
    document.body.classList.add('dark-mode');
    globalThis.localStorage.setItem('preferred-color-scheme', 'dark');
  } else {
    colorScheme = 'light only';
    // eslint-disable-next-line no-undef
    document.body.style.colorScheme = 'light only';
    // eslint-disable-next-line no-undef
    document.body.classList.remove('dark-mode');
    // eslint-disable-next-line no-undef
    document.body.classList.add('light-mode');
    globalThis.localStorage.setItem('preferred-color-scheme', 'light');
  }
}
export default <template>
  {{(initializeColorScheme)}}
  {{outlet}}
</template>
