import { pageTitle } from 'ember-page-title';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';
import { initializeColorScheme, toggleColorScheme as baseToggleColorScheme } from './index.gts';

let useTransparentBackground = false;

const lightThemeDefaultColors = {
  logo: null as string | null,
  background: null as string | null,
  backHill: null as string | null,
  tree: null as string | null,
  altTree: null as string | null,
}
const darkThemeDefaultColors = {
  logo: null as string | null,
  background: null as string | null,
  backHill: null as string | null,
  tree: null as string | null,
  altTree: null as string | null,
}

// Store colors separately for light and dark modes
const lightModeColors = {
  logo: null as string | null,
  background: null as string | null,
  backHill: null as string | null,
  tree: null as string | null,
  altTree: null as string | null,
};

const darkModeColors = {
  logo: null as string | null,
  background: null as string | null,
  backHill: null as string | null,
  tree: null as string | null,
  altTree: null as string | null,
};

// Helper to get current mode's colors
function getCurrentModeColors() {
  return globalThis.document.body.classList.contains('dark-mode') ? darkModeColors : lightModeColors;
}

// Helper to get current mode's default colors
function getCurrentModeDefaults() {
  return globalThis.document.body.classList.contains('dark-mode') ? darkThemeDefaultColors : lightThemeDefaultColors;
}

// Initialize defaults from CSS if not already set
function initializeDefaults() {
  const defaults = getCurrentModeDefaults();

  if (defaults.logo === null) {
    const body = globalThis.document.body;
    const themeColor = globalThis.getComputedStyle(body).getPropertyValue('--title').trim();
    const titleElement = globalThis.document.querySelector('h1.title') as HTMLElement;
    const fallbackColor = titleElement
      ? globalThis.getComputedStyle(titleElement).getPropertyValue('color')
      : '';

    const computedColor = themeColor || fallbackColor || '#9333ea';
    defaults.logo = rgbToHex(computedColor);
  }

  if (defaults.background === null) {
    const body = globalThis.document.body;
    const computedBg = globalThis.getComputedStyle(body).getPropertyValue('--bg-sky').trim();
    defaults.background = rgbToHex(computedBg || '#f3e8ff');
  }

  if (defaults.backHill === null) {
    const body = globalThis.document.body;
    const computed = globalThis.getComputedStyle(body).getPropertyValue('--color-hill-back').trim();
    defaults.backHill = rgbToHex(computed || '#ff69b4');
  }

  if (defaults.tree === null) {
    const body = globalThis.document.body;
    const computed = globalThis.getComputedStyle(body).getPropertyValue('--tree-color').trim();
    defaults.tree = rgbToHex(computed || '#052c16');
  }

  if (defaults.altTree === null) {
    const body = globalThis.document.body;
    const computed = globalThis.getComputedStyle(body).getPropertyValue('--alt-tree-color').trim();
    defaults.altTree = rgbToHex(computed || '#06a743');
  }
}

// Get effective color (override or default)
function getEffectiveColor(colorKey: 'logo' | 'background' | 'backHill' | 'tree' | 'altTree'): string {
  const modeColors = getCurrentModeColors();
  const defaults = getCurrentModeDefaults();
  return modeColors[colorKey] || defaults[colorKey] || '#000000';
}

// Apply theme colors to CSS variables (scoped to .themeable elements)
function updateThemeColors() {
  const themeables = Array.from(
    globalThis.document.querySelectorAll('.themeable')
  ) as unknown as HTMLDivElement[];

  if (!themeables.length) return;

  const logoColor = getEffectiveColor('logo');
  const titleColor = getTitleColor();
  const backgroundColor = getEffectiveColor('background');
  const backHillColor = getEffectiveColor('backHill');
  const treeColor = getEffectiveColor('tree');
  const altTreeColor = getEffectiveColor('altTree');

  themeables.forEach((element) => {
    if (backgroundColor) {
      element.style.setProperty('--bg-sky', backgroundColor);
    }

    if (backHillColor) {
      element.style.setProperty('--color-hill-back', backHillColor);
    }

    if (logoColor) {
      element.style.setProperty('--color-hill-front', logoColor);
      element.style.setProperty('--title', titleColor);
      element.style.setProperty('--custom-logo-color', titleColor);
    }

    if (treeColor) {
      element.style.setProperty('--tree-color', treeColor);
    }

    if (altTreeColor) {
      element.style.setProperty('--alt-tree-color', altTreeColor);
    }
  });

  // Update square logo backgrounds (only on themeable instances)
  const logoElements = globalThis.document.querySelectorAll(
    '.square-logo.themeable'
  ) as unknown as HTMLDivElement[];

  logoElements.forEach((logoElement) => {
    if (useTransparentBackground) {
      logoElement.style.backgroundColor = '';
    } else {
      const r = parseInt(backgroundColor.slice(1, 3), 16);
      const g = parseInt(backgroundColor.slice(3, 5), 16);
      const b = parseInt(backgroundColor.slice(5, 7), 16);
      logoElement.style.backgroundColor = `rgba(${r}, ${g}, ${b}, ${backgroundOpacity})`;
    }
  });
}

let logoOpacity = 1;
let backgroundOpacity = 1;

function handleColorChange(event: Event) {
  const input = event.target as HTMLInputElement;
  const modeColors = getCurrentModeColors();
  modeColors.logo = input.value;
  updateThemeColors();
  updatePreviews();
}

function handleOpacityChange(event: Event) {
  const input = event.target as HTMLInputElement;
  logoOpacity = parseFloat(input.value);
  updateThemeColors();

  // Update opacity label
  const label = globalThis.document.querySelector(
    '.opacity-value'
  ) as HTMLElement;
  if (label) {
    label.textContent = Math.round(logoOpacity * 100) + '%';
  }

  updatePreviews();
}

function handleBackgroundColorChange(event: Event) {
  const input = event.target as HTMLInputElement;
  const modeColors = getCurrentModeColors();
  modeColors.background = input.value;
  updateThemeColors();
  updatePreviews();
}

function handleBackgroundOpacityChange(event: Event) {
  const input = event.target as HTMLInputElement;
  backgroundOpacity = parseFloat(input.value);
  updateThemeColors();

  const label = globalThis.document.querySelector(
    '.background-opacity-value'
  ) as HTMLElement;
  if (label) {
    label.textContent = Math.round(backgroundOpacity * 100) + '%';
  }

  updatePreviews();
}

function handleBackHillColorChange(event: Event) {
  const input = event.target as HTMLInputElement;
  const modeColors = getCurrentModeColors();
  modeColors.backHill = input.value;
  updateThemeColors();
  updatePreviews();
}

function handleTreeColorChange(event: Event) {
  const input = event.target as HTMLInputElement;
  const modeColors = getCurrentModeColors();
  modeColors.tree = input.value;
  updateThemeColors();
  updatePreviews();
}

function handleAltTreeColorChange(event: Event) {
  const input = event.target as HTMLInputElement;
  const modeColors = getCurrentModeColors();
  modeColors.altTree = input.value;
  updateThemeColors();
  updatePreviews();
}

function resetColors() {
  // Reset mode overrides to defaults
  const modeColors = getCurrentModeColors();

  modeColors.logo = null;
  modeColors.background = null;
  modeColors.backHill = null;
  modeColors.tree = null;
  modeColors.altTree = null;

  logoOpacity = 1;
  backgroundOpacity = 1;

  // Reset opacity labels
  const opacityLabel = globalThis.document.querySelector('.opacity-value') as HTMLElement;
  const backgroundOpacityLabel = globalThis.document.querySelector('.background-opacity-value') as HTMLElement;
  if (opacityLabel) opacityLabel.textContent = '100%';
  if (backgroundOpacityLabel) backgroundOpacityLabel.textContent = '100%';

  // Update color pickers to show defaults
  initializeColorPickers();

  // Reapply theme colors
  updateThemeColors();
  updatePreviews();
}

function rgbToHex(rgb: string): string {
  if (rgb.startsWith('#')) {
    return rgb;
  }
  // Handle rgb(r, g, b) or rgba(r, g, b, a) format
  const match = rgb.match(/^rgba?\((\d+),\s*(\d+),\s*(\d+)/);
  if (!match) return '#9333ea'; // fallback

  const r = parseInt(match[1]!);
  const g = parseInt(match[2]!);
  const b = parseInt(match[3]!);

  return (
    '#' +
    [r, g, b]
      .map((x) => {
        const hex = x.toString(16);
        return hex.length === 1 ? '0' + hex : hex;
      })
      .join('')
  );
}

type RGB = { r: number; g: number; b: number };

function parseColorToRgb(color: string): RGB | null {
  if (color.startsWith('#')) {
    const hex = color.slice(1);
    if (hex.length === 3) {
      const r = parseInt(hex[0]! + hex[0], 16);
      const g = parseInt(hex[1]! + hex[1], 16);
      const b = parseInt(hex[2]! + hex[2], 16);
      return { r, g, b };
    }
    if (hex.length === 6) {
      const r = parseInt(hex.slice(0, 2), 16);
      const g = parseInt(hex.slice(2, 4), 16);
      const b = parseInt(hex.slice(4, 6), 16);
      return { r, g, b };
    }
    return null;
  }

  const match = color.match(/^rgba?\((\d+),\s*(\d+),\s*(\d+)/);
  if (!match) return null;

  return {
    r: parseInt(match[1]!, 10),
    g: parseInt(match[2]!, 10),
    b: parseInt(match[3]!, 10),
  };
}

function applyOpacityToColor(color: string, opacity: number): string {
  const rgb = parseColorToRgb(color);
  if (!rgb) return color;

  return `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, ${opacity})`;
}

// Initialize color pickers to show effective colors (overrides or defaults)
function initializeColorPickers() {
  const colorInput = globalThis.document.querySelector('.logo-color-input') as HTMLInputElement;
  const backgroundInput = globalThis.document.querySelector('.background-color-input') as HTMLInputElement;
  const backHillInput = globalThis.document.querySelector('.back-hill-color-input') as HTMLInputElement;
  const treeInput = globalThis.document.querySelector('.tree-color-input') as HTMLInputElement;
  const altTreeInput = globalThis.document.querySelector('.alt-tree-color-input') as HTMLInputElement;
  const opacityInput = globalThis.document.querySelector('.logo-opacity-input') as HTMLInputElement;
  const backgroundOpacityInput = globalThis.document.querySelector('.background-opacity-input') as HTMLInputElement;

  if (colorInput) colorInput.value = getEffectiveColor('logo');
  if (backgroundInput) backgroundInput.value = getEffectiveColor('background');
  if (backHillInput) backHillInput.value = getEffectiveColor('backHill');
  if (treeInput) treeInput.value = getEffectiveColor('tree');
  if (altTreeInput) altTreeInput.value = getEffectiveColor('altTree');
  if (opacityInput) opacityInput.value = logoOpacity.toString();
  if (backgroundOpacityInput) backgroundOpacityInput.value = backgroundOpacity.toString();
}

const initColorPicker = modifier(() => {
  // Initialize color picker after a short delay to ensure DOM is ready
  globalThis.setTimeout(() => {
    // Initialize defaults for this mode if needed
    initializeDefaults();

    // Set color pickers to show effective colors
    initializeColorPickers();

    // Apply theme colors
    updateThemeColors();
    updatePreviews();
  }, 100);
});

function isDebugMode(): boolean {
  const hash = globalThis.location.hash;
  const queryStart = hash.indexOf('?');
  if (queryStart === -1) return false;

  const queryString = hash.substring(queryStart + 1);
  const urlParams = new URLSearchParams(queryString);
  return urlParams.get('debug') === 'true';
}

// Get title color with opacity
function getTitleColor(): string {
  const logoColor = getEffectiveColor('logo');
  return applyOpacityToColor(logoColor, logoOpacity);
}

// Get background color with opacity
function getBackgroundColor(): string {
  const backgroundColor = getEffectiveColor('background');
  return applyOpacityToColor(backgroundColor, backgroundOpacity);
}

// Shared logo dimension calculations
function calculateLogoDimensions(size: number) {
  const padding = fitToContent ? 0 : 6;
  const sizeFactor = fitToContent ? 38: 50;
  const leftMargin = size * (padding / sizeFactor);

  const chevronSize = (size * 11) / sizeFactor;
  const chevronMargin = (size * 1) / sizeFactor;
  const fontSize = (size * 5) / sizeFactor;
  const lineHeight = (size * 6) / sizeFactor;
  const iconOffsetY = (lineHeight * 2 - chevronSize) / 2;

  const totalHeight = 2 * lineHeight;

  const offsetX = leftMargin;
  const offsetY = fitToContent ? 0 : (size - totalHeight) / 2;
  const boxWidth = size;
  const boxHeight = fitToContent ? totalHeight : size;

  return {
    boxWidth,
    boxHeight,
    chevronSize,
    chevronMargin,
    fontSize,
    lineHeight,
    iconOffsetY,
    totalHeight,
    offsetX,
    offsetY,
  };
}

function updatePreviews() {
  generateSVGPreview();
  generatePNGPreview();
  generateStravaBannerPreview();
}

// Generate SVG - shared by both preview and download
function generateSVG(size: number, titleColor: string): Promise<SVGSVGElement> {
  const svgNS = 'http://www.w3.org/2000/svg';
  const svg = globalThis.document.createElementNS(svgNS, 'svg');

  // If chevron only mode, use different dimensions
  if (chevronOnly) {
    const chevronSize = size * 0.75;
    const boxWidth = size;
    const boxHeight = size;

    svg.setAttribute('xmlns', svgNS);
    svg.setAttribute('viewBox', `0 0 ${boxWidth} ${boxHeight}`);

    // Add background
    const rect = globalThis.document.createElementNS(svgNS, 'rect');
    rect.setAttribute('width', boxWidth.toString());
    rect.setAttribute('height', boxHeight.toString());

    if (!useTransparentBackground) {
      const backgroundColor = getBackgroundColor();
      rect.setAttribute('fill', backgroundColor);
    } else {
      rect.setAttribute('fill', 'none');
    }
    svg.appendChild(rect);

    // Fetch chevron SVG and render centered
    return globalThis
      .fetch('/logo-orange-chevron.svg')
      .then((response) => response.text())
      .then((chevronSvgText) => {
        const parser = new DOMParser();
        const chevronDoc = parser.parseFromString(
          chevronSvgText,
          'image/svg+xml'
        );
        const chevronSvgEl = chevronDoc.documentElement;

        const defs = globalThis.document.createElementNS(svgNS, 'defs');
        const symbol = globalThis.document.createElementNS(svgNS, 'symbol');
        symbol.setAttribute('id', `chevron-${Date.now()}`);
        symbol.setAttribute(
          'viewBox',
          chevronSvgEl.getAttribute('viewBox') || '0 0 100 100'
        );

        Array.from(chevronSvgEl.children).forEach((child) => {
          const importedChild = globalThis.document.importNode(
            child,
            true
          ) as SVGElement;
          if (importedChild instanceof SVGElement) {
            importedChild.removeAttribute('fill');
            importedChild.setAttribute('fill', titleColor);
          }
          symbol.appendChild(importedChild);
        });

        defs.appendChild(symbol);
        svg.appendChild(defs);

        // Center the chevron
        const chevronX = (boxWidth - chevronSize) / 2;
        const chevronY = (boxHeight - chevronSize) / 2;

        const useEl = globalThis.document.createElementNS(svgNS, 'use');
        useEl.setAttribute('href', `#${symbol.id}`);
        useEl.setAttribute('x', chevronX.toString());
        useEl.setAttribute('y', chevronY.toString());
        useEl.setAttribute('width', chevronSize.toString());
        useEl.setAttribute('height', chevronSize.toString());
        useEl.setAttribute('fill', titleColor);
        svg.appendChild(useEl);

        return svg;
      });
  }

  // Use shared dimension calculations
  const {
    boxWidth,
    boxHeight,
    chevronSize,
    chevronMargin,
    fontSize,
    lineHeight,
    iconOffsetY,
    offsetX,
    offsetY,
  } = calculateLogoDimensions(size);

  // svg.setAttribute('width', boxWidth.toString());
  // svg.setAttribute('height', boxHeight.toString());
  svg.setAttribute('xmlns', svgNS);
  svg.setAttribute('viewBox', `0 0 ${boxWidth} ${boxHeight}`);

  // Add background
  const rect = globalThis.document.createElementNS(svgNS, 'rect');
  rect.setAttribute('width', boxWidth.toString());
  rect.setAttribute('height', boxHeight.toString());

  if (!useTransparentBackground) {
    const backgroundColor = getBackgroundColor();
    rect.setAttribute('fill', backgroundColor);
  } else {
    rect.setAttribute('fill', 'none');
  }
  svg.appendChild(rect);

  // Fetch chevron SVG and render
  return globalThis
    .fetch('/logo-orange-chevron.svg')
    .then((response) => response.text())
    .then((chevronSvgText) => {
      // Parse chevron SVG and create symbol
      const parser = new DOMParser();
      const chevronDoc = parser.parseFromString(
        chevronSvgText,
        'image/svg+xml'
      );
      const chevronSvgEl = chevronDoc.documentElement;

      const defs = globalThis.document.createElementNS(svgNS, 'defs');
      const symbol = globalThis.document.createElementNS(svgNS, 'symbol');
      symbol.setAttribute('id', `chevron-${Date.now()}`);
      symbol.setAttribute(
        'viewBox',
        chevronSvgEl.getAttribute('viewBox') || '0 0 100 100'
      );

      Array.from(chevronSvgEl.children).forEach((child) => {
        const importedChild = globalThis.document.importNode(
          child,
          true
        ) as SVGElement;
        // Remove any fill attributes to allow the use element to control the color
        if (importedChild instanceof SVGElement) {
          importedChild.removeAttribute('fill');
          importedChild.setAttribute('fill', titleColor);
        }
        symbol.appendChild(importedChild);
      });

      defs.appendChild(symbol);
      svg.appendChild(defs);

      const g = globalThis.document.createElementNS(svgNS, 'g');
      g.setAttribute('transform', `translate(${offsetX}, ${offsetY})`);

      // Use chevron symbol
      const useEl = globalThis.document.createElementNS(svgNS, 'use');
      useEl.setAttribute('href', `#${symbol.id}`);
      useEl.setAttribute('x', '0');
      useEl.setAttribute('y', iconOffsetY.toString());
      useEl.setAttribute('width', chevronSize.toString());
      useEl.setAttribute('height', chevronSize.toString());
      useEl.setAttribute('fill', titleColor);
      g.appendChild(useEl);

      // Text
      const text1 = globalThis.document.createElementNS(svgNS, 'text');
      text1.setAttribute('x', (chevronSize + chevronMargin).toString());
      text1.setAttribute('y', fontSize.toString());
      text1.setAttribute('font-family', 'Montserrat, sans-serif');
      text1.setAttribute('font-size', fontSize.toString());
      text1.setAttribute('font-weight', '800');
      text1.setAttribute('font-style', 'italic');
      text1.setAttribute('fill', titleColor);
      text1.setAttribute('text-transform', 'uppercase');
      text1.textContent = 'BAY';
      g.appendChild(text1);

      const text2 = globalThis.document.createElementNS(svgNS, 'text');
      text2.setAttribute('x', (chevronSize + chevronMargin).toString());
      text2.setAttribute('y', (fontSize + lineHeight).toString());
      text2.setAttribute('font-family', 'Montserrat, sans-serif');
      text2.setAttribute('font-size', fontSize.toString());
      text2.setAttribute('font-weight', '800');
      text2.setAttribute('font-style', 'italic');
      text2.setAttribute('fill', titleColor);
      text2.setAttribute('text-transform', 'uppercase');
      text2.textContent = 'BANDITS';
      g.appendChild(text2);

      svg.appendChild(g);

      return svg;
    });
}

// Generate PNG - shared by both preview and download
function generatePNG(
  size: number,
  titleColor: string,
  scale: number = 1
): Promise<HTMLCanvasElement> {
  const canvas = globalThis.document.createElement('canvas');
  const ctx = canvas.getContext('2d');
  if (!ctx) return Promise.reject(new Error('Cannot get canvas context'));

  // If chevron only mode, use different dimensions
  if (chevronOnly) {
    const chevronSize = size * 0.75;
    canvas.width = size * scale;
    canvas.height = size * scale;

    ctx.scale(scale, scale);

    // Draw background
    if (!useTransparentBackground) {
      const backgroundColor = getBackgroundColor();
      ctx.fillStyle = backgroundColor;
      ctx.fillRect(0, 0, size, size);
    } else {
      ctx.clearRect(0, 0, size, size);
    }

    // Load and draw centered chevron
    const img = new globalThis.Image();
    img.crossOrigin = 'anonymous';

    return new Promise((resolve) => {
      img.onload = () => {
        // eslint-disable-next-line warp-drive/no-legacy-request-patterns
        ctx.save();
        ctx.globalCompositeOperation = 'source-over';

        // Create a temporary canvas for the colored chevron
        const tempCanvas = globalThis.document.createElement('canvas');
        const tempCtx = tempCanvas.getContext('2d');
        if (!tempCtx) throw new Error('Cannot get temp canvas context');

        tempCanvas.width = chevronSize * scale;
        tempCanvas.height = chevronSize * scale;
        tempCtx.scale(scale, scale);

        // Draw the SVG as mask
        tempCtx.drawImage(img, 0, 0, chevronSize, chevronSize);

        // Apply color
        tempCtx.globalCompositeOperation = 'source-in';
        tempCtx.fillStyle = titleColor;
        tempCtx.fillRect(0, 0, chevronSize, chevronSize);

        // Draw colored chevron centered on main canvas
        const chevronX = (size - chevronSize) / 2;
        const chevronY = (size - chevronSize) / 2;
        ctx.drawImage(
          tempCanvas,
          chevronX,
          chevronY,
          chevronSize,
          chevronSize
        );
        ctx.restore();

        resolve(canvas);
      };
      img.src = '/logo-orange-chevron.svg';
    });
  }

  // Use shared dimension calculations
  const {
    boxWidth,
    boxHeight,
    chevronSize,
    chevronMargin,
    fontSize,
    lineHeight,
    offsetX,
    offsetY,
  } = calculateLogoDimensions(size);

  canvas.width = boxWidth * scale;
  canvas.height = boxHeight * scale;

  ctx.scale(scale, scale);

  // Draw background
  if (!useTransparentBackground) {
    const backgroundColor = getBackgroundColor();
    ctx.fillStyle = backgroundColor;
    ctx.fillRect(0, 0, size, size);
  } else {
    ctx.clearRect(0, 0, size, size);
  }

  // Load font and image before rendering
  const img = new globalThis.Image();
  img.crossOrigin = 'anonymous';

  return Promise.all([
    globalThis.document.fonts.load('italic 800 30px Montserrat'),
    new Promise((resolve) => {
      img.onload = resolve;
      img.src = '/logo-orange-chevron.svg';
    }),
  ]).then(() => {
    // Draw chevron with color overlay
    // eslint-disable-next-line warp-drive/no-legacy-request-patterns
    ctx.save();
    ctx.globalCompositeOperation = 'source-over';

    // Create a temporary canvas for the colored chevron
    const tempCanvas = globalThis.document.createElement('canvas');
    const tempCtx = tempCanvas.getContext('2d');
    if (!tempCtx) throw new Error('Cannot get temp canvas context');

    tempCanvas.width = chevronSize * scale;
    tempCanvas.height = chevronSize * scale;
    tempCtx.scale(scale, scale);

    // Draw the SVG as mask
    tempCtx.drawImage(img, 0, 0, chevronSize, chevronSize);

    // Apply color
    tempCtx.globalCompositeOperation = 'source-in';
    tempCtx.fillStyle = titleColor;
    tempCtx.fillRect(0, 0, chevronSize, chevronSize);

    // Draw colored chevron onto main canvas
    ctx.drawImage(
      tempCanvas,
      offsetX,
      offsetY,
      chevronSize,
      chevronSize
    );
    ctx.restore();

    // Draw text
    ctx.fillStyle = titleColor;
    ctx.font = `italic 800 ${fontSize}px Montserrat, sans-serif`;
    ctx.textBaseline = 'middle';
    const textX = offsetX + chevronSize + chevronMargin;
    const textBaselineY = offsetY + lineHeight / 2;
    ctx.fillText('BAY', textX, textBaselineY);
    ctx.fillText('BANDITS', textX, textBaselineY + lineHeight);

    return canvas;
  });
}

function generateSVGPreview() {
  const containers = Array.from(
    globalThis.document.querySelectorAll('.svg-preview-target')
  );
  if (!containers.length) return;

  const titleColor = getTitleColor();

  containers.forEach((container) => {
    const size = container.clientWidth || 300;

    if (!fitToContent) {
      container.classList.remove('fit-to-content');
    } else {
      container.classList.add('fit-to-content');
    }

    generateSVG(size, titleColor)
      .then((svg) => {
        container.innerHTML = '';
        container.appendChild(svg);
      })
      .catch(() => {
        container.innerHTML = '<p>Error generating preview</p>';
      });
  });
}

function generatePNGPreview() {
  const canvasElement = globalThis.document.getElementById(
    'png-preview'
  ) as HTMLCanvasElement;
  if (!canvasElement) return;

  if (!fitToContent) {
    canvasElement.parentElement?.classList.remove('fit-to-content');
  } else {
    canvasElement.parentElement?.classList.add('fit-to-content');
  }

  const size = 300;
  const titleColor = getTitleColor();

  // Use shared PNG generation
  generatePNG(size, titleColor, 1)
    .then((generatedCanvas) => {
      // Copy the generated canvas to the preview canvas
      const ctx = canvasElement.getContext('2d');
      if (!ctx) return;

      canvasElement.width = generatedCanvas.width;
      canvasElement.height = generatedCanvas.height;
      ctx.drawImage(generatedCanvas, 0, 0);
    })
    .catch((error) => {
      globalThis.console.error('Error generating PNG preview:', error);
    });
}

function toggleTransparentBackground() {
  useTransparentBackground = !useTransparentBackground;

  const button = globalThis.document.querySelector(
    '.transparent-toggle-btn'
  ) as HTMLButtonElement;
  const logoElement = globalThis.document.querySelector(
    '.square-logo'
  ) as HTMLElement;

  if (button) {
    button.textContent = useTransparentBackground
      ? 'Background: Transparent ✓'
      : 'Background: Themed';
  }

  if (logoElement) {
    if (useTransparentBackground) {
      logoElement.classList.add('transparent-bg');
    } else {
      logoElement.classList.remove('transparent-bg');
    }
  }

  updateThemeColors();
  updatePreviews();
}

let fitToContent = false;
function toggleFitToContent() {
  fitToContent = !fitToContent;
  const logoElement = globalThis.document.querySelector(
    '.square-logo'
  ) as HTMLElement;
  if (!logoElement) return;

  if (fitToContent) {
    logoElement.classList.add('fit-to-content');
  } else {
    logoElement.classList.remove('fit-to-content');
  }

  updatePreviews();
}

let chevronOnly = false;
function toggleChevronOnly() {
  chevronOnly = !chevronOnly;

  const button = globalThis.document.querySelector(
    '.chevron-only-toggle-btn'
  ) as HTMLButtonElement;

  if (button) {
    button.textContent = chevronOnly
      ? 'Chevron Only: Enabled ✓'
      : 'Chevron Only: Disabled';
  }

  updatePreviews();
}

let showBannerMasks = false;
function toggleBannerMasks() {
  showBannerMasks = !showBannerMasks;

  const button = globalThis.document.querySelector(
    '.banner-mask-toggle-btn'
  ) as HTMLButtonElement;

  if (button) {
    button.textContent = showBannerMasks
      ? 'Safe Area: Visible ✓'
      : 'Safe Area: Hidden';
  }

  updatePreviews();
}

function toggleColorScheme() {
  baseToggleColorScheme();
  // Update previews and color pickers after theme change to recalculate colors
  globalThis.setTimeout(() => {
    // Initialize defaults for the new mode if needed
    initializeDefaults();

    // Update color pickers to show effective colors for new mode
    initializeColorPickers();

    // Reapply theme colors
    updateThemeColors();
    updatePreviews();
  }, 50);
}

function toggleCircleMask() {
  const logoElement = globalThis.document.querySelector(
    '.square-logo'
  ) as HTMLElement;
  if (!logoElement) return;

  logoElement.classList.toggle('circle-mask');
}

function downloadAsSVG() {
  const logoElement = globalThis.document.querySelector(
    '.square-logo'
  ) as HTMLElement;
  if (!logoElement) return;

  const width = logoElement.offsetWidth;
  const titleColor = getTitleColor();

  // Use shared SVG generation
  generateSVG(width, titleColor)
    .then((svg) => {
      // Fetch and embed fonts for the download version
      return globalThis
        .fetch(
          'https://fonts.googleapis.com/css2?family=Montserrat:ital,wght@0,800;1,800&display=swap'
        )
        .then((r) => r.text())
        .then((fontCss) => {
          // Add style element with embedded font at the beginning
          const svgNS = 'http://www.w3.org/2000/svg';
          const style = globalThis.document.createElementNS(svgNS, 'style');
          style.textContent = fontCss;
          svg.insertBefore(style, svg.firstChild);
          return svg;
        });
    })
    .then((svg) => {
      // Download
      const svgData = new XMLSerializer().serializeToString(svg);
      const blob = new Blob([svgData], { type: 'image/svg+xml' });
      const url = URL.createObjectURL(blob);

      const a = globalThis.document.createElement('a');
      a.href = url;
      a.download = 'bay-bandits-logo.svg';
      a.click();

      URL.revokeObjectURL(url);
    })
    .catch((error: Error) => {
      globalThis.console.error('Error downloading SVG:', error);
    });
}

function downloadAsPNG() {
  const logoElement = globalThis.document.querySelector(
    '.square-logo'
  ) as HTMLElement;
  if (!logoElement) return;

  const width = logoElement.offsetWidth;
  const titleColor = getTitleColor();
  const scale = 4; // 4x resolution for crisp PNG

  // Use shared PNG generation
  generatePNG(width, titleColor, scale)
    .then((canvas) => {
      // Download
      canvas.toBlob((blob) => {
        if (!blob) return;
        const url = URL.createObjectURL(blob);
        const a = globalThis.document.createElement('a');
        a.href = url;
        a.download = 'bay-bandits-logo.png';
        a.click();
        URL.revokeObjectURL(url);
      });
    })
    .catch((error) => {
      globalThis.console.error('Error downloading PNG:', error);
    });
}

// Get theme color values for banner generation
function getThemeColors() {
  const logoColor = getTitleColor();

  return {
    sky: getBackgroundColor(),
    backHill: getEffectiveColor('backHill'),
    frontHill: logoColor, // Front hill always matches logo/title color
    tree: getEffectiveColor('tree'),
    altTree: getEffectiveColor('altTree'),
    logo: logoColor,
    skyOpacity: backgroundOpacity,
  };
}

// Generate Strava banner as SVG
function generateStravaBannerSVG(): Promise<SVGSVGElement> {
  const svgNS = 'http://www.w3.org/2000/svg';
  const svg = globalThis.document.createElementNS(svgNS, 'svg');

  const width = 1210;
  const height = 593;

  svg.setAttribute('width', width.toString());
  svg.setAttribute('height', height.toString());
  svg.setAttribute('xmlns', svgNS);
  svg.setAttribute('viewBox', `0 0 ${width} ${height}`);

  const colors = getThemeColors();

  // Sky background
  const skyColor = applyOpacityToColor(colors.sky, colors.skyOpacity);
  const skyRect = globalThis.document.createElementNS(svgNS, 'rect');
  skyRect.setAttribute('width', width.toString());
  skyRect.setAttribute('height', height.toString());
  skyRect.setAttribute('fill', skyColor);
  svg.appendChild(skyRect);

  // Calculate hill positioning
  // Hills from homepage use viewBox="0 0 1440 320" - scale proportionally to banner width
  const hillScaleX = width / 1440;
  const hillHeight = 320;

  // CSS shows: back-hill has bottom: 5vh offset for depth
  const backHillOffsetY = height - hillHeight - (height * 0.05) - 75; // 5vh offset + 75px raised
  const frontHillOffsetY = height - hillHeight - 55; // anchored at bottom + 55px raised

  // Back hill path (scaled from index.gts, with 5vh elevation)
  const backHillPath = globalThis.document.createElementNS(svgNS, 'path');
  const backHillD = `
    M 0,${backHillOffsetY + 160}
    L ${120 * hillScaleX},${backHillOffsetY + 176}
    C ${240 * hillScaleX},${backHillOffsetY + 192} ${480 * hillScaleX},${backHillOffsetY + 224} ${720 * hillScaleX},${backHillOffsetY + 224}
    C ${960 * hillScaleX},${backHillOffsetY + 224} ${1200 * hillScaleX},${backHillOffsetY + 192} ${1320 * hillScaleX},${backHillOffsetY + 176}
    L ${1440 * hillScaleX},${backHillOffsetY + 160}
    L ${1440 * hillScaleX},${backHillOffsetY + 320}
    L ${1320 * hillScaleX},${backHillOffsetY + 320}
    C ${1200 * hillScaleX},${backHillOffsetY + 320} ${960 * hillScaleX},${backHillOffsetY + 320} ${720 * hillScaleX},${backHillOffsetY + 320}
    C ${480 * hillScaleX},${backHillOffsetY + 320} ${240 * hillScaleX},${backHillOffsetY + 320} ${120 * hillScaleX},${backHillOffsetY + 320}
    L 0,${backHillOffsetY + 320}
    Z
  `.trim().replace(/\s+/g, ' ');
  backHillPath.setAttribute('d', backHillD);
  backHillPath.setAttribute('fill', colors.backHill);
  svg.appendChild(backHillPath);

  // Front hill path (scaled from index.gts, anchored at bottom)
  const frontHillPath = globalThis.document.createElementNS(svgNS, 'path');
  const frontHillD = `
    M 0,${frontHillOffsetY + 224}
    L ${80 * hillScaleX},${frontHillOffsetY + 213.3}
    C ${160 * hillScaleX},${frontHillOffsetY + 203} ${320 * hillScaleX},${frontHillOffsetY + 181} ${480 * hillScaleX},${frontHillOffsetY + 181.3}
    C ${640 * hillScaleX},${frontHillOffsetY + 181} ${800 * hillScaleX},${frontHillOffsetY + 203} ${960 * hillScaleX},${frontHillOffsetY + 213.3}
    C ${1120 * hillScaleX},${frontHillOffsetY + 224} ${1280 * hillScaleX},${frontHillOffsetY + 224} ${1360 * hillScaleX},${frontHillOffsetY + 224}
    L ${1440 * hillScaleX},${frontHillOffsetY + 224}
    L ${1440 * hillScaleX},${height}
    L 0,${height}
    Z
  `.trim().replace(/\s+/g, ' ');
  frontHillPath.setAttribute('d', frontHillD);
  frontHillPath.setAttribute('fill', colors.frontHill);
  svg.appendChild(frontHillPath);

  // Load tree and chevron SVGs
  return Promise.all([
    globalThis.fetch('/redwood.svg').then(r => r.text()),
    globalThis.fetch('/logo-orange-chevron.svg').then(r => r.text()),
  ]).then(([treeSvgText, chevronSvgText]) => {
    const parser = new DOMParser();

    // Create defs section for reusable elements
    const defs = globalThis.document.createElementNS(svgNS, 'defs');

    // Parse and add tree symbol
    const treeDoc = parser.parseFromString(treeSvgText, 'image/svg+xml');
    const treeSvgEl = treeDoc.documentElement;
    const treeSymbol = globalThis.document.createElementNS(svgNS, 'symbol');
    treeSymbol.setAttribute('id', 'tree');
    treeSymbol.setAttribute('viewBox', treeSvgEl.getAttribute('viewBox') || '0 0 100 100');
    Array.from(treeSvgEl.children).forEach(child => {
      const imported = globalThis.document.importNode(child, true) as SVGElement;
      if (imported instanceof SVGElement) {
        imported.removeAttribute('fill');
      }
      treeSymbol.appendChild(imported);
    });
    defs.appendChild(treeSymbol);

    // Parse and add chevron symbol
    const chevronDoc = parser.parseFromString(chevronSvgText, 'image/svg+xml');
    const chevronSvgEl = chevronDoc.documentElement;
    const chevronSymbol = globalThis.document.createElementNS(svgNS, 'symbol');
    chevronSymbol.setAttribute('id', 'chevron');
    chevronSymbol.setAttribute('viewBox', chevronSvgEl.getAttribute('viewBox') || '0 0 100 100');
    Array.from(chevronSvgEl.children).forEach(child => {
      const imported = globalThis.document.importNode(child, true) as SVGElement;
      if (imported instanceof SVGElement) {
        imported.removeAttribute('fill');
      }
      chevronSymbol.appendChild(imported);
    });
    defs.appendChild(chevronSymbol);

    svg.appendChild(defs);

    // Draw trees - matching homepage CSS positions
    // Base tree dimensions: 20vw wide × 60vh tall
    // For banner: trees should be anchored at bottom and extend up through the scene
    // Further reducing to 40% of height for better proportions
    const baseTreeWidth = width * 0.20; // 20vw
    const baseTreeHeight = height * 0.40; // Scale to 40% of banner height for proper proportions

    const treePositions = [
      // Left trees (anchored at bottom with varied heights)
      { x: width * 0.05, scale: 0.85, flip: false, elevated: false, heightScale: 0.9, color: colors.tree }, // tree-left-0 (left: 5vw)
      { x: 0, scale: 1.0, flip: false, elevated: false, heightScale: 1.1, color: colors.tree }, // tree-left-1 (left: 0)
      { x: width * 0.15, scale: 0.75, flip: false, elevated: false, heightScale: 0.8, color: colors.tree }, // tree-left-2 (left: 15vw)
      { x: width * 0.30, scale: 0.65, flip: false, elevated: false, heightScale: 1.0, color: colors.tree }, // tree-left-3 (left: 30vw)

      // Right trees (flipped horizontally, varied heights and elevations)
      // Note: CSS uses "right: Xvw" which means right edge at X from right, so x = width - X - treeWidth
      { x: width * 0.55, scale: 0.9, flip: true, elevated: true, heightScale: 1.05, color: colors.altTree }, // tree-right-0 (right: 25vw)
      { x: width * 0.63, scale: 0.9, flip: true, elevated: true, heightScale: 1.05, color: colors.altTree }, // tree-right-1 (right: 17vw)
      { x: width * 0.65, scale: 0.8, flip: true, elevated: false, heightScale: 0.85, color: colors.tree }, // tree-right-2 (right: 15vw)
      { x: width * 0.50, scale: 0.75, flip: true, elevated: false, heightScale: 1.15, color: colors.tree }, // tree-right-3 (right: 30vw)
      { x: width * 0.80, scale: 1.0, flip: true, elevated: false, heightScale: 0.95, color: colors.tree }, // tree-right-4 (right: 0)
    ];

    treePositions.forEach(pos => {
      const scaledWidth = baseTreeWidth * pos.scale;
      const scaledHeight = baseTreeHeight * pos.scale * (pos.heightScale || 1.0);
      const elevationOffset = pos.elevated ? height * 0.1 : 0; // 10vh elevation
      const treeY = height - scaledHeight - elevationOffset - 50; // Raised by 50px

      const treeGroup = globalThis.document.createElementNS(svgNS, 'g');

      // Apply flip transform if needed
      if (pos.flip) {
        const centerX = pos.x + scaledWidth / 2;
        treeGroup.setAttribute('transform', `translate(${centerX * 2}, 0) scale(-1, 1)`);
      }

      const useEl = globalThis.document.createElementNS(svgNS, 'use');
      useEl.setAttribute('href', '#tree');
      useEl.setAttribute('x', pos.x.toString());
      useEl.setAttribute('y', treeY.toString());
      useEl.setAttribute('width', scaledWidth.toString());
      useEl.setAttribute('height', scaledHeight.toString());
      useEl.setAttribute('fill', pos.color);

      if (pos.flip) {
        treeGroup.appendChild(useEl);
        svg.appendChild(treeGroup);
      } else {
        svg.appendChild(useEl);
      }
    });

    // Center logo group - moved up to clear trees
    const centerX = width / 2;
    const centerY = height * 0.35; // Move up from center (0.5) to 0.35
    const logoGroup = globalThis.document.createElementNS(svgNS, 'g');

    // Chevron - sized to match the height of the capital letters (reduced by 20%)
    const chevronSize = 40;
    const textY = centerY - 16;

    // Create temp text element to measure width (this is an approximation)
    const tempText = globalThis.document.createElementNS(svgNS, 'text');
    tempText.setAttribute('font-family', 'Montserrat, sans-serif');
    tempText.setAttribute('font-size', '51.2');
    tempText.setAttribute('font-weight', '800');
    tempText.setAttribute('font-style', 'italic');
    tempText.textContent = 'BAY BANDITS';
    svg.appendChild(tempText);
    const textWidth = tempText.getBBox?.()?.width || 360; // fallback adjusted to 360 (450 * 0.8)
    svg.removeChild(tempText);

    // Calculate total width of chevron + margin + text to center them together
    const chevronMargin = 16;
    const totalLogoWidth = chevronSize + chevronMargin + textWidth;
    const logoStartX = centerX - totalLogoWidth / 2;

    const chevronX = logoStartX;
    const chevronY = textY - chevronSize / 2 - 4.8; // Adjusted up by 4.8px (6 * 0.8)

    const chevronUse = globalThis.document.createElementNS(svgNS, 'use');
    chevronUse.setAttribute('href', '#chevron');
    chevronUse.setAttribute('x', chevronX.toString());
    chevronUse.setAttribute('y', chevronY.toString());
    chevronUse.setAttribute('width', chevronSize.toString());
    chevronUse.setAttribute('height', chevronSize.toString());
    chevronUse.setAttribute('fill', colors.logo);
    logoGroup.appendChild(chevronUse);

    // Main text - positioned after chevron
    const textX = logoStartX + chevronSize + chevronMargin;
    const mainText = globalThis.document.createElementNS(svgNS, 'text');
    mainText.setAttribute('x', textX.toString());
    mainText.setAttribute('y', textY.toString());
    mainText.setAttribute('font-family', 'Montserrat, sans-serif');
    mainText.setAttribute('font-size', '51.2');
    mainText.setAttribute('font-weight', '800');
    mainText.setAttribute('font-style', 'italic');
    mainText.setAttribute('fill', colors.logo);
    mainText.setAttribute('text-anchor', 'start');
    mainText.setAttribute('dominant-baseline', 'middle');
    mainText.textContent = 'BAY BANDITS';
    logoGroup.appendChild(mainText);

    // Line separator
    const lineY = textY + 40;
    const lineWidth = textWidth * 0.6;
    const line = globalThis.document.createElementNS(svgNS, 'line');
    line.setAttribute('x1', (centerX - lineWidth / 2).toString());
    line.setAttribute('y1', lineY.toString());
    line.setAttribute('x2', (centerX + lineWidth / 2).toString());
    line.setAttribute('y2', lineY.toString());
    line.setAttribute('stroke', colors.logo);
    line.setAttribute('stroke-width', '2.4');
    logoGroup.appendChild(line);

    // Tagline - centered with adjusted letter spacing to match logo width
    const taglineY = lineY + 32;
    const taglineText = 'Trail Running Community';

    const tagline = globalThis.document.createElementNS(svgNS, 'text');
    tagline.setAttribute('x', centerX.toString());
    tagline.setAttribute('y', taglineY.toString());
    tagline.setAttribute('font-family', 'Montserrat, sans-serif');
    tagline.setAttribute('font-size', '25.6');
    tagline.setAttribute('font-weight', '500');
    tagline.setAttribute('fill', colors.altTree);
    tagline.setAttribute('text-anchor', 'middle');
    tagline.setAttribute('dominant-baseline', 'middle');
    tagline.setAttribute('letter-spacing', '0.15em');
    tagline.textContent = taglineText;
    logoGroup.appendChild(tagline);

    svg.appendChild(logoGroup);

    // Add mobile fold masks if enabled
    if (showBannerMasks) {
      const colorScheme = globalThis.document.body.classList.contains('dark-mode') ? 'dark' : 'light';
      const maskColor = colorScheme === 'dark' ? 'rgba(0, 0, 0, 0.5)' : 'rgba(255, 255, 255, 0.5)';

      // Top mask (100px)
      const topMask = globalThis.document.createElementNS(svgNS, 'rect');
      topMask.setAttribute('width', width.toString());
      topMask.setAttribute('height', '100');
      topMask.setAttribute('y', '0');
      topMask.setAttribute('fill', maskColor);
      svg.appendChild(topMask);

      // Bottom mask (150px)
      const bottomMask = globalThis.document.createElementNS(svgNS, 'rect');
      bottomMask.setAttribute('width', width.toString());
      bottomMask.setAttribute('height', '150');
      bottomMask.setAttribute('y', (height - 150).toString());
      bottomMask.setAttribute('fill', maskColor);
      svg.appendChild(bottomMask);
    }

    return svg;
  });
}

function downloadStravaBannerSVG() {
  generateStravaBannerSVG()
    .then((svg) => {
      // Fetch and embed fonts for the download version
      return globalThis
        .fetch(
          'https://fonts.googleapis.com/css2?family=Montserrat:ital,wght@0,500;0,800;1,800&display=swap'
        )
        .then((r) => r.text())
        .then((fontCss) => {
          // Add style element with embedded font at the beginning
          const svgNS = 'http://www.w3.org/2000/svg';
          const style = globalThis.document.createElementNS(svgNS, 'style');
          style.textContent = fontCss;
          svg.insertBefore(style, svg.firstChild);
          return svg;
        });
    })
    .then((svg) => {
      // Download
      const svgData = new XMLSerializer().serializeToString(svg);
      const blob = new Blob([svgData], { type: 'image/svg+xml' });
      const url = URL.createObjectURL(blob);

      const a = globalThis.document.createElement('a');
      a.href = url;
      a.download = 'bay-bandits-strava-banner.svg';
      a.click();

      URL.revokeObjectURL(url);
    })
    .catch((error: Error) => {
      globalThis.console.error('Error downloading Strava banner:', error);
    });
}

function downloadStravaBannerPNG() {
  const width = 1210;
  const height = 593;

  generateStravaBannerSVG()
    .then((svg) => {
      // Create canvas at exact Strava banner dimensions
      const canvas = globalThis.document.createElement('canvas');
      canvas.width = width;
      canvas.height = height;

      const ctx = canvas.getContext('2d');
      if (!ctx) {
        throw new Error('Cannot get canvas context');
      }

      // Serialize SVG to data URL
      const svgData = new XMLSerializer().serializeToString(svg);
      const svgBlob = new Blob([svgData], { type: 'image/svg+xml;charset=utf-8' });
      const url = URL.createObjectURL(svgBlob);

      // Load SVG as image
      const img = new globalThis.Image();
      img.crossOrigin = 'anonymous';

      return new Promise<HTMLCanvasElement>((resolve, reject) => {
        img.onload = () => {
          // Draw SVG to canvas
          ctx.drawImage(img, 0, 0, width, height);
          URL.revokeObjectURL(url);
          resolve(canvas);
        };

        img.onerror = () => {
          URL.revokeObjectURL(url);
          reject(new Error('Failed to load SVG as image'));
        };

        img.src = url;
      });
    })
    .then((canvas) => {
      // Convert canvas to PNG and download
      canvas.toBlob((blob) => {
        if (!blob) {
          throw new Error('Failed to create PNG blob');
        }

        const url = URL.createObjectURL(blob);
        const a = globalThis.document.createElement('a');
        a.href = url;
        a.download = 'bay-bandits-strava-banner.png';
        a.click();
        URL.revokeObjectURL(url);
      }, 'image/png');
    })
    .catch((error: Error) => {
      globalThis.console.error('Error downloading Strava banner PNG:', error);
    });
}

// Generate preview for Strava banner
function generateStravaBannerPreview() {
  const previewContainer = globalThis.document.getElementById(
    'strava-banner-preview'
  );
  if (!previewContainer) return;

  generateStravaBannerSVG()
    .then((svg) => {
      previewContainer.innerHTML = '';
      previewContainer.appendChild(svg);
    })
    .catch((error: Error) => {
      globalThis.console.error('Error generating Strava banner preview:', error);
      previewContainer.innerHTML = '<p>Error generating preview</p>';
    });
}

<template>
  {{pageTitle "Bandits | The Bay Area Trail Running Community"}}

  <section class="page">
    {{(initializeColorScheme)}}

    <div class="landscape-container">

      <div class="sky branding">
        <div class="logo-container">
          <div
            class="square-logo themeable svg-preview-target"
            role="button"
            aria-roledescription="toggle color scheme"
            {{on "click" toggleColorScheme}}
          ></div>
        </div>

        <div class="preview-section">
          <div class="preview-box">
            <h3>Small Size</h3>
            <div class="preview-container small-logo-preview">
              <div class="svg-preview-target"></div>
            </div>
          </div>
        </div>

        <div class="color-controls" {{initColorPicker}}>
          <div class="color-picker-group">
            <label for="logo-color">Logo Color:</label>
            <input
              type="color"
              id="logo-color"
              class="logo-color-input"
              value="#9333ea"
              {{on "input" handleColorChange}}
            />
          </div>
          <div class="color-picker-group">
            <label for="background-color">Sky Color:</label>
            <input
              type="color"
              id="background-color"
              class="background-color-input"
              value="#f3e8ff"
              {{on "input" handleBackgroundColorChange}}
            />
          </div>
          <div class="color-picker-group">
            <label for="back-hill-color">Back Hill:</label>
            <input
              type="color"
              id="back-hill-color"
              class="back-hill-color-input"
              value="#ff69b4"
              {{on "input" handleBackHillColorChange}}
            />
          </div>
          <div class="color-picker-group">
            <label for="tree-color">Tree Color:</label>
            <input
              type="color"
              id="tree-color"
              class="tree-color-input"
              value="#052c16"
              {{on "input" handleTreeColorChange}}
            />
          </div>
          <div class="color-picker-group">
            <label for="alt-tree-color">Alt Tree:</label>
            <input
              type="color"
              id="alt-tree-color"
              class="alt-tree-color-input"
              value="#06a743"
              {{on "input" handleAltTreeColorChange}}
            />
          </div>
          <div class="opacity-control-group">
            <label for="background-opacity">Sky Opacity:
              <span class="background-opacity-value">100%</span></label>
            <input
              type="range"
              id="background-opacity"
              class="background-opacity-input"
              min="0"
              max="1"
              step="0.01"
              value="1"
              {{on "input" handleBackgroundOpacityChange}}
            />
          </div>
          <div class="opacity-control-group">
            <label for="logo-opacity">Logo Opacity:
              <span class="opacity-value">100%</span></label>
            <input
              type="range"
              id="logo-opacity"
              class="logo-opacity-input"
              min="0"
              max="1"
              step="0.01"
              value="1"
              {{on "input" handleOpacityChange}}
            />
          </div>
          <button
            type="button"
            class="download-btn reset-btn"
            {{on "click" resetColors}}
          >
            Reset Current Theme Colors
          </button>
        </div>

        <h2>Logo Downloads</h2>
        <div class="download-buttons">
          <button
            type="button"
            class="download-btn chevron-only-toggle-btn"
            {{on "click" toggleChevronOnly}}
          >
            Chevron Only: Disabled
          </button>
          <button
            type="button"
            class="download-btn circle-toggle-btn"
            {{on "click" toggleCircleMask}}
          >
            Toggle Circle Mask
          </button>
          <button
            type="button"
            class="download-btn fit-to-content-btn"
            {{on "click" toggleFitToContent}}
          >
            Toggle Fit to Content
          </button>
          <button
            type="button"
            class="download-btn transparent-toggle-btn"
            {{on "click" toggleTransparentBackground}}
          >
            Background: Themed
          </button>
          <button
            type="button"
            class="download-btn"
            {{on "click" downloadAsSVG}}
          >
            Download Logo SVG
          </button>
          <button
            type="button"
            class="download-btn"
            {{on "click" downloadAsPNG}}
          >
            Download Logo PNG
          </button>
        </div>

        <h2>Strava Club Header</h2>
        <div class="strava-banner-section themeable">
          <div class="strava-banner-info">
            <p>Banner dimensions: 1210px × 593px. Top/bottom 100px may be hidden on Desktop.</p>
          </div>
          <div class="strava-banner-preview-container">
            <div id="strava-banner-preview"></div>
          </div>
          <div class="download-buttons">
            <button
              type="button"
              class="download-btn banner-mask-toggle-btn"
              {{on "click" toggleBannerMasks}}
            >
              Safe Area: Hidden
            </button>
            <button
              type="button"
              class="download-btn"
              {{on "click" downloadStravaBannerSVG}}
            >
              Download Strava Banner SVG
            </button>
            <button
              type="button"
              class="download-btn"
              {{on "click" downloadStravaBannerPNG}}
            >
              Download Strava Banner PNG
            </button>
          </div>
        </div>

        {{#if (isDebugMode)}}
          <div class="preview-section themeable">
            <div class="preview-box">
              <h3>SVG Preview</h3>
              <div class="preview-container svg-preview-target"></div>
            </div>
            <div class="preview-box">
              <h3>PNG Preview</h3>
              <div class="preview-container png-preview">
                <canvas id="png-preview"></canvas>
              </div>
            </div>
          </div>
        {{/if}}
      </div>
    </div>
  </section>
</template>
