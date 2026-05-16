import { pageTitle } from 'ember-page-title';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';
import { getTheme } from '@trail-run/core/device/site-theme';
import ThemedPage from '#app/components/layout/themed-page.gts';
import { scopedClass } from 'ember-scoped-css';

const SiteManifest = {
  "name": "The Bay Bandits",
  "short_name": "Bandits",
  "icons": [],
  "theme_color": "#ffffff",
  "background_color": "#ffffff",
  "display": "standalone"
};

let useTransparentBackground = false;

// Sky image state
let skyImageData: string | null = null; // base64 encoded image
let skyImageScale = 1; // scale factor for image
let skyImageOffsetX = 0; // horizontal offset in pixels
let skyImageOffsetY = 0; // vertical offset in pixels

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
  return document.body.classList.contains('dark-mode') ? darkModeColors : lightModeColors;
}

// Helper to get current mode's default colors
function getCurrentModeDefaults() {
  return document.body.classList.contains('dark-mode') ? darkThemeDefaultColors : lightThemeDefaultColors;
}

// Initialize defaults from CSS if not already set
function initializeDefaults() {
  const defaults = getCurrentModeDefaults();

  if (defaults.logo === null) {
    const body = document.body;
    const themeColor = getComputedStyle(body).getPropertyValue('--title').trim();
    const titleElement = document.querySelector('h1.title') as HTMLElement;
    const fallbackColor = titleElement
      ? getComputedStyle(titleElement).getPropertyValue('color')
      : '';

    const computedColor = themeColor || fallbackColor || '#9333ea';
    defaults.logo = rgbToHex(computedColor);
  }

  if (defaults.background === null) {
    const body = document.body;
    const computedBg = getComputedStyle(body).getPropertyValue('--bg-sky').trim();
    defaults.background = rgbToHex(computedBg || '#f3e8ff');
  }

  if (defaults.backHill === null) {
    const body = document.body;
    const computed = getComputedStyle(body).getPropertyValue('--color-hill-back').trim();
    defaults.backHill = rgbToHex(computed || '#ff69b4');
  }

  if (defaults.tree === null) {
    const body = document.body;
    const computed = getComputedStyle(body).getPropertyValue('--tree-color').trim();
    defaults.tree = rgbToHex(computed || '#052c16');
  }

  if (defaults.altTree === null) {
    const body = document.body;
    const computed = getComputedStyle(body).getPropertyValue('--alt-tree-color').trim();
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
    document.querySelectorAll('.themeable')
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
  const label = document.querySelector(
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

  const label = document.querySelector(
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
  const opacityLabel = document.querySelector('.opacity-value') as HTMLElement;
  const backgroundOpacityLabel = document.querySelector('.background-opacity-value') as HTMLElement;
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

function getEffectiveColorForTheme(
  colorKey: 'logo' | 'background' | 'backHill' | 'tree' | 'altTree',
  theme: 'light' | 'dark'
): string {
  const modeColors = theme === 'dark' ? darkModeColors : lightModeColors;
  const defaults = theme === 'dark' ? darkThemeDefaultColors : lightThemeDefaultColors;
  return modeColors[colorKey] || defaults[colorKey] || '#000000';
}

function getColorsForTheme(theme: 'light' | 'dark') {
  const logo = applyOpacityToColor(getEffectiveColorForTheme('logo', theme), logoOpacity);
  const background = applyOpacityToColor(getEffectiveColorForTheme('background', theme), backgroundOpacity);
  const backHill = getEffectiveColorForTheme('backHill', theme);
  const tree = getEffectiveColorForTheme('tree', theme);
  const altTree = getEffectiveColorForTheme('altTree', theme);
  return {
    sky: background,
    backHill,
    frontHill: logo,
    tree,
    altTree,
    logo,
    skyOpacity: backgroundOpacity,
  };
}

// Initialize color pickers to show effective colors (overrides or defaults)
function initializeColorPickers() {
  const colorInput = document.querySelector('.logo-color-input') as HTMLInputElement;
  const backgroundInput = document.querySelector('.background-color-input') as HTMLInputElement;
  const backHillInput = document.querySelector('.back-hill-color-input') as HTMLInputElement;
  const treeInput = document.querySelector('.tree-color-input') as HTMLInputElement;
  const altTreeInput = document.querySelector('.alt-tree-color-input') as HTMLInputElement;
  const opacityInput = document.querySelector('.logo-opacity-input') as HTMLInputElement;
  const backgroundOpacityInput = document.querySelector('.background-opacity-input') as HTMLInputElement;

  if (colorInput) colorInput.value = getEffectiveColor('logo');
  if (backgroundInput) backgroundInput.value = getEffectiveColor('background');
  if (backHillInput) backHillInput.value = getEffectiveColor('backHill');
  if (treeInput) treeInput.value = getEffectiveColor('tree');
  if (altTreeInput) altTreeInput.value = getEffectiveColor('altTree');
  if (opacityInput) opacityInput.value = logoOpacity.toString();
  if (backgroundOpacityInput) backgroundOpacityInput.value = backgroundOpacity.toString();
}

const initColorPicker = modifier(() => {
  async function setup() {
    await new Promise((r) => setTimeout(r, 100));

    const theme = getTheme();
    const isDark = document.body.classList.contains('dark-mode');

    // Initialize defaults for the current theme
    initializeDefaults();

    // Briefly switch to the other theme to capture its CSS variable defaults
    theme.updateThemePreference(isDark ? 'light' : 'dark');
    await new Promise((r) => setTimeout(r, 60));
    initializeDefaults();

    // Switch back
    theme.updateThemePreference(isDark ? 'dark' : 'light');
    await new Promise((r) => setTimeout(r, 60));

    initializeColorPickers();
    updateThemeColors();
    updatePreviews();
  }

  setup().catch(console.error);
});

function isDebugMode(): boolean {
  const hash = location.hash;
  const queryStart = hash.indexOf('?');
  if (queryStart === -1) return false;

  const queryString = hash.substring(queryStart + 1);
  const urlParams = new URLSearchParams(queryString);
  return urlParams.get('debug') === 'true';
}

// Sky image handlers
function handleSkyImageUpload(event: Event) {
  const input = event.target as HTMLInputElement;
  const file = input.files?.[0];

  if (!file) return;

  const reader = new FileReader();
  reader.onload = (e) => {
    skyImageData = e.target?.result as string;
    skyImageScale = 1;
    skyImageOffsetX = 0;
    skyImageOffsetY = 0;

    // Show controls
    const controls = document.getElementById('sky-image-controls');
    if (controls) {
      controls.classList.remove('hidden');
    }

    updatePreviews();
  };
  reader.readAsDataURL(file);
}

function clearSkyImage() {
  skyImageData = null;
  skyImageScale = 1;
  skyImageOffsetX = 0;
  skyImageOffsetY = 0;

  const input = document.querySelector('.sky-image-input') as HTMLInputElement;
  if (input) input.value = '';

  // Hide controls
  const controls = document.getElementById('sky-image-controls');
  if (controls) {
    controls.classList.add('hidden');
  }

  updatePreviews();
}

function handleSkyImageScale(event: Event) {
  const input = event.target as HTMLInputElement;
  skyImageScale = parseFloat(input.value);

  const valueLabel = document.querySelector('.sky-image-scale-value');
  if (valueLabel) {
    valueLabel.textContent = skyImageScale.toFixed(1);
  }

  updatePreviews();
}

function handleSkyImageOffsetX(event: Event) {
  const input = event.target as HTMLInputElement;
  skyImageOffsetX = parseFloat(input.value);

  const valueLabel = document.querySelector('.sky-image-offset-x-value');
  if (valueLabel) {
    valueLabel.textContent = skyImageOffsetX.toString();
  }

  updatePreviews();
}

function handleSkyImageOffsetY(event: Event) {
  const input = event.target as HTMLInputElement;
  skyImageOffsetY = parseFloat(input.value);

  const valueLabel = document.querySelector('.sky-image-offset-y-value');
  if (valueLabel) {
    valueLabel.textContent = skyImageOffsetY.toString();
  }

  updatePreviews();
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
function calculateLogoDimensions(size: number, opts: { fitToContent?: boolean; singleLine?: boolean } = {}) {
  const fc = opts.fitToContent ?? fitToContent;
  const sl = opts.singleLine ?? false;

  if (sl) {
    // Single-line horizontal layout matching banner proportions:
    // banner uses chevronSize=40, fontSize=51.2 → ratio ≈ 0.781
    const fontSize = size;
    const chevronSize = Math.round(size * (40 / 51.2)); // ~78% of fontSize, banner ratio
    const chevronMargin = Math.round(chevronSize / 11);  // matches two-line ratio (1/11 of chevronSize)
    const iconOffsetY = (size - chevronSize) / 2;        // center chevron vertically
    // Initial estimate; actual width measured via getBBox in generateSVG to prevent clipping
    const textWidthEstimate = fontSize * 7.5;
    const boxHeight = size;
    const boxWidth = chevronSize + chevronMargin + textWidthEstimate;
    return {
      boxWidth,
      boxHeight,
      chevronSize,
      chevronMargin,
      fontSize,
      lineHeight: size,
      iconOffsetY,
      totalHeight: size,
      offsetX: 0,
      offsetY: 0,
    };
  }

  const padding = fc ? 0 : 6;
  const sizeFactor = fc ? 38 : 50;
  const leftMargin = size * (padding / sizeFactor);

  const chevronSize = (size * 11) / sizeFactor;
  const chevronMargin = (size * 1) / sizeFactor;
  const fontSize = (size * 5) / sizeFactor;
  const lineHeight = (size * 6) / sizeFactor;
  const iconOffsetY = (lineHeight * 2 - chevronSize) / 2;

  const totalHeight = 2 * lineHeight;

  const offsetX = leftMargin;
  const offsetY = fc ? 0 : (size - totalHeight) / 2;
  const boxWidth = size;
  const boxHeight = fc ? totalHeight : size;

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

function appendPreviewActions(el: HTMLElement) {
  const actions = document.createElement('div');
  actions.className = 'preview-cell-actions';

  const svgBtn = document.createElement('button');
  svgBtn.className = 'preview-dl-btn';
  svgBtn.textContent = 'SVG';
  svgBtn.addEventListener('click', (e) => { e.stopPropagation(); downloadPreviewEl(el, 'svg'); });

  const pngBtn = document.createElement('button');
  pngBtn.className = 'preview-dl-btn';
  pngBtn.textContent = 'PNG';
  pngBtn.addEventListener('click', (e) => { e.stopPropagation(); downloadPreviewEl(el, 'png'); });

  actions.appendChild(svgBtn);
  actions.appendChild(pngBtn);
  el.appendChild(actions);
}

async function downloadPreviewEl(el: HTMLElement, format: 'svg' | 'png') {
  const theme = (el.getAttribute('data-theme') ?? 'light') as 'light' | 'dark';
  const previewType = el.getAttribute('data-preview');
  const isTransparent = el.getAttribute('data-transparent') === 'true';
  const isInverted = el.getAttribute('data-inverted') === 'true';
  const colors = getColorsForTheme(theme);
  const logoColor = isInverted ? colors.sky : colors.logo;
  const bgColor = isInverted ? colors.logo : colors.sky;
  const nameParts = ['bay-bandits'];

  let svg: SVGSVGElement;

  if (previewType === 'logo') {
    const size = parseInt(el.getAttribute('data-size') ?? '250');
    const isChevronOnly = el.getAttribute('data-chevron-only') === 'true';
    const isFitToContent = el.getAttribute('data-fit-to-content') === 'true';
    const isSingleLine = el.getAttribute('data-single-line') === 'true';
    if (isChevronOnly) nameParts.push('chevron');
    else if (isSingleLine) nameParts.push('logo-single');
    else if (isFitToContent) nameParts.push('logo-fit');
    else nameParts.push('logo');
    nameParts.push(`${size}px`, theme);
    if (isInverted) nameParts.push('inverted');
    if (isTransparent) nameParts.push('transparent');
    svg = await generateSVG(size, logoColor, {
      chevronOnly: isChevronOnly, fitToContent: isFitToContent,
      singleLine: isSingleLine, backgroundColor: bgColor, transparent: isTransparent,
    });
  } else if (previewType === 'banner') {
    const noText = el.getAttribute('data-no-text') === 'true';
    const noTrees = el.getAttribute('data-no-trees') === 'true';
    nameParts.push('banner');
    if (noTrees) nameParts.push('minimal');
    else if (noText) nameParts.push('no-text');
    nameParts.push(theme);
    svg = await generateStravaBannerSVG({ noText, noTrees, colors });
  } else {
    return;
  }

  const filename = nameParts.join('-');

  if (format === 'svg') {
    const svgStr = new XMLSerializer().serializeToString(svg);
    const blob = new Blob([svgStr], { type: 'image/svg+xml' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${filename}.svg`;
    a.click();
    URL.revokeObjectURL(url);
  } else {
    const vb = (svg.getAttribute('viewBox') ?? '').split(' ');
    const vbW = parseFloat(vb[2] ?? '300');
    const vbH = parseFloat(vb[3] ?? '300');
    const svgStr = new XMLSerializer().serializeToString(svg);
    const svgBlob = new Blob([svgStr], { type: 'image/svg+xml' });
    const svgUrl = URL.createObjectURL(svgBlob);
    const img = new Image();
    img.onload = () => {
      const canvas = document.createElement('canvas');
      canvas.width = Math.round(vbW * 2);
      canvas.height = Math.round(vbH * 2);
      const ctx = canvas.getContext('2d');
      if (!ctx) { URL.revokeObjectURL(svgUrl); return; }
      ctx.scale(2, 2);
      ctx.drawImage(img, 0, 0, vbW, vbH);
      URL.revokeObjectURL(svgUrl);
      canvas.toBlob((pngBlob) => {
        if (!pngBlob) return;
        const pngUrl = URL.createObjectURL(pngBlob);
        const a = document.createElement('a');
        a.href = pngUrl;
        a.download = `${filename}.png`;
        a.click();
        URL.revokeObjectURL(pngUrl);
      }, 'image/png');
    };
    img.onerror = () => URL.revokeObjectURL(svgUrl);
    img.src = svgUrl;
  }
}

function updatePreviews() {
  // Logo previews — driven by data attributes on each container
  (Array.from(document.querySelectorAll('[data-preview="logo"]')) as HTMLElement[]).forEach((el) => {
    const theme = (el.getAttribute('data-theme') ?? 'light') as 'light' | 'dark';
    const size = parseInt(el.getAttribute('data-size') ?? '250');
    const displayHeight = el.getAttribute('data-display-height') ? parseInt(el.getAttribute('data-display-height')!) : null;
    const isChevronOnly = el.getAttribute('data-chevron-only') === 'true';
    const isFitToContent = el.getAttribute('data-fit-to-content') === 'true';
    const isSingleLine = el.getAttribute('data-single-line') === 'true';
    const isTransparent = el.getAttribute('data-transparent') === 'true';
    const isInverted = el.getAttribute('data-inverted') === 'true';

    const colors = getColorsForTheme(theme);
    const logoColor = isInverted ? colors.sky : colors.logo;
    const bgColor = isInverted ? colors.logo : colors.sky;
    generateSVG(size, logoColor, {
      chevronOnly: isChevronOnly,
      fitToContent: isFitToContent,
      singleLine: isSingleLine,
      backgroundColor: bgColor,
      transparent: isTransparent,
    }).then((svg) => {
      const vb = (svg.getAttribute('viewBox') ?? '').split(' ');
      const vbW = parseFloat(vb[2] ?? size.toString());
      const vbH = parseFloat(vb[3] ?? size.toString());
      if (displayHeight && Math.abs(displayHeight - vbH) > 1) {
        const scale = displayHeight / vbH;
        svg.setAttribute('width', Math.round(vbW * scale).toString());
        svg.setAttribute('height', displayHeight.toString());
      } else {
        svg.setAttribute('width', Math.round(vbW).toString());
        svg.setAttribute('height', Math.round(vbH).toString());
      }
      el.innerHTML = '';
      el.appendChild(svg);
      appendPreviewActions(el);
    }).catch(() => {
      el.innerHTML = '<p style="font-size:10px">Error</p>';
    });
  });

  // Banner previews — driven by data attributes on each container
  (Array.from(document.querySelectorAll('[data-preview="banner"]')) as HTMLElement[]).forEach((el) => {
    const theme = (el.getAttribute('data-theme') ?? 'light') as 'light' | 'dark';
    const noText = el.getAttribute('data-no-text') === 'true';
    const noTrees = el.getAttribute('data-no-trees') === 'true';
    const colors = getColorsForTheme(theme);
    generateStravaBannerSVG({ noText, noTrees, colors }).then((svg) => {
      el.innerHTML = '';
      el.appendChild(svg);
      appendPreviewActions(el);
    }).catch(() => {
      el.innerHTML = '<p>Error generating banner</p>';
    });
  });
}

// Generate SVG - shared by both preview and download
function generateSVG(
  size: number,
  titleColor: string,
  svgOptions: {
    chevronOnly?: boolean;
    fitToContent?: boolean;
    singleLine?: boolean;
    backgroundColor?: string;
    transparent?: boolean;
  } = {}
): Promise<SVGSVGElement> {
  const svgNS = 'http://www.w3.org/2000/svg';
  const svg = document.createElementNS(svgNS, 'svg');

  const isChevronOnly = svgOptions.chevronOnly ?? chevronOnly;
  const isFitToContent = svgOptions.fitToContent ?? fitToContent;
  const isSingleLine = svgOptions.singleLine ?? false;
  const isTransparent = svgOptions.transparent ?? useTransparentBackground;
  const bgColor = svgOptions.backgroundColor ?? getBackgroundColor();

  // Chevron-only mode: square box with centred chevron
  if (isChevronOnly) {
    const chevronSize = size * 0.75;
    const boxWidth = size;
    const boxHeight = size;

    svg.setAttribute('xmlns', svgNS);
    svg.setAttribute('viewBox', `0 0 ${boxWidth} ${boxHeight}`);

    const rect = document.createElementNS(svgNS, 'rect');
    rect.setAttribute('width', boxWidth.toString());
    rect.setAttribute('height', boxHeight.toString());
    rect.setAttribute('fill', isTransparent ? 'none' : bgColor);
    svg.appendChild(rect);

    return globalThis
      .fetch('/logo-orange-chevron.svg')
      .then((response) => response.text())
      .then((chevronSvgText) => {
        const parser = new DOMParser();
        const chevronDoc = parser.parseFromString(chevronSvgText, 'image/svg+xml');
        const chevronSvgEl = chevronDoc.documentElement;

        const defs = document.createElementNS(svgNS, 'defs');
        const symbol = document.createElementNS(svgNS, 'symbol');
        symbol.setAttribute('id', `chevron-${Date.now()}`);
        symbol.setAttribute('viewBox', chevronSvgEl.getAttribute('viewBox') || '0 0 100 100');

        Array.from(chevronSvgEl.children).forEach((child) => {
          const importedChild = document.importNode(child, true) as SVGElement;
          if (importedChild instanceof SVGElement) {
            importedChild.removeAttribute('fill');
            importedChild.setAttribute('fill', titleColor);
          }
          symbol.appendChild(importedChild);
        });

        defs.appendChild(symbol);
        svg.appendChild(defs);

        const chevronX = (boxWidth - chevronSize) / 2;
        const chevronY = (boxHeight - chevronSize) / 2;

        const useEl = document.createElementNS(svgNS, 'use');
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

  // Full logo: chevron + text (single-line or two-line)
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
  } = calculateLogoDimensions(size, { fitToContent: isFitToContent, singleLine: isSingleLine });

  svg.setAttribute('xmlns', svgNS);
  svg.setAttribute('viewBox', `0 0 ${boxWidth} ${boxHeight}`);

  const rect = document.createElementNS(svgNS, 'rect');
  rect.setAttribute('width', boxWidth.toString());
  rect.setAttribute('height', boxHeight.toString());
  rect.setAttribute('fill', isTransparent ? 'none' : bgColor);
  svg.appendChild(rect);

  return globalThis
    .fetch('/logo-orange-chevron.svg')
    .then((response) => response.text())
    .then((chevronSvgText) => {
      const parser = new DOMParser();
      const chevronDoc = parser.parseFromString(chevronSvgText, 'image/svg+xml');
      const chevronSvgEl = chevronDoc.documentElement;

      const defs = document.createElementNS(svgNS, 'defs');
      const symbol = document.createElementNS(svgNS, 'symbol');
      symbol.setAttribute('id', `chevron-${Date.now()}`);
      symbol.setAttribute('viewBox', chevronSvgEl.getAttribute('viewBox') || '0 0 100 100');

      Array.from(chevronSvgEl.children).forEach((child) => {
        const importedChild = document.importNode(child, true) as SVGElement;
        if (importedChild instanceof SVGElement) {
          importedChild.removeAttribute('fill');
          importedChild.setAttribute('fill', titleColor);
        }
        symbol.appendChild(importedChild);
      });

      defs.appendChild(symbol);
      svg.appendChild(defs);

      const g = document.createElementNS(svgNS, 'g');
      g.setAttribute('transform', `translate(${offsetX}, ${offsetY})`);

      const useEl = document.createElementNS(svgNS, 'use');
      useEl.setAttribute('href', `#${symbol.id}`);
      useEl.setAttribute('x', '0');
      useEl.setAttribute('y', iconOffsetY.toString());
      useEl.setAttribute('width', chevronSize.toString());
      useEl.setAttribute('height', chevronSize.toString());
      useEl.setAttribute('fill', titleColor);
      g.appendChild(useEl);

      if (isSingleLine) {
        // Single line: "BAY BANDITS" vertically centred on the chevron
        const text = document.createElementNS(svgNS, 'text');
        text.setAttribute('x', (chevronSize + chevronMargin).toString());
        // dominant-baseline='middle' centers the em box; cap height center is ~9.4% of fontSize
        // above the em-box center (banner empirical: 4.8px at fontSize 51.2). Shift y down
        // by that ratio so visual caps align with the vertically-centered chevron.
        text.setAttribute('y', (boxHeight / 2 + fontSize * (4.8 / 51.2)).toString());
        text.setAttribute('font-family', 'Montserrat, sans-serif');
        text.setAttribute('font-size', fontSize.toString());
        text.setAttribute('font-weight', '800');
        text.setAttribute('font-style', 'italic');
        text.setAttribute('fill', titleColor);
        text.setAttribute('dominant-baseline', 'middle');
        text.textContent = 'BAY BANDITS';
        g.appendChild(text);
        svg.appendChild(g);

        // getBBox requires the element to be in the document; attach temporarily to measure
        const tempDiv = document.createElement('div');
        tempDiv.style.cssText = 'position:fixed;top:-9999px;left:-9999px;visibility:hidden;pointer-events:none;';
        document.body.appendChild(tempDiv);
        tempDiv.appendChild(svg);
        const measuredTextWidth = (text as SVGTextElement).getBBox?.()?.width ?? (fontSize * 7.5);
        document.body.removeChild(tempDiv); // detaches svg from DOM; svg object still usable

        const actualBoxWidth = chevronSize + chevronMargin + measuredTextWidth + chevronMargin;
        svg.setAttribute('viewBox', `0 0 ${actualBoxWidth} ${boxHeight}`);
        rect.setAttribute('width', actualBoxWidth.toString());
      } else {
        // Two lines: "BAY" over "BANDITS"
        const text1 = document.createElementNS(svgNS, 'text');
        text1.setAttribute('x', (chevronSize + chevronMargin).toString());
        text1.setAttribute('y', fontSize.toString());
        text1.setAttribute('font-family', 'Montserrat, sans-serif');
        text1.setAttribute('font-size', fontSize.toString());
        text1.setAttribute('font-weight', '800');
        text1.setAttribute('font-style', 'italic');
        text1.setAttribute('fill', titleColor);
        text1.textContent = 'BAY';
        g.appendChild(text1);

        const text2 = document.createElementNS(svgNS, 'text');
        text2.setAttribute('x', (chevronSize + chevronMargin).toString());
        text2.setAttribute('y', (fontSize + lineHeight).toString());
        text2.setAttribute('font-family', 'Montserrat, sans-serif');
        text2.setAttribute('font-size', fontSize.toString());
        text2.setAttribute('font-weight', '800');
        text2.setAttribute('font-style', 'italic');
        text2.setAttribute('fill', titleColor);
        text2.textContent = 'BANDITS';
        g.appendChild(text2);
      }

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
  const canvas = document.createElement('canvas');
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
    const img = new Image();
    img.crossOrigin = 'anonymous';

    return new Promise((resolve) => {
      img.onload = () => {
        // eslint-disable-next-line warp-drive/no-legacy-request-patterns
        ctx.save();
        ctx.globalCompositeOperation = 'source-over';

        // Create a temporary canvas for the colored chevron
        const tempCanvas = document.createElement('canvas');
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
  const img = new Image();
  img.crossOrigin = 'anonymous';

  return Promise.all([
    document.fonts.load('italic 800 30px Montserrat'),
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
    const tempCanvas = document.createElement('canvas');
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

function toggleTransparentBackground() {
  useTransparentBackground = !useTransparentBackground;

  const button = document.querySelector('.transparent-toggle-btn') as HTMLButtonElement;
  if (button) {
    button.textContent = useTransparentBackground
      ? 'Background: Transparent ✓'
      : 'Background: Themed';
  }

  updateThemeColors();
  updatePreviews();
}

let fitToContent = false;
function toggleFitToContent() {
  fitToContent = !fitToContent;
  updatePreviews();
}

let chevronOnly = false;
function toggleChevronOnly() {
  chevronOnly = !chevronOnly;

  const button = document.querySelector(
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
  const label = showBannerMasks ? 'Safe Area: Visible ✓' : 'Safe Area: Hidden';
  document.querySelectorAll('.banner-mask-toggle-btn').forEach((btn) => {
    (btn as HTMLButtonElement).textContent = label;
  });
  updatePreviews();
}

function toggleColorScheme() {
  const theme = getTheme();
  theme.updateThemePreference(theme.isDarkMode ? 'light' : 'dark');
  // Update previews and color pickers after theme change to recalculate colors
  setTimeout(() => {
    // Initialize defaults for the new mode if needed
    initializeDefaults();

    // Update color pickers to show effective colors for new mode
    initializeColorPickers();

    // Reapply theme colors
    updateThemeColors();
    updatePreviews();
  }, 0);
}

function downloadAsSVG() {
  const width = 300;
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
          const style = document.createElementNS(svgNS, 'style');
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

      const a = document.createElement('a');
      a.href = url;
      a.download = 'bay-bandits-logo.svg';
      a.click();

      URL.revokeObjectURL(url);
    })
    .catch((error: Error) => {
      console.error('Error downloading SVG:', error);
    });
}

function downloadAsPNG() {
  const width = 300;
  const titleColor = getTitleColor();
  const scale = 4; // 4x resolution for crisp PNG

  // Use shared PNG generation
  generatePNG(width, titleColor, scale)
    .then((canvas) => {
      // Download
      canvas.toBlob((blob) => {
        if (!blob) return;
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'bay-bandits-logo.png';
        a.click();
        URL.revokeObjectURL(url);
      });
    })
    .catch((error) => {
      console.error('Error downloading PNG:', error);
    });
}

function downloadAssetsAsZip() {
  // Store current theme state and chevron mode
  const currentTheme = document.body.classList.contains('dark-mode') ? 'dark' : 'light';
  const currentChevronOnly = chevronOnly;

  // Define all asset configurations for each theme
  const themeAssetConfigs = [
    // Site icons (required sizes) - with text
    { name: 'favicon-32x32.png', size: 32, isFavicon: true, chevronOnly: false, invertColors: false },
    { name: 'favicon.ico', size: 32, isIco: true, chevronOnly: false, invertColors: false },
    { name: 'apple-touch-icon-180x180.png', size: 180, chevronOnly: false, invertColors: false },
    { name: 'android-chrome-192x192.png', size: 192, chevronOnly: false, invertColors: false },
    { name: 'android-chrome-512x512.png', size: 512, chevronOnly: false, invertColors: false },

    // Site icons (required sizes) - with text, inverted colors
    { name: 'favicon-32x32-inverted.png', size: 32, isFavicon: true, chevronOnly: false, invertColors: true },
    { name: 'favicon-inverted.ico', size: 32, isIco: true, chevronOnly: false, invertColors: true },
    { name: 'apple-touch-icon-180x180-inverted.png', size: 180, chevronOnly: false, invertColors: true },
    { name: 'android-chrome-192x192-inverted.png', size: 192, chevronOnly: false, invertColors: true },
    { name: 'android-chrome-512x512-inverted.png', size: 512, chevronOnly: false, invertColors: true },

    // Site icons (required sizes) - chevron only
    { name: 'favicon-32x32-chevron.png', size: 32, isFavicon: true, chevronOnly: true, invertColors: false },
    { name: 'favicon-chevron.ico', size: 32, isIco: true, chevronOnly: true, invertColors: false },
    { name: 'apple-touch-icon-180x180-chevron.png', size: 180, chevronOnly: true, invertColors: false },
    { name: 'android-chrome-192x192-chevron.png', size: 192, chevronOnly: true, invertColors: false },
    { name: 'android-chrome-512x512-chevron.png', size: 512, chevronOnly: true, invertColors: false },

    // Site icons (required sizes) - chevron only, inverted colors
    { name: 'favicon-32x32-chevron-inverted.png', size: 32, isFavicon: true, chevronOnly: true, invertColors: true },
    { name: 'favicon-chevron-inverted.ico', size: 32, isIco: true, chevronOnly: true, invertColors: true },
    { name: 'apple-touch-icon-180x180-chevron-inverted.png', size: 180, chevronOnly: true, invertColors: true },
    { name: 'android-chrome-192x192-chevron-inverted.png', size: 192, chevronOnly: true, invertColors: true },
    { name: 'android-chrome-512x512-chevron-inverted.png', size: 512, chevronOnly: true, invertColors: true },

    // SVG logos - both variants
    { name: 'logo.svg', isVector: true, chevronOnly: false, invertColors: false },
    { name: 'logo-inverted.svg', isVector: true, chevronOnly: false, invertColors: true },
    { name: 'logo-chevron.svg', isVector: true, chevronOnly: true, invertColors: false },
    { name: 'logo-chevron-inverted.svg', isVector: true, chevronOnly: true, invertColors: true },

    // Social media previews - logo based (with text)
    { name: 'og-logo-600x600.png', size: 600, scale: 2, chevronOnly: false, invertColors: false },
    { name: 'og-logo-600x600-inverted.png', size: 600, scale: 2, chevronOnly: false, invertColors: true },

    // Social media previews - logo based (chevron only)
    { name: 'og-logo-600x600-chevron.png', size: 600, scale: 2, chevronOnly: true, invertColors: false },
    { name: 'og-logo-600x600-chevron-inverted.png', size: 600, scale: 2, chevronOnly: true, invertColors: true },
  ];

  const bannerAssetConfigs = [
    // Social media previews - banner based (PNG)
    { name: 'og-banner-1200x630.png', isBanner: true, width: 1200, height: 630 },
    { name: 'og-banner-1210x593.png', isBanner: true, width: 1210, height: 593 },
  ];

  const bannerSvgConfigs = [
    // Banner SVGs for each theme
    { name: 'og-banner-1210x593.svg', isBannerSvg: true },
  ];

  const adaptiveSvgConfigs = [
    // Adaptive SVGs that switch between light/dark theme automatically
    { name: 'logo-adaptive.svg', chevronOnly: false, invertColors: false, isBannerSvg: false },
    { name: 'logo-adaptive-inverted.svg', chevronOnly: false, invertColors: true, isBannerSvg: false },
    { name: 'logo-chevron-adaptive.svg', chevronOnly: true, invertColors: false, isBannerSvg: false },
    { name: 'logo-chevron-adaptive-inverted.svg', chevronOnly: true, invertColors: true, isBannerSvg: false },
    { name: 'og-banner-adaptive.svg', isBannerSvg: true },
  ];

  const assets: { [key: string]: Blob } = {};

  // Helper to get theme-specific folder name
  const getThemeFolder = (isDark: boolean) => isDark ? 'dark' : 'light';

  // Function to switch theme
  const switchTheme = (targetTheme: 'light' | 'dark', callback: () => void) => {
    const isDark = document.body.classList.contains('dark-mode');
    const needsSwitch = (targetTheme === 'dark' && !isDark) || (targetTheme === 'light' && isDark);

    if (needsSwitch) {
      toggleColorScheme();
      setTimeout(callback, 100);
    } else {
      callback();
    }
  };

  // Helper function to convert PNG canvas to ICO format
  const canvasToIco = (canvas: HTMLCanvasElement): Promise<Blob> => {
    return new Promise((resolve, reject) => {
      canvas.toBlob((pngBlob) => {
        if (!pngBlob) {
          reject(new Error('Failed to create PNG blob'));
          return;
        }

        // Read the PNG data
        const reader = new FileReader();
        reader.onload = () => {
          const pngData = new Uint8Array(reader.result as ArrayBuffer);

          // Create ICO header (6 bytes) + image directory (16 bytes)
          const icoHeader = new Uint8Array(6 + 16 + pngData.length);

          // ICO header
          icoHeader[0] = 0; // Reserved
          icoHeader[1] = 0;
          icoHeader[2] = 1; // Type: 1 = ICO
          icoHeader[3] = 0;
          icoHeader[4] = 1; // Number of images
          icoHeader[5] = 0;

          // Image directory entry
          icoHeader[6] = 32; // Width (0 = 256)
          icoHeader[7] = 32; // Height (0 = 256)
          icoHeader[8] = 0;  // Color palette
          icoHeader[9] = 0;  // Reserved
          icoHeader[10] = 1; // Color planes
          icoHeader[11] = 0;
          icoHeader[12] = 32; // Bits per pixel
          icoHeader[13] = 0;

          // Image size (little-endian)
          const imageSize = pngData.length;
          icoHeader[14] = imageSize & 0xFF;
          icoHeader[15] = (imageSize >> 8) & 0xFF;
          icoHeader[16] = (imageSize >> 16) & 0xFF;
          icoHeader[17] = (imageSize >> 24) & 0xFF;

          // Image offset (little-endian) - after header and directory
          icoHeader[18] = 22; // 6 + 16
          icoHeader[19] = 0;
          icoHeader[20] = 0;
          icoHeader[21] = 0;

          // Copy PNG data after header
          icoHeader.set(pngData, 22);

          const icoBlob = new Blob([icoHeader], { type: 'image/x-icon' });
          resolve(icoBlob);
        };
        reader.onerror = () => reject(new Error('Failed to read PNG data'));
        reader.readAsArrayBuffer(pngBlob);
      }, 'image/png');
    });
  };

  // Helper to swap logo and background colors in current mode
  const swapLogoAndBackgroundColors = () => {
    const modeColors = getCurrentModeColors();

    // Store original values
    const originalLogo = modeColors.logo;
    const originalBg = modeColors.background;

    // Get current effective colors (including defaults if needed)
    const defaults = getCurrentModeDefaults();
    const effectiveLogo = originalLogo || defaults.logo;
    const effectiveBg = originalBg || defaults.background;

    // Swap them in the mode colors
    modeColors.logo = effectiveBg;
    modeColors.background = effectiveLogo;

    // Return a function to restore original values
    return () => {
      modeColors.logo = originalLogo;
      modeColors.background = originalBg;
    };
  };

  // Helper to generate adaptive SVG with prefers-color-scheme
  const generateAdaptiveSVG = async (
    isBanner: boolean,
    _chevronOnly: boolean = false,
    invertColors: boolean = false
  ): Promise<SVGElement> => {
    // Get colors for both themes
    const originalTheme = document.body.classList.contains('dark-mode') ? 'dark' : 'light';

    // Generate light theme SVG
    if (originalTheme === 'dark') {
      toggleColorScheme();
      await new Promise(resolve => setTimeout(resolve, 100));
    }

    const restoreLight = invertColors ? swapLogoAndBackgroundColors() : null;
    const lightTitleColor = getTitleColor();
    const lightBgColor = getBackgroundColor();
    if (restoreLight) restoreLight();

    // Switch to dark theme
    toggleColorScheme();
    await new Promise(resolve => setTimeout(resolve, 100));

    const restoreDark = invertColors ? swapLogoAndBackgroundColors() : null;
    const darkTitleColor = getTitleColor();
    const darkBgColor = getBackgroundColor();
    if (restoreDark) restoreDark();

    // Restore original theme if needed
    if (originalTheme === 'light') {
      toggleColorScheme();
      await new Promise(resolve => setTimeout(resolve, 100));
    }

    // Create the adaptive SVG
    const svg = isBanner ? await generateStravaBannerSVG() : await generateSVG(300, lightTitleColor);

    // Add style element with media queries
    const style = document.createElementNS('http://www.w3.org/2000/svg', 'style');
    style.textContent = `
      .logo-fill { fill: ${lightTitleColor}; }
      .bg-fill { fill: ${lightBgColor}; }

      @media (prefers-color-scheme: dark) {
        .logo-fill { fill: ${darkTitleColor}; }
        .bg-fill { fill: ${darkBgColor}; }
      }
    `;
    svg.insertBefore(style, svg.firstChild);

    // Update all elements to use classes
    const rects = svg.querySelectorAll('rect');
    rects.forEach(rect => {
      const currentFill = rect.getAttribute('fill');
      rect.removeAttribute('fill');
      // Background rects typically use the sky/background color
      if (currentFill && (currentFill.includes('bg-sky') || currentFill === lightBgColor)) {
        rect.setAttribute('class', 'bg-fill');
      } else {
        rect.setAttribute('class', 'logo-fill');
      }
    });

    // Update all text and path elements to use logo-fill class
    const logoElements = svg.querySelectorAll('text, path, polygon, ellipse, circle');
    logoElements.forEach(el => {
      el.removeAttribute('fill');
      el.setAttribute('class', 'logo-fill');
    });

    return svg;
  };

  // Function to generate and add each asset
  const generateAsset = (
    config: typeof themeAssetConfigs[0] | typeof bannerAssetConfigs[0],
    themeName: 'light' | 'dark',
    callback: () => void
  ) => {
    const themeFolder = getThemeFolder(themeName === 'dark');

    // Set chevron mode for this asset if applicable
    const needsChevronToggle = 'chevronOnly' in config && config.chevronOnly !== chevronOnly;
    if (needsChevronToggle) {
      chevronOnly = config.chevronOnly!;
    }

    // Swap colors if this is an inverted asset
    const shouldInvert = 'invertColors' in config && config.invertColors;
    const restoreColors = shouldInvert ? swapLogoAndBackgroundColors() : null;

    if ('isBanner' in config && config.isBanner) {
      // Generate banner variant
      generateStravaBannerSVG()
        .then((svg) => {
          // Create canvas at specified dimensions
          const canvas = document.createElement('canvas');
          canvas.width = config.width!;
          canvas.height = config.height!;

          const ctx = canvas.getContext('2d');
          if (!ctx) throw new Error('Cannot get canvas context');

          // Serialize SVG to data URL
          const svgData = new XMLSerializer().serializeToString(svg);
          const svgBlob = new Blob([svgData], { type: 'image/svg+xml;charset=utf-8' });
          const url = URL.createObjectURL(svgBlob);

          // Load SVG as image
          const img = new Image();
          img.crossOrigin = 'anonymous';

          img.onload = () => {
            // Draw SVG to canvas, cropping/scaling as needed
            const scale = Math.max(config.width / 1210, config.height / 593);
            const scaledWidth = 1210 * scale;
            const scaledHeight = 593 * scale;
            const offsetX = (config.width - scaledWidth) / 2;
            const offsetY = (config.height - scaledHeight) / 2;

            ctx.drawImage(img, offsetX, offsetY, scaledWidth, scaledHeight);
            URL.revokeObjectURL(url);

            canvas.toBlob((blob) => {
              if (blob) {
                assets[`${themeFolder}/${config.name}`] = blob;
              }
              if (restoreColors) restoreColors();
              callback();
            }, 'image/png');
          };

          img.onerror = () => {
            URL.revokeObjectURL(url);
            if (restoreColors) restoreColors();
            callback();
          };

          img.src = url;
        })
        .catch(() => {
          if (restoreColors) restoreColors();
          callback();
        });
    } else if ('isVector' in config && config.isVector) {
      // Generate SVG
      const originalBg = useTransparentBackground;
      if (shouldInvert) {
        useTransparentBackground = false; // Ensure background is rendered
      }

      generateSVG(300, getTitleColor())
        .then((svg) => {
          const svgData = new XMLSerializer().serializeToString(svg);
          const blob = new Blob([svgData], { type: 'image/svg+xml' });
          assets[`${themeFolder}/${config.name}`] = blob;
          if (restoreColors) restoreColors();
          useTransparentBackground = originalBg;
          callback();
        })
        .catch(() => {
          if (restoreColors) restoreColors();
          useTransparentBackground = originalBg;
          callback();
        });
    } else if ('isIco' in config && config.isIco) {
      // Generate ICO file
      const size = ('size' in config && config.size) ? config.size : 32;
      const scale = 1; // ICO should be exactly 32x32

      generatePNG(size, getTitleColor(), scale)
        .then((canvas) => canvasToIco(canvas))
        .then((icoBlob) => {
          assets[`${themeFolder}/${config.name}`] = icoBlob;
          if (restoreColors) restoreColors();
          callback();
        })
        .catch(() => {
          if (restoreColors) restoreColors();
          callback();
        });
    } else {
      // Generate PNG
      const size = ('size' in config && config.size) ? config.size : 300;
      const scale = ('scale' in config && config.scale) ? config.scale : (size >= 512 ? 2 : 1);

      generatePNG(size, getTitleColor(), scale)
        .then((canvas) => {
          canvas.toBlob((blob) => {
            if (blob) {
              assets[`${themeFolder}/${config.name}`] = blob;
            }
            if (restoreColors) restoreColors();
            callback();
          }, 'image/png');
        })
        .catch(() => {
          if (restoreColors) restoreColors();
          callback();
        });
    }
  };

  // Generate assets for a specific theme
  const generateThemeAssets = (themeName: 'light' | 'dark', callback: () => void) => {
    switchTheme(themeName, () => {
      const allConfigs = [...themeAssetConfigs, ...bannerAssetConfigs];
      let configIndex = 0;

      const generateNextAsset = () => {
        if (configIndex < allConfigs.length) {
          const config = allConfigs[configIndex]!;
          configIndex++;
          generateAsset(config, themeName, generateNextAsset);
        } else {
          callback();
        }
      };

      generateNextAsset();
    });
  };

  // Generate banner SVGs for a specific theme
  const generateBannerSVGs = (themeName: 'light' | 'dark', callback: () => void) => {
    switchTheme(themeName, () => {
      let configIndex = 0;
      const themeFolder = getThemeFolder(themeName === 'dark');

      const generateNextBannerSVG = () => {
        if (configIndex < bannerSvgConfigs.length) {
          const config = bannerSvgConfigs[configIndex]!;
          configIndex++;

          generateStravaBannerSVG()
            .then((svg) => {
              const svgData = new XMLSerializer().serializeToString(svg);
              const blob = new Blob([svgData], { type: 'image/svg+xml' });
              assets[`${themeFolder}/${config.name}`] = blob;
              generateNextBannerSVG();
            })
            .catch(() => {
              generateNextBannerSVG();
            });
        } else {
          callback();
        }
      };

      generateNextBannerSVG();
    });
  };

  // Generate adaptive SVGs
  const generateAdaptiveSVGs = (callback: () => void) => {
    let configIndex = 0;

    const generateNextAdaptiveSVG = () => {
      if (configIndex < adaptiveSvgConfigs.length) {
        const config = adaptiveSvgConfigs[configIndex]!;
        configIndex++;

        const isBanner = config.isBannerSvg || false;
        const chevronOnlyValue = config.chevronOnly || false;
        const invertColorsValue = config.invertColors || false;

        // Set chevron mode if applicable
        if (!isBanner) {
          const needsChevronToggle = chevronOnlyValue !== chevronOnly;
          if (needsChevronToggle) {
            chevronOnly = chevronOnlyValue;
          }
        }

        // Generate the adaptive SVG
        generateAdaptiveSVG(isBanner, chevronOnlyValue, invertColorsValue)
          .then((svg) => {
            const svgData = new XMLSerializer().serializeToString(svg);
            const blob = new Blob([svgData], { type: 'image/svg+xml' });
            assets[config.name] = blob;
            generateNextAdaptiveSVG();
          })
          .catch(() => {
            generateNextAdaptiveSVG();
          });
      } else {
        callback();
      }
    };

    generateNextAdaptiveSVG();
  };

  // Generate all on-screen variants not covered by the existing theme asset configs.
  // Uses getColorsForTheme() directly so no theme switching is needed.
  const generateDirectVariants = (callback: () => void) => {
    const svgToBlob = (svg: SVGSVGElement) => {
      const str = new XMLSerializer().serializeToString(svg);
      return new Blob([str], { type: 'image/svg+xml' });
    };

    const svgToPngBlob = (svg: SVGSVGElement, scale = 2): Promise<Blob> => {
      const vb = (svg.getAttribute('viewBox') ?? '').split(' ');
      const vbW = parseFloat(vb[2] ?? '100');
      const vbH = parseFloat(vb[3] ?? '100');
      const str = new XMLSerializer().serializeToString(svg);
      const url = URL.createObjectURL(new Blob([str], { type: 'image/svg+xml' }));
      return new Promise((resolve, reject) => {
        const img = new Image();
        img.onload = () => {
          const canvas = document.createElement('canvas');
          canvas.width = Math.max(1, Math.round(vbW * scale));
          canvas.height = Math.max(1, Math.round(vbH * scale));
          const ctx = canvas.getContext('2d');
          if (!ctx) { URL.revokeObjectURL(url); reject(new Error('no ctx')); return; }
          ctx.scale(scale, scale);
          ctx.drawImage(img, 0, 0, vbW, vbH);
          URL.revokeObjectURL(url);
          canvas.toBlob((blob) => {
            if (blob) resolve(blob); else reject(new Error('toBlob null'));
          }, 'image/png');
        };
        img.onerror = () => { URL.revokeObjectURL(url); reject(new Error('load failed')); };
        img.src = url;
      });
    };

    const themes: Array<'light' | 'dark'> = ['light', 'dark'];
    const mods = [
      { transparent: false, inverted: false, suffix: '' },
      { transparent: true,  inverted: false, suffix: '-transparent' },
      { transparent: false, inverted: true,  suffix: '-inverted' },
    ];

    interface DV {
      folder: string; name: string; size: number;
      theme: 'light' | 'dark'; chevronOnly: boolean;
      transparent: boolean; inverted: boolean;
      fitToContent?: boolean; singleLine?: boolean;
      isBanner?: boolean; noText?: boolean; noTrees?: boolean;
      format: 'png' | 'svg';
    }

    const variants: DV[] = [];

    // Chevron sizes shown on screen but not in existing ZIP (16, 50, 100, 250)
    // Also add transparent for existing 32px
    for (const size of [16, 32, 50, 100, 250]) {
      for (const theme of themes) {
        for (const { transparent, inverted, suffix } of mods) {
          // Skip non-transparent 32px (normal + inverted already in ZIP)
          if (size === 32 && !transparent && !inverted) continue;
          // Skip inverted 32px already in ZIP
          if (size === 32 && !transparent && inverted) continue;
          variants.push({ folder: theme, name: `chevron-${size}x${size}${suffix}.png`, size, theme, chevronOnly: true, transparent, inverted, format: 'png' });
        }
      }
    }

    // Logo (two-line square) sizes on screen but not in ZIP (100, 250)
    // Also add transparent for existing 32px
    for (const size of [32, 100, 250]) {
      for (const theme of themes) {
        for (const { transparent, inverted, suffix } of mods) {
          if (size === 32 && !transparent && !inverted) continue; // already in ZIP
          if (size === 32 && !transparent && inverted) continue;  // already in ZIP
          variants.push({ folder: theme, name: `logo-${size}x${size}${suffix}.png`, size, theme, chevronOnly: false, transparent, inverted, format: 'png' });
        }
      }
    }

    // Fit-to-content (two-line) — both display heights generate the same underlying SVG
    for (const theme of themes) {
      for (const { transparent, inverted, suffix } of mods) {
        variants.push({ folder: theme, name: `logo-fit${suffix}.png`,  size: 250, theme, chevronOnly: false, transparent, inverted, fitToContent: true, format: 'png' });
        variants.push({ folder: theme, name: `logo-fit${suffix}.svg`,  size: 250, theme, chevronOnly: false, transparent, inverted, fitToContent: true, format: 'svg' });
      }
    }

    // Single-line variants
    for (const size of [100, 50]) {
      for (const theme of themes) {
        for (const { transparent, inverted, suffix } of mods) {
          variants.push({ folder: theme, name: `logo-single-${size}px${suffix}.png`, size, theme, chevronOnly: false, transparent, inverted, singleLine: true, format: 'png' });
          variants.push({ folder: theme, name: `logo-single-${size}px${suffix}.svg`, size, theme, chevronOnly: false, transparent, inverted, singleLine: true, format: 'svg' });
        }
      }
    }

    // Banner variants: full, no-text, minimal — SVG + PNG for each theme
    const bannerDefs = [
      { noText: false, noTrees: false, nameSuffix: 'og-banner-1210x593' },
      { noText: true,  noTrees: false, nameSuffix: 'banner-no-text' },
      { noText: true,  noTrees: true,  nameSuffix: 'banner-minimal' },
    ];
    for (const theme of themes) {
      for (const { noText, noTrees, nameSuffix } of bannerDefs) {
        variants.push({ folder: theme, name: `${nameSuffix}.svg`, size: 0, theme, chevronOnly: false, transparent: false, inverted: false, isBanner: true, noText, noTrees, format: 'svg' });
        variants.push({ folder: theme, name: `${nameSuffix}.png`, size: 0, theme, chevronOnly: false, transparent: false, inverted: false, isBanner: true, noText, noTrees, format: 'png' });
      }
    }

    const run = async () => {
      for (const v of variants) {
        const colors = getColorsForTheme(v.theme);
        try {
          let svg: SVGSVGElement;
          if (v.isBanner) {
            svg = await generateStravaBannerSVG({ noText: v.noText, noTrees: v.noTrees, colors });
          } else {
            const logoColor = v.inverted ? colors.sky : colors.logo;
            const bgColor   = v.inverted ? colors.logo : colors.sky;
            svg = await generateSVG(v.size, logoColor, {
              chevronOnly: v.chevronOnly,
              fitToContent: v.fitToContent ?? false,
              singleLine: v.singleLine ?? false,
              backgroundColor: bgColor,
              transparent: v.transparent,
            });
          }
          assets[`${v.folder}/${v.name}`] = v.format === 'svg' ? svgToBlob(svg) : await svgToPngBlob(svg);
        } catch {
          // skip failed assets
        }
      }
    };

    run().then(() => callback()).catch(() => callback());
  };

  // Generate all assets for both themes
  generateThemeAssets('light', () => {
    generateThemeAssets('dark', () => {
      // Generate banner SVGs for both themes
      generateBannerSVGs('light', () => {
        generateBannerSVGs('dark', () => {
          // Generate adaptive SVGs
          generateAdaptiveSVGs(() => {
            generateDirectVariants(() => {
            // Restore original theme and chevron mode
            chevronOnly = currentChevronOnly;
            switchTheme(currentTheme, () => {
              // Create manifest files for both themes
              const lightManifest = JSON.stringify({
                ...SiteManifest,
                icons: [
                  { src: "light/android-chrome-192x192-chevron-inverted.png", sizes: "192x192", type: "image/png" },
                  { src: "light/android-chrome-512x512-chevron-inverted.png", type: "image/png", sizes: "512x512", purpose: "maskable" },
                  { src: "light/android-chrome-512x512-chevron-inverted.png", sizes: "512x512", type: "image/png" }
                ]
              }, null, 2);

              const darkManifest = JSON.stringify({
                ...SiteManifest,
                icons: [
                  { src: "dark/android-chrome-192x192-chevron-inverted.png", sizes: "192x192", type: "image/png" },
                  { src: "dark/android-chrome-512x512-chevron-inverted.png", type: "image/png", sizes: "512x512", purpose: "maskable" },
                  { src: "dark/android-chrome-512x512-chevron-inverted.png", sizes: "512x512", type: "image/png" }
                ]
              }, null, 2);

              assets['light/site.manifest'] = new Blob([lightManifest], { type: 'application/json' });
              assets['dark/site.manifest'] = new Blob([darkManifest], { type: 'application/json' });

              // All assets generated, create zip
              createAndDownloadZip(assets);
            });
            }); // generateDirectVariants
          });
        });
      });
    });
  });
}

// Create zip file and download
function createAndDownloadZip(assets: { [key: string]: Blob }) {
  // Load JSZip from CDN
  const script = document.createElement('script');
  script.src = 'https://cdn.jsdelivr.net/npm/jszip@3.10.1/dist/jszip.min.js';
  script.onload = () => {
    try {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-assignment
      const JSZip = (globalThis as any).JSZip;
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-assignment
      const zip = new JSZip();

      // Add all assets to zip
      for (const [filename, blob] of Object.entries(assets)) {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access
        zip.file(filename, blob);
      }

      // Add a README file
      const readme = `
Bay Bandits Logo Assets
=======================

This package contains assets for both light and dark themes, organized in separate folders.
Each theme includes both full logo (with text) and chevron-only variants.

STRUCTURE:
----------
light/               Light theme assets
  ├── favicon-32x32.png              Favicon 32x32 PNG (with text)
  ├── favicon-32x32-inverted.png     Favicon 32x32 PNG (with text, inverted colors)
  ├── favicon.ico                    Favicon ICO format (with text)
  ├── favicon-inverted.ico           Favicon ICO format (with text, inverted colors)
  ├── favicon-32x32-chevron.png      Favicon 32x32 PNG (chevron only)
  ├── favicon-32x32-chevron-inverted.png  Favicon 32x32 PNG (chevron only, inverted)
  ├── favicon-chevron.ico            Favicon ICO format (chevron only)
  ├── favicon-chevron-inverted.ico   Favicon ICO format (chevron only, inverted)
  ├── apple-touch-icon-180x180.png   Apple Touch Icon 180x180 (with text)
  ├── apple-touch-icon-180x180-inverted.png   Apple Touch Icon (with text, inverted)
  ├── apple-touch-icon-180x180-chevron.png    Apple Touch Icon (chevron only)
  ├── apple-touch-icon-180x180-chevron-inverted.png  Apple Touch Icon (chevron, inverted)
  ├── android-chrome-192x192.png     App icon 192x192 (with text)
  ├── android-chrome-192x192-inverted.png     App icon 192x192 (with text, inverted)
  ├── android-chrome-192x192-chevron.png      App icon 192x192 (chevron only)
  ├── android-chrome-192x192-chevron-inverted.png  App icon 192x192 (chevron, inverted)
  ├── android-chrome-512x512.png     App icon 512x512 (with text)
  ├── android-chrome-512x512-inverted.png     App icon 512x512 (with text, inverted)
  ├── android-chrome-512x512-chevron.png      App icon 512x512 (chevron only)
  ├── android-chrome-512x512-chevron-inverted.png  App icon 512x512 (chevron, inverted)
  ├── logo.svg                       Vector logo (with text)
  ├── logo-inverted.svg              Vector logo (with text, inverted colors)
  ├── logo-chevron.svg               Vector logo (chevron only)
  ├── logo-chevron-inverted.svg      Vector logo (chevron only, inverted colors)
  ├── og-logo-600x600.png            Social media preview square (with text)
  ├── og-logo-600x600-inverted.png   Social media preview square (with text, inverted)
  ├── og-logo-600x600-chevron.png    Social media preview square (chevron only)
  ├── og-logo-600x600-chevron-inverted.png  Social media preview (chevron, inverted)
  ├── og-banner-1200x630.png         Social media preview landscape banner PNG
  ├── og-banner-1210x593.png         Social media preview PNG (Strava dimensions)
  ├── og-banner-1210x593.svg         Social media preview SVG (Strava dimensions)
  └── site.manifest                  Web app manifest (references light theme icons)

dark/                Dark theme assets
  └── [same structure as light/]

logo-adaptive.svg                    Adaptive SVG (with text, auto-switches light/dark)
logo-adaptive-inverted.svg           Adaptive SVG (with text, inverted, auto-switches)
logo-chevron-adaptive.svg            Adaptive SVG (chevron only, auto-switches)
logo-chevron-adaptive-inverted.svg   Adaptive SVG (chevron only, inverted, auto-switches)
og-banner-adaptive.svg               Adaptive banner SVG (auto-switches light/dark)

USAGE NOTES:
------------
Logo Variants:
- Files without "-chevron" suffix include the full logo with "BAY BANDITS" text
- Files with "-chevron" suffix contain only the chevron icon (no text)
- Files with "-inverted" suffix swap the logo and background colors
  (e.g., if normal has purple logo on light background, inverted has light logo on purple background)
- Inverted variants are useful for creating visual contrast or matching different background contexts
- Choose the variant that best fits your use case and design needs

Site Icons:
- favicon.ico: Traditional favicon format for broad browser compatibility
- favicon-32x32.png: Modern PNG favicon for <link rel="icon" sizes="32x32" href="...">
- apple-touch-icon-180x180.png: Use in <link rel="apple-touch-icon" sizes="180x180" href="...">
- android-chrome-192x192.png & android-chrome-512x512.png: Referenced in site.manifest
- Chevron-only variants available for minimal/compact designs

Site Manifest:
- Use site.manifest as your web app manifest file
- Update icon paths in the manifest to match your deployment structure
- Serve with Content-Type: application/manifest+json
- Default manifest references full logos; update to -chevron variants if preferred

Social Media Previews (og:image):
- og-logo-600x600.png: Square variant (with text)
- og-logo-600x600-inverted.png: Square variant (with text, inverted colors)
- og-logo-600x600-chevron.png: Square variant (chevron only)
- og-logo-600x600-chevron-inverted.png: Square variant (chevron only, inverted colors)
- og-banner-1200x630.png: Standard Open Graph landscape format PNG (1.91:1 ratio)
- og-banner-1210x593.png: Strava club header dimensions PNG
- og-banner-1210x593.svg: Strava club header dimensions SVG (per theme)
- og-banner-adaptive.svg: Adaptive banner SVG (auto-switches with prefers-color-scheme)

Example HTML:
<!-- Traditional favicon -->
<link rel="icon" href="/light/favicon.ico">
<!-- Modern PNG favicons -->
<link rel="icon" type="image/png" sizes="32x32" href="/light/favicon-32x32.png">
<!-- Apple Touch Icon -->
<link rel="apple-touch-icon" sizes="180x180" href="/light/apple-touch-icon-180x180.png">
<!-- Web App Manifest -->
<link rel="manifest" href="/light/site.manifest">
<!-- Open Graph image -->
<meta property="og:image" content="https://yourdomain.com/light/og-banner-1200x630.png">

For chevron-only icons:
<link rel="icon" href="/light/favicon-chevron.ico">
<link rel="icon" type="image/png" sizes="32x32" href="/light/favicon-32x32-chevron.png">

For inverted color icons:
<link rel="icon" href="/light/favicon-inverted.ico">
<link rel="icon" type="image/png" sizes="32x32" href="/light/favicon-32x32-inverted.png">

Banner SVGs:
<!-- Theme-specific banner SVG -->
<img src="/light/og-banner-1210x593.svg" alt="Bay Bandits Banner">
<!-- Adaptive banner that auto-switches -->
<img src="/og-banner-adaptive.svg" alt="Bay Bandits Banner">

Adaptive SVGs (automatically switch between light/dark based on user's system preference):
<!-- Adaptive SVG that changes with prefers-color-scheme -->
<img src="/logo-adaptive.svg" alt="Bay Bandits Logo">
<!-- Chevron-only adaptive variant -->
<img src="/logo-chevron-adaptive.svg" alt="Bay Bandits Chevron">
<!-- Adaptive banner -->
<img src="/og-banner-adaptive.svg" alt="Bay Bandits Banner">

Adaptive SVG Features:
- Automatically adapts to user's system color scheme preference (light/dark mode)
- Uses CSS @media (prefers-color-scheme: dark) internally
- Single file that works in both themes
- Recommended for websites that support system-based theme switching
- Five variants: normal, inverted, chevron, chevron-inverted, and banner
- Each variant automatically switches colors between light and dark modes
- Banner SVG is perfect for hero sections, headers, or social media that support SVG

Generated: ${new Date().toISOString()}
Theme: Both light and dark variants included
      `.trim();

      // eslint-disable-next-line @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access
      zip.file('README.txt', readme);

      // Generate and download
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access
      zip.generateAsync({ type: 'blob' }).then((blob: Blob) => {
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'bay-bandits-logo-assets.zip';
        a.click();
        URL.revokeObjectURL(url);
      });
    } catch (error) {
      console.error('Error creating zip file:', error);
      console.log('JSZip library may not be loaded yet. Please try again.');
    }
  };

  script.onerror = () => {
    console.error('Error loading JSZip library');
  };

  document.head.appendChild(script);
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
function generateStravaBannerSVG(options: {
  noText?: boolean;
  noTrees?: boolean;
  colors?: ReturnType<typeof getThemeColors>;
} = {}): Promise<SVGSVGElement> {
  const svgNS = 'http://www.w3.org/2000/svg';
  const svg = document.createElementNS(svgNS, 'svg');

  const width = 1210;
  const height = 593;

  svg.setAttribute('width', width.toString());
  svg.setAttribute('height', height.toString());
  svg.setAttribute('xmlns', svgNS);
  svg.setAttribute('viewBox', `0 0 ${width} ${height}`);

  const colors = options.colors ?? getThemeColors();

  // Add background image if available
  if (skyImageData) {
    const defs = document.createElementNS(svgNS, 'defs');
    const pattern = document.createElementNS(svgNS, 'pattern');
    pattern.setAttribute('id', 'skyImagePattern');
    pattern.setAttribute('x', '0');
    pattern.setAttribute('y', '0');
    pattern.setAttribute('width', width.toString());
    pattern.setAttribute('height', height.toString());
    pattern.setAttribute('patternUnits', 'userSpaceOnUse');

    const image = document.createElementNS(svgNS, 'image');
    // We'll need to embed the image data
    image.setAttribute('href', skyImageData);
    image.setAttribute('x', skyImageOffsetX.toString());
    image.setAttribute('y', skyImageOffsetY.toString());
    image.setAttribute('width', (width * skyImageScale).toString());
    image.setAttribute('height', (height * skyImageScale).toString());
    image.setAttribute('preserveAspectRatio', 'xMidYMid slice');

    pattern.appendChild(image);
    defs.appendChild(pattern);
    svg.appendChild(defs);

    // Use pattern as background
    const skyRect = document.createElementNS(svgNS, 'rect');
    skyRect.setAttribute('width', width.toString());
    skyRect.setAttribute('height', height.toString());
    skyRect.setAttribute('fill', 'url(#skyImagePattern)');
    svg.appendChild(skyRect);
  } else {
    // Sky background
    const skyColor = applyOpacityToColor(colors.sky, colors.skyOpacity);
    const skyRect = document.createElementNS(svgNS, 'rect');
    skyRect.setAttribute('width', width.toString());
    skyRect.setAttribute('height', height.toString());
    skyRect.setAttribute('fill', skyColor);
    svg.appendChild(skyRect);
  }

  // Calculate hill positioning
  // Hills from homepage use viewBox="0 0 1440 320" - scale proportionally to banner width
  const hillScaleX = width / 1440;
  const hillHeight = 320;

  // CSS shows: back-hill has bottom: 5vh offset for depth
  const backHillOffsetY = height - hillHeight - (height * 0.05) - 75; // 5vh offset + 75px raised
  const frontHillOffsetY = height - hillHeight - 55; // anchored at bottom + 55px raised

  // Back hill path (scaled from index.gts, with 5vh elevation)
  const backHillPath = document.createElementNS(svgNS, 'path');
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
  const frontHillPath = document.createElementNS(svgNS, 'path');
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
    // eslint-disable-next-line warp-drive/no-external-request-patterns
    fetch('/redwood.svg').then(r => r.text()),
    // eslint-disable-next-line warp-drive/no-external-request-patterns
    fetch('/logo-orange-chevron.svg').then(r => r.text()),
  ]).then(([treeSvgText, chevronSvgText]) => {
    const parser = new DOMParser();

    // Create defs section for reusable elements
    const defs = document.createElementNS(svgNS, 'defs');

    // Parse and add tree symbol
    const treeDoc = parser.parseFromString(treeSvgText, 'image/svg+xml');
    const treeSvgEl = treeDoc.documentElement;
    const treeSymbol = document.createElementNS(svgNS, 'symbol');
    treeSymbol.setAttribute('id', 'tree');
    treeSymbol.setAttribute('viewBox', treeSvgEl.getAttribute('viewBox') || '0 0 100 100');
    Array.from(treeSvgEl.children).forEach(child => {
      const imported = document.importNode(child, true) as SVGElement;
      if (imported instanceof SVGElement) {
        imported.removeAttribute('fill');
      }
      treeSymbol.appendChild(imported);
    });
    defs.appendChild(treeSymbol);

    // Parse and add chevron symbol
    const chevronDoc = parser.parseFromString(chevronSvgText, 'image/svg+xml');
    const chevronSvgEl = chevronDoc.documentElement;
    const chevronSymbol = document.createElementNS(svgNS, 'symbol');
    chevronSymbol.setAttribute('id', 'chevron');
    chevronSymbol.setAttribute('viewBox', chevronSvgEl.getAttribute('viewBox') || '0 0 100 100');
    Array.from(chevronSvgEl.children).forEach(child => {
      const imported = document.importNode(child, true) as SVGElement;
      if (imported instanceof SVGElement) {
        imported.removeAttribute('fill');
      }
      chevronSymbol.appendChild(imported);
    });
    defs.appendChild(chevronSymbol);

    svg.appendChild(defs);

    // Draw trees
    if (!options.noTrees) {
    const baseTreeWidth = width * 0.20;
    const baseTreeHeight = height * 0.40;

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

      const treeGroup = document.createElementNS(svgNS, 'g');

      // Apply flip transform if needed
      if (pos.flip) {
        const centerX = pos.x + scaledWidth / 2;
        treeGroup.setAttribute('transform', `translate(${centerX * 2}, 0) scale(-1, 1)`);
      }

      const useEl = document.createElementNS(svgNS, 'use');
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
    } // end noTrees

    // Center logo group
    if (!options.noText) {
    const centerX = width / 2;
    const centerY = height * 0.35;
    const logoGroup = document.createElementNS(svgNS, 'g');

    // If using sky image, add a semi-transparent colored rectangle behind logo/tagline
    if (skyImageData) {
      const backgroundColor = getBackgroundColor();

      // Estimate logo area height
      const estimatedHeight = 170;

      const bgRect = document.createElementNS(svgNS, 'rect');
      bgRect.setAttribute('x', (centerX - 250).toString());
      bgRect.setAttribute('y', (centerY - 80).toString());
      bgRect.setAttribute('width', '500');
      bgRect.setAttribute('height', estimatedHeight.toString());
      bgRect.setAttribute('fill', backgroundColor);
      bgRect.setAttribute('opacity', '0.75');
      bgRect.setAttribute('rx', '8'); // rounded corners
      svg.appendChild(bgRect);
    }

    // Chevron - sized to match the height of the capital letters (reduced by 20%)
    const chevronSize = 40;
    const textY = centerY - 16;

    // Create temp text element to measure width (this is an approximation)
    const tempText = document.createElementNS(svgNS, 'text');
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

    const chevronUse = document.createElementNS(svgNS, 'use');
    chevronUse.setAttribute('href', '#chevron');
    chevronUse.setAttribute('x', chevronX.toString());
    chevronUse.setAttribute('y', chevronY.toString());
    chevronUse.setAttribute('width', chevronSize.toString());
    chevronUse.setAttribute('height', chevronSize.toString());
    chevronUse.setAttribute('fill', colors.logo);
    logoGroup.appendChild(chevronUse);

    // Main text - positioned after chevron
    const textX = logoStartX + chevronSize + chevronMargin;
    const mainText = document.createElementNS(svgNS, 'text');
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
    const line = document.createElementNS(svgNS, 'line');
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

    const tagline = document.createElementNS(svgNS, 'text');
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
    } // end noText

    // Add mobile fold masks if enabled
    if (showBannerMasks) {
      const colorScheme = document.body.classList.contains('dark-mode') ? 'dark' : 'light';
      const maskColor = colorScheme === 'dark' ? 'rgba(0, 0, 0, 0.5)' : 'rgba(255, 255, 255, 0.5)';

      // Top mask (100px)
      const topMask = document.createElementNS(svgNS, 'rect');
      topMask.setAttribute('width', width.toString());
      topMask.setAttribute('height', '100');
      topMask.setAttribute('y', '0');
      topMask.setAttribute('fill', maskColor);
      svg.appendChild(topMask);

      // Bottom mask (150px)
      const bottomMask = document.createElementNS(svgNS, 'rect');
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
          const style = document.createElementNS(svgNS, 'style');
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

      const a = document.createElement('a');
      a.href = url;
      a.download = 'bay-bandits-strava-banner.svg';
      a.click();

      URL.revokeObjectURL(url);
    })
    .catch((error: Error) => {
      console.error('Error downloading Strava banner:', error);
    });
}

function downloadStravaBannerPNG() {
  const width = 1210;
  const height = 593;

  generateStravaBannerSVG()
    .then((svg) => {
      // Create canvas at exact Strava banner dimensions
      const canvas = document.createElement('canvas');
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
      const img = new Image();
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
        const a = document.createElement('a');
        a.href = url;
        a.download = 'bay-bandits-strava-banner.png';
        a.click();
        URL.revokeObjectURL(url);
      }, 'image/png');
    })
    .catch((error: Error) => {
      console.error('Error downloading Strava banner PNG:', error);
    });
}


<template>
  {{pageTitle "Bandits | The Bay Area Trail Running Community"}}

  <ThemedPage @hideFoothills={{true}} class="branding">
    <:header>Brand Assets</:header>
    <:default>

      {{! ── Download All ── }}
      <div class="download-all-bar">
        <button type="button" class="download-btn download-all-btn" {{on "click" downloadAssetsAsZip}}>Download All Assets (ZIP)</button>
      </div>

      {{! Color Controls }}
      <div class="color-controls" {{initColorPicker}}>
        <div class="color-picker-group">
          <label for="logo-color">Logo Color:</label>
          <input type="color" id="logo-color" class="logo-color-input" value="#9333ea" {{on "input" handleColorChange}} />
        </div>
        <div class="color-picker-group">
          <label for="background-color">Sky Color:</label>
          <input type="color" id="background-color" class="background-color-input" value="#f3e8ff" {{on "input" handleBackgroundColorChange}} />
        </div>
        <div class="color-picker-group">
          <label for="back-hill-color">Back Hill:</label>
          <input type="color" id="back-hill-color" class="back-hill-color-input" value="#ff69b4" {{on "input" handleBackHillColorChange}} />
        </div>
        <div class="color-picker-group">
          <label for="tree-color">Tree Color:</label>
          <input type="color" id="tree-color" class="tree-color-input" value="#052c16" {{on "input" handleTreeColorChange}} />
        </div>
        <div class="color-picker-group">
          <label for="alt-tree-color">Alt Tree:</label>
          <input type="color" id="alt-tree-color" class="alt-tree-color-input" value="#06a743" {{on "input" handleAltTreeColorChange}} />
        </div>
        <div class="opacity-control-group">
          <label for="background-opacity">Sky Opacity: <span class="background-opacity-value">100%</span></label>
          <input type="range" id="background-opacity" class="background-opacity-input" min="0" max="1" step="0.01" value="1" {{on "input" handleBackgroundOpacityChange}} />
        </div>
        <div class="opacity-control-group">
          <label for="logo-opacity">Logo Opacity: <span class="opacity-value">100%</span></label>
          <input type="range" id="logo-opacity" class="logo-opacity-input" min="0" max="1" step="0.01" value="1" {{on "input" handleOpacityChange}} />
        </div>
        <button type="button" class="download-btn reset-btn" {{on "click" resetColors}}>Reset Current Theme Colors</button>
      </div>

      {{! ── Chevron Only ── }}
      <h2>Chevron Only</h2>
      <div class="preview-sizes">

        <div class="preview-size-item">
          <h3>250 × 250</h3>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="250" data-chevron-only="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="250" data-chevron-only="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Transparent</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="250" data-chevron-only="true" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Transparent</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="250" data-chevron-only="true" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Inverted</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="250" data-chevron-only="true" data-inverted="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Inverted</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="250" data-chevron-only="true" data-inverted="true"></div>
          </div>
        </div>

        <div class="preview-size-item">
          <h3>100 × 100</h3>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="100" data-chevron-only="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="100" data-chevron-only="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Transparent</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="100" data-chevron-only="true" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Transparent</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="100" data-chevron-only="true" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Inverted</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="100" data-chevron-only="true" data-inverted="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Inverted</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="100" data-chevron-only="true" data-inverted="true"></div>
          </div>
        </div>

        <div class="preview-size-item">
          <h3>50 × 50</h3>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="50" data-chevron-only="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="50" data-chevron-only="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Transparent</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="50" data-chevron-only="true" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Transparent</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="50" data-chevron-only="true" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Inverted</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="50" data-chevron-only="true" data-inverted="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Inverted</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="50" data-chevron-only="true" data-inverted="true"></div>
          </div>
        </div>

        <div class="preview-size-item">
          <h3>32 × 32</h3>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="32" data-chevron-only="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="32" data-chevron-only="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Transparent</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="32" data-chevron-only="true" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Transparent</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="32" data-chevron-only="true" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Inverted</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="32" data-chevron-only="true" data-inverted="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Inverted</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="32" data-chevron-only="true" data-inverted="true"></div>
          </div>
        </div>

        <div class="preview-size-item">
          <h3>16 × 16</h3>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="16" data-chevron-only="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="16" data-chevron-only="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Transparent</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="16" data-chevron-only="true" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Transparent</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="16" data-chevron-only="true" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Inverted</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="16" data-chevron-only="true" data-inverted="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Inverted</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="16" data-chevron-only="true" data-inverted="true"></div>
          </div>
        </div>

      </div>

      {{! ── Chevron + Logo (Two Lines) ── }}
      <h2>Chevron + Logo (Two Lines)</h2>
      <div class="preview-sizes">

        <div class="preview-size-item">
          <h3>250 × 250</h3>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="250"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="250"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Transparent</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="250" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Transparent</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="250" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Inverted</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="250" data-inverted="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Inverted</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="250" data-inverted="true"></div>
          </div>
        </div>

        <div class="preview-size-item">
          <h3>100 × 100</h3>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="100"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="100"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Transparent</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="100" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Transparent</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="100" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Inverted</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="100" data-inverted="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Inverted</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="100" data-inverted="true"></div>
          </div>
        </div>

        <div class="preview-size-item">
          <h3>Fit — height 250px</h3>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="250" data-fit-to-content="true" data-display-height="250"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="250" data-fit-to-content="true" data-display-height="250"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Transparent</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="250" data-fit-to-content="true" data-display-height="250" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Transparent</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="250" data-fit-to-content="true" data-display-height="250" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Inverted</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="250" data-fit-to-content="true" data-display-height="250" data-inverted="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Inverted</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="250" data-fit-to-content="true" data-display-height="250" data-inverted="true"></div>
          </div>
        </div>

        <div class="preview-size-item">
          <h3>Fit — height 100px</h3>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="250" data-fit-to-content="true" data-display-height="100"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="250" data-fit-to-content="true" data-display-height="100"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Transparent</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="250" data-fit-to-content="true" data-display-height="100" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Transparent</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="250" data-fit-to-content="true" data-display-height="100" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Inverted</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="250" data-fit-to-content="true" data-display-height="100" data-inverted="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Inverted</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="250" data-fit-to-content="true" data-display-height="100" data-inverted="true"></div>
          </div>
        </div>

      </div>

      {{! ── Chevron + Logo (Single Line) ── }}
      <h2>Chevron + Logo (Single Line)</h2>
      <div class="preview-sizes">

        <div class="preview-size-item">
          <h3>Fit — height 100px</h3>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="100" data-single-line="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="100" data-single-line="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Transparent</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="100" data-single-line="true" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Transparent</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="100" data-single-line="true" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Inverted</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="100" data-single-line="true" data-inverted="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Inverted</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="100" data-single-line="true" data-inverted="true"></div>
          </div>
        </div>

        <div class="preview-size-item">
          <h3>Fit — height 50px</h3>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="50" data-single-line="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="50" data-single-line="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Transparent</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="50" data-single-line="true" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Transparent</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="50" data-single-line="true" data-transparent="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Light · Inverted</span>
            <div class="preview-cell checkered" data-preview="logo" data-theme="light" data-size="50" data-single-line="true" data-inverted="true"></div>
          </div>
          <div class="theme-preview-wrapper">
            <span class="theme-label">Dark · Inverted</span>
            <div class="preview-cell checkered-dark" data-preview="logo" data-theme="dark" data-size="50" data-single-line="true" data-inverted="true"></div>
          </div>
        </div>

      </div>

      {{! ── Strava Club Header / Banner ── }}
      <h2>Strava Club Header</h2>

      <div class="color-controls">
        <div class="color-picker-group">
          <label for="sky-image">Upload Background Image (optional):</label>
          <input type="file" id="sky-image" class="sky-image-input" accept="image/*" {{on "change" handleSkyImageUpload}} />
        </div>
        <div id="sky-image-controls" class="hidden">
          <button type="button" class="download-btn reset-btn" {{on "click" clearSkyImage}}>Clear Background Image</button>
          <div class="opacity-control-group">
            <label for="sky-image-scale">Image Scale: <span class="sky-image-scale-value">1.0</span></label>
            <input type="range" id="sky-image-scale" class="sky-image-scale-input" min="0.5" max="3" step="0.1" value="1" {{on "input" handleSkyImageScale}} />
          </div>
          <div class="opacity-control-group">
            <label for="sky-image-offset-x">Image Offset X: <span class="sky-image-offset-x-value">0</span></label>
            <input type="range" id="sky-image-offset-x" class="sky-image-offset-x-input" min="-500" max="500" step="10" value="0" {{on "input" handleSkyImageOffsetX}} />
          </div>
          <div class="opacity-control-group">
            <label for="sky-image-offset-y">Image Offset Y: <span class="sky-image-offset-y-value">0</span></label>
            <input type="range" id="sky-image-offset-y" class="sky-image-offset-y-input" min="-500" max="500" step="10" value="0" {{on "input" handleSkyImageOffsetY}} />
          </div>
        </div>
      </div>

      <p class="banner-info">Banner: 1210 × 593px. Top/bottom 100px may be cropped on desktop.</p>

      <div class="banner-variants">

        <div class="banner-variant-group">
          <h3>Full <button type="button" class="banner-mask-toggle-btn inline-toggle-btn" {{on "click" toggleBannerMasks}}>Safe Area: Hidden</button></h3>
          <div class="theme-preview-wrapper banner-wrapper">
            <span class="theme-label">Light</span>
            <div class="preview-cell banner-preview-cell checkered" data-preview="banner" data-theme="light"></div>
          </div>
          <div class="theme-preview-wrapper banner-wrapper">
            <span class="theme-label">Dark</span>
            <div class="preview-cell banner-preview-cell checkered-dark" data-preview="banner" data-theme="dark"></div>
          </div>
        </div>

        <div class="banner-variant-group">
          <h3>No Text <button type="button" class="banner-mask-toggle-btn inline-toggle-btn" {{on "click" toggleBannerMasks}}>Safe Area: Hidden</button></h3>
          <div class="theme-preview-wrapper banner-wrapper">
            <span class="theme-label">Light</span>
            <div class="preview-cell banner-preview-cell checkered" data-preview="banner" data-theme="light" data-no-text="true"></div>
          </div>
          <div class="theme-preview-wrapper banner-wrapper">
            <span class="theme-label">Dark</span>
            <div class="preview-cell banner-preview-cell checkered-dark" data-preview="banner" data-theme="dark" data-no-text="true"></div>
          </div>
        </div>

        <div class="banner-variant-group">
          <h3>No Trees / No Text <button type="button" class="banner-mask-toggle-btn inline-toggle-btn" {{on "click" toggleBannerMasks}}>Safe Area: Hidden</button></h3>
          <div class="theme-preview-wrapper banner-wrapper">
            <span class="theme-label">Light</span>
            <div class="preview-cell banner-preview-cell checkered" data-preview="banner" data-theme="light" data-no-trees="true" data-no-text="true"></div>
          </div>
          <div class="theme-preview-wrapper banner-wrapper">
            <span class="theme-label">Dark</span>
            <div class="preview-cell banner-preview-cell checkered-dark" data-preview="banner" data-theme="dark" data-no-trees="true" data-no-text="true"></div>
          </div>
        </div>

      </div>

    </:default>
  </ThemedPage>
</template>
