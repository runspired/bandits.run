# Markdown Content Guide

This guide explains how to use markdown descriptions in the bandits.run application.

## Overview

Each organization, user, location, and run can have an optional markdown description that is compiled to HTML and included in the application data.

## File Naming Convention

Markdown files must have the same base name as their corresponding TypeScript data files:

| Data File | Markdown File |
|-----------|---------------|
| `organizations/001_bay-bandits.ts` | `organizations/001_bay-bandits.md` |
| `users/001_chris-thoburn.ts` | `users/001_chris-thoburn.md` |
| `locations/001_skyline-gate.ts` | `locations/001_skyline-gate.md` |
| `runs/001_bay-bandits/runday.ts` | `runs/001_bay-bandits/runday.md` |

## Markdown Features

### Standard Markdown

All standard markdown syntax is supported:

```markdown
# Headings (H1-H6)

**Bold text** and *italic text*

- Unordered lists
- With multiple items

1. Ordered lists
2. Also supported

[Links](https://example.com)

![Images](image.jpg)

> Blockquotes for
> emphasized content

`Inline code` and code blocks:
\`\`\`javascript
const code = 'with syntax highlighting';
\`\`\`
```

### Syntax Highlighting

Code blocks support syntax highlighting with Shiki, using GitHub's light/dark themes:

```markdown
\`\`\`typescript
interface TrailRun {
  title: string;
  distance: string;
  elevation: number;
}
\`\`\`

\`\`\`bash
pnpm api:compile
\`\`\`
```

Supported languages include: JavaScript, TypeScript, Python, Bash, CSS, HTML, JSON, and many more.

### Custom Containers

Use special container syntax for callouts:

```markdown
:::tip Pro Tip
This is helpful information for users!
:::

:::warning Watch Out
Be careful about trail conditions after rain.
:::

:::danger Important
This is critical safety information.
:::

:::info Good to Know
Additional context or background information.
:::

:::details Click to Expand
Collapsible content (requires JavaScript handler).
:::
```

### Tables

Create tables with markdown syntax:

```markdown
| Distance | Elevation | Difficulty |
|----------|-----------|------------|
| 6-8 mi   | 1000 ft   | Moderate   |
| 3-5 mi   | 600 ft    | Easy       |
```

### Heading Anchors

All headings automatically get anchor links:

```markdown
## Getting Started

This creates an anchor at #getting-started
```

Users can link directly to sections: `#getting-started`

### HTML Attributes

Add CSS classes and IDs to elements:

```markdown
This paragraph has a class {.highlight}

## Special Heading {#custom-id .special-heading}

![Image with class](image.jpg){.rounded}
```

## Styling in the App

The compiled HTML is rendered with the `.markdown-content` wrapper class. CSS is provided in [app/styles/markdown.css](../app/styles/markdown.css).

### Using in Components

To display markdown content in an Ember component:

```handlebars
<div class="markdown-content">
  {{! Safe to use triple-stash because content is pre-sanitized }}
  {{{@description.descriptionHtml}}}
</div>
```

### Dark Mode Support

The markdown styles automatically adapt to dark mode via:
- `@media (prefers-color-scheme: dark)` for system preferences
- `.dark-mode` class for manual dark mode

## Example: Organization Description

Here's a complete example for an organization:

**File**: `api/seeds/organizations/001_bay-bandits.md`

```markdown
# About Bay Bandits

The Bay Bandits is a **trail running community** in the San Francisco Bay Area.

## Our Mission

:::tip Community First
We believe in making trail running accessible to everyone!
:::

### Weekly Schedule

| Day      | Time    | Location      |
|----------|---------|---------------|
| Monday   | 6:00 PM | Skyline Gate  |
| Thursday | 6:00 PM | Serpentine    |

## Getting Started

New runners welcome! Here's what to bring:

- Trail shoes with good grip
- Headlamp (for evening runs)
- Water bottle
- Positive attitude!

\`\`\`javascript
// Join us on Strava
const club = {
  name: 'Bay Bandits',
  id: '504077',
  vibe: 'awesome'
};
\`\`\`

:::warning Trail Etiquette
Always yield to hikers and stay on marked trails.
:::
```

## Compilation Process

1. **Development**: Edit markdown files in `api/seeds/`
2. **Compile**: Run `pnpm api:compile` to process markdown to HTML
3. **Access**: The HTML is available in `descriptionHtml` field

```typescript
import { compile } from './api/compile.ts';

const data = await compile();
const org = data.organizations.get('1');

if (org.descriptionHtml) {
  // Use the compiled HTML
  console.log(org.descriptionHtml);
}
```

## Best Practices

### Content Organization

- **Keep it concise**: Focus on essential information
- **Use headings**: Create scannable structure
- **Leverage containers**: Highlight important tips/warnings
- **Add context**: Explain things newcomers might not know

### Accessibility

- Use descriptive link text (not "click here")
- Provide alt text for images
- Use semantic heading hierarchy (H1 → H2 → H3)
- Ensure good color contrast in custom styles

### Performance

- Optimize images before including them
- Keep markdown files under 50KB when possible
- Use code highlighting sparingly (it adds bundle size)

### Maintainability

- Follow consistent heading structure across all entities
- Use the same container types (tip, warning, etc.) consistently
- Document complex tables with captions
- Keep code examples relevant and tested

## Troubleshooting

### Markdown not showing up

1. Check file naming matches exactly (including `.md` extension)
2. Verify file is in the correct directory
3. Run `pnpm api:compile` to rebuild
4. Check compile output for markdown count

### Styling looks wrong

1. Ensure HTML is wrapped in `.markdown-content` div
2. Check that `app/styles/markdown.css` is imported
3. Verify CSS custom properties are defined
4. Test in both light and dark modes

### Code highlighting not working

1. Verify language identifier in code fence: \`\`\`javascript
2. Check that Shiki is properly installed
3. Ensure `@shikijs/markdown-it` is in dependencies

## Resources

- [Markdown Guide](https://www.markdownguide.org/)
- [VitePress Containers](https://vitepress.dev/guide/markdown#custom-containers)
- [Shiki Documentation](https://shiki.matsu.io/)
- [markdown-it Plugins](https://github.com/markdown-it/markdown-it#plugins)
