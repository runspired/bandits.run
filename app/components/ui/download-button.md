# DownloadButton Component

A reusable, accessible button component for indicating download/installation status with visual feedback through animated glows and icons.

## Features

- **Four distinct states**: available, downloading, complete, error
- **Visual feedback**: Color-coded glows (grey, rotating progress, green, red)
- **Progress indicator**: Animated rotating glow during download
- **Accessibility**: ARIA labels and keyboard navigation
- **Theme-aware**: Automatically adapts to light/dark mode
- **Reduced motion support**: Respects `prefers-reduced-motion`
- **Mobile responsive**: Adjusts size on smaller screens

## Usage

### Basic Example

```gts
import DownloadButton from '#ui/download-button.gts';

<template>
  <DownloadButton
    @status="available"
    @onClick={{this.handleDownload}}
  />
</template>
```

### With Progress Tracking

```gts
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import DownloadButton, { type DownloadStatus } from '#ui/download-button.gts';

export default class MyComponent extends Component {
  @tracked status: DownloadStatus = 'available';
  @tracked progress = 0;

  handleDownload = async () => {
    this.status = 'downloading';
    this.progress = 0;

    try {
      // Simulate download with progress updates
      for (let i = 0; i <= 100; i += 10) {
        this.progress = i;
        await new Promise(resolve => setTimeout(resolve, 200));
      }
      this.status = 'complete';
    } catch (error) {
      this.status = 'error';
    }
  };

  <template>
    <DownloadButton
      @status={{this.status}}
      @progress={{this.progress}}
      @onClick={{this.handleDownload}}
    />
  </template>
}
```

### Custom Icon

```gts
import { faCloudDownload } from '@fortawesome/free-solid-svg-icons';

<template>
  <DownloadButton
    @status="available"
    @icon={{faCloudDownload}}
    @onClick={{this.handleDownload}}
  />
</template>
```

### Custom Aria Label

```gts
<template>
  <DownloadButton
    @status="complete"
    @ariaLabel="Trail map downloaded and ready for offline use"
  />
</template>
```

## API

### Arguments

| Argument | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `@status` | `DownloadStatus` | Yes | - | Current download state: `'available'`, `'downloading'`, `'complete'`, or `'error'` |
| `@progress` | `number` | No | `0` | Download progress from 0-100 (only relevant when status is `'downloading'`) |
| `@onClick` | `() => void` | No | - | Callback when button is clicked (only fires when status is `'available'`) |
| `@icon` | `IconDefinition` | No | `faDownload` | Font Awesome icon to display |
| `@disabled` | `boolean` | No | `false` | Whether the button is disabled |
| `@ariaLabel` | `string` | No | Auto-generated | Accessible label for screen readers |

### Status Types

```typescript
type DownloadStatus = 'available' | 'downloading' | 'complete' | 'error';
```

#### Status Details

- **`'available'`**: Ready to download
  - Grey background glow
  - Clickable (if not disabled)
  - Displays the main icon

- **`'downloading'`**: Download in progress
  - Rotating color gradient glow (orange → yellow → green)
  - Animated spinner ring
  - Not clickable
  - Displays the main icon

- **`'complete'`**: Successfully downloaded
  - Green background glow
  - Not clickable
  - Displays main icon + small green checkmark badge

- **`'error'`**: Download failed
  - Red background glow with pulse animation
  - Not clickable
  - Displays the main icon

## Styling

The component uses CSS custom properties from your theme system:

- `--theme-white-black`: Icon and border color (adapts to theme)
- `--bg-sky`: Background color for checkmark badge border

### Size Customization

Default size is 60x60px (50x50px on mobile). You can customize by adding a class:

```gts
<DownloadButton
  @status="available"
  @onClick={{this.handleDownload}}
  class="custom-size"
/>
```

```css
.custom-size {
  width: 80px;
  height: 80px;
}

.custom-size .download-button__icon {
  font-size: 2rem;
}
```

## Real-World Examples

### Service Worker Installation

```typescript
import DownloadButton, { type DownloadStatus } from '#ui/download-button.gts';
import { tracked } from '@glimmer/tracking';
import { registerSW } from 'virtual:pwa-register';

export default class OfflineSettings extends Component {
  @tracked status: DownloadStatus = 'available';
  @tracked progress = 0;

  get isOfflineAvailable() {
    return 'serviceWorker' in navigator;
  }

  installPWA = () => {
    if (!this.isOfflineAvailable) return;

    this.status = 'downloading';
    this.progress = 0;

    registerSW({
      immediate: true,
      onRegisteredSW: () => {
        this.progress = 100;
        this.status = 'complete';
      },
      onRegisterError: () => {
        this.status = 'error';
      },
    });
  };

  <template>
    <DownloadButton
      @status={{this.status}}
      @progress={{this.progress}}
      @onClick={{this.installPWA}}
    />
  </template>
}
```

### File Download with Fetch API

```typescript
downloadFile = async (url: string) => {
  this.status = 'downloading';
  this.progress = 0;

  try {
    const response = await fetch(url);
    const reader = response.body?.getReader();
    const contentLength = Number(response.headers.get('Content-Length'));

    let receivedLength = 0;
    const chunks: Uint8Array[] = [];

    while (true) {
      const { done, value } = await reader!.read();
      if (done) break;

      chunks.push(value);
      receivedLength += value.length;
      this.progress = Math.round((receivedLength / contentLength) * 100);
    }

    // Process the downloaded file...
    this.status = 'complete';
  } catch (error) {
    this.status = 'error';
  }
};
```

### Asset Caching

```typescript
cacheAssets = async (assets: string[]) => {
  this.status = 'downloading';
  this.progress = 0;

  try {
    const cache = await caches.open('app-assets-v1');
    const total = assets.length;

    for (let i = 0; i < assets.length; i++) {
      await cache.add(assets[i]);
      this.progress = Math.round(((i + 1) / total) * 100);
    }

    this.status = 'complete';
  } catch (error) {
    this.status = 'error';
  }
};
```

## Accessibility

The component follows accessibility best practices:

- Semantic `<button>` element
- ARIA labels for screen readers
- Keyboard accessible (native button behavior)
- Disabled state prevents interaction
- Respects `prefers-reduced-motion` preference
- Sufficient color contrast for all states

## Browser Support

Works in all modern browsers that support:
- CSS custom properties
- CSS animations
- `conic-gradient` (for progress visualization)

Gracefully degrades in older browsers with simpler styling.
