# View Transitions

This application uses the [View Transitions API](https://developer.mozilla.org/en-US/docs/Web/API/View_Transitions_API) to provide smooth, animated page transitions with directional awareness (forward/backward navigation).

## Features

- **Automatic direction detection**: The app tracks navigation history to determine if you're going forward or backward
- **Slide animations**: Forward navigation slides in from the right, backward slides in from the left
- **Browser back/forward support**: Works with browser navigation buttons
- **Accessibility**: Respects `prefers-reduced-motion` for users who need reduced animation
- **Progressive enhancement**: Gracefully falls back to instant navigation on browsers that don't support View Transitions API
- **TypeScript support**: Fully typed service and components

## Browser Support

View Transitions API is supported in:
- Chrome/Edge 111+
- Safari 18+
- Opera 97+

On unsupported browsers, navigation will work normally without animations.

## Usage

### Option 1: Using the VtLink Component (Recommended)

Replace standard `LinkTo` components with `VtLink` for automatic view transitions:

```gts
import VtLink from '#app/components/vt-link.gts';

<template>
  <VtLink @route="organizations.single" @model={{org.id}}>
    {{org.name}}
  </VtLink>
</template>
```

With multiple models:

```gts
<VtLink @route="organizations.runs.single" @models={{array org.id run.id}}>
  View Run
</VtLink>
```

With query params:

```gts
<VtLink @route="search" @query={{hash q="trail running"}}>
  Search
</VtLink>
```

### Option 2: Using the Modifier

Apply the `view-transition-link` modifier to any anchor tag:

```gts
<a href="/organizations/1" {{view-transition-link}}>
  Organization
</a>
```

Or with a named route:

```gts
<a {{view-transition-link route="organizations.single" model=org.id}}>
  {{org.name}}
</a>
```

### Option 3: Programmatic Navigation

Use the `view-transition` service directly:

```typescript
import { service } from '@ember/service';
import Component from '@glimmer/component';
import type ViewTransitionService from '../services/view-transition';

export default class MyComponent extends Component {
  @service('view-transition') declare viewTransition: ViewTransitionService;

  navigateToOrg = async (orgId: string) => {
    await this.viewTransition.transitionTo('organizations.single', orgId);
  };

  navigateToURL = async (url: string) => {
    await this.viewTransition.transitionToURL(url);
  };

  // Custom transition with manual direction control
  customTransition = async () => {
    await this.viewTransition.withTransition(
      () => {
        // Your DOM update code here
      },
      'backward' // or 'forward'
    );
  };
}
```

## How It Works

### Direction Detection

The `view-transition` service maintains a navigation history stack and determines direction by:

1. **Forward**: Navigating to a new route or one that's ahead in the history
2. **Backward**: Navigating to a route that appears earlier in the history stack
3. **Browser navigation**: Detects popstate events (back/forward buttons) and tracks them appropriately

### Animation Flow

1. User clicks a VtLink or triggers programmatic navigation
2. Service determines the direction (forward/backward)
3. Adds a direction class (`forward` or `backward`) to the document element
4. Starts the View Transition
5. Performs the route transition
6. Browser animates the old and new page states
7. Removes the direction class

### CSS Animation Details

The animations are defined in `app/styles/app.css`:

- **Forward navigation**: Old page slides left 30%, new page slides in from right
- **Backward navigation**: Old page slides right 30%, new page slides in from left
- **Duration**: 300ms with a smooth cubic-bezier easing
- **Opacity**: Fades during transition for smoother effect

## Customization

### Adjusting Animation Speed

Edit the CSS variables in `app/styles/app.css`:

```css
:root {
  --vt-duration: 300ms; /* Change this */
  --vt-easing: cubic-bezier(0.4, 0, 0.2, 1); /* Or this */
}
```

### Different Animation Styles

You can modify the keyframes in `app/styles/app.css`. Current animations:

- `slide-out-to-left` / `slide-in-from-right` (forward)
- `slide-out-to-right` / `slide-in-from-left` (backward)

Example alternative (fade only):

```css
@keyframes fade-out {
  to { opacity: 0; }
}

@keyframes fade-in {
  from { opacity: 0; }
}

::view-transition-old(root) {
  animation-name: fade-out;
}

::view-transition-new(root) {
  animation-name: fade-in;
}
```

### Per-Element Transitions

You can animate specific elements independently by giving them a `view-transition-name`:

```css
.header {
  view-transition-name: header;
}

::view-transition-old(header),
::view-transition-new(header) {
  animation-duration: 500ms;
}
```

## Accessibility

The implementation respects user preferences:

```css
@media (prefers-reduced-motion: reduce) {
  ::view-transition-old(root),
  ::view-transition-new(root) {
    animation-duration: 1ms !important;
  }
}
```

This ensures users who prefer reduced motion get near-instant transitions.

## Migration Guide

To add view transitions to existing links:

### Before:
```gts
import { LinkTo } from '@ember/routing';

<LinkTo @route="organizations.single" @model={{org.id}}>
  {{org.name}}
</LinkTo>
```

### After:
```gts
import VtLink from '#app/components/vt-link.gts';

<VtLink @route="organizations.single" @model={{org.id}}>
  {{org.name}}
</VtLink>
```

## Troubleshooting

### Transitions aren't working

1. Check browser support in DevTools console
2. Verify the `view-transition` service is properly injected
3. Ensure you're not using `target="_blank"` or modifier keys (Ctrl/Cmd)

### Transitions are too slow/fast

Adjust `--vt-duration` in `app/styles/app.css`

### Wrong direction detection

The service uses a navigation history stack. If you're seeing incorrect directions, it might be due to:
- Direct URL entry (defaults to forward)
- External navigation that bypasses the service
- You can manually specify direction with `withTransition(callback, 'forward' | 'backward')`

## Resources

- [View Transitions API (MDN)](https://developer.mozilla.org/en-US/docs/Web/API/View_Transitions_API)
- [Smooth and simple transitions with the View Transitions API](https://developer.chrome.com/docs/web-platform/view-transitions/)
- [Can I Use: View Transitions](https://caniuse.com/view-transitions)
