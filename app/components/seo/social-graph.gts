import Component from '@glimmer/component';

export interface SocialGraphSignature {
  Args: {
    /**
     * The page title
     */
    title: string;

    /**
     * The page description for SEO and social sharing
     */
    description: string;

    /**
     * The canonical URL for this page
     */
    url: string;

    /**
     * The Open Graph image URL (absolute URL)
     * Recommended: 1200x630px for optimal display
     */
    image?: string;

    /**
     * The Open Graph type (defaults to 'website')
     * Common values: 'website', 'article', 'profile'
     */
    type?: string;

    /**
     * The site name (defaults to 'bandits.run')
     */
    siteName?: string;

    /**
     * Keywords for SEO
     */
    keywords?: string;

  };
}

function createTitleElement(): HTMLTitleElement {
  const title = document.createElement('title');
  document.head.appendChild(title);
  return title;
}

function createMetaElement(attrs: { property: string } | { name: string } | { itemprop: string }): HTMLMetaElement {
  const meta = document.createElement('meta');
  for (const [key, value] of Object.entries(attrs)) {
    meta.setAttribute(key, value);
  }
  document.head.appendChild(meta);
  return meta;
}

const MetaElements = new Map<string, HTMLMetaElement | HTMLTitleElement>([
  ['title', document.querySelector('title') ?? createTitleElement()],
  ['og:title', document.querySelector('meta[property="og:title"]') ?? createMetaElement({ property: 'og:title' })],
  ['description', document.querySelector('meta[name="description"]') ?? createMetaElement({ name: 'description' })],
  ['itemprop_description', document.querySelector('meta[itemprop="description"]') ?? createMetaElement({ itemprop: 'description' })],
  ['og:description', document.querySelector('meta[property="og:description"]') ?? createMetaElement({ property: 'og:description' })],
  ['og:url', document.querySelector('meta[property="og:url"]') ?? createMetaElement({ property: 'og:url' })],
  ['og:type', document.querySelector('meta[property="og:type"]') ?? createMetaElement({ property: 'og:type' })],
  ['og:site_name', document.querySelector('meta[property="og:site_name"]') ?? createMetaElement({ property: 'og:site_name' })],
  ['og:image', document.querySelector('meta[property="og:image"]') ?? createMetaElement({ property: 'og:image' })],
  ['keywords', document.querySelector('meta[name="keywords"]') ?? createMetaElement({ name: 'keywords' })]
]);

function metaKeysForProp(prop: keyof SocialGraphSignature['Args']): string[] {
  switch (prop) {
    case 'title':
      return ['title', 'og:title'];
    case 'description':
      return ['description', 'itemprop_description','og:description'];
    case 'url':
      return ['og:url'];
    case 'type':
      return ['og:type'];
    case 'siteName':
      return ['og:site_name'];
    case 'image':
      return ['og:image'];
    case 'keywords':
      return ['keywords'];
    default:
      throw new Error(`Unknown meta property: ${String(prop)}`);
  }
}

const DefaultMetaValues: SocialGraphSignature['Args'] = {
  type: 'website',
  siteName: 'bandits.run',
  url: 'https://bandits.run',
  image: 'https://bandits.run/images/light/og-banner-1200x630.png',
  title: 'The Bandits',
  description: 'Find Your Trail Friends! The Bandits are a Trail Running Community based in the SF Bay Area. Join us for group runs, social events, and more.',
  keywords: 'trail runsning, group runs, social events, Bay Area, community'
};

function updateMeta(meta: SocialGraphSignature['Args']) {
  // last one in wins, so update all head tags
  for (const [key, defaultValue] of Object.entries(DefaultMetaValues)) {
    const metaKeys = metaKeysForProp(key as keyof SocialGraphSignature['Args']);
    const value = meta[key as keyof SocialGraphSignature['Args']] ?? defaultValue;

    for (const metaKey of metaKeys) {
      const element = MetaElements.get(metaKey)!;
        if (element instanceof HTMLTitleElement) {
          element.textContent = String(value);
        } else if (element instanceof HTMLMetaElement) {
          element.setAttribute('content', String(value));
        }
    }
  }
}

const Metas = new Map<object, SocialGraphSignature['Args']>();
const OGManager = {
  setMeta(owner: object, meta: SocialGraphSignature['Args']) {
    Metas.set(owner, meta);
    updateMeta(meta);
  },
  removeMeta(owner: object) {
    Metas.delete(owner);
    // Maps are ordered, so the last one wins
    const lastMeta = Array.from(Metas)[Metas.size-1]?.[1] ?? DefaultMetaValues;
    updateMeta(lastMeta);
  }
}

class SocialGraph extends Component<SocialGraphSignature> {
  willDestroy(): void {
    super.willDestroy();
    OGManager.removeMeta(this);
  }

  setMeta = (args: SocialGraphSignature['Args']) => {
    OGManager.setMeta(this, args);
  }

  <template>
    {{this.setMeta this.args}}
  </template>;
}
export default SocialGraph;
