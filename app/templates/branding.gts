import { pageTitle } from 'ember-page-title';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';
import { initializeColorScheme, toggleColorScheme } from './index.gts';

let useTransparentBackground = false;
let customLogoColor: string | null = null;
let logoOpacity = 1;

function handleColorChange(event: Event) {
  const input = event.target as HTMLInputElement;
  customLogoColor = input.value;
  updateLogoColor();
  updatePreviews();
}

function handleOpacityChange(event: Event) {
  const input = event.target as HTMLInputElement;
  logoOpacity = parseFloat(input.value);
  updateLogoColor();

  // Update opacity label
  const label = globalThis.document.querySelector(
    '.opacity-value'
  ) as HTMLElement;
  if (label) {
    label.textContent = Math.round(logoOpacity * 100) + '%';
  }

  updatePreviews();
}

function updateLogoColor() {
  const titleElement = globalThis.document.querySelector(
    'h1.title'
  ) as HTMLElement;
  const chevron = globalThis.document.querySelector(
    'h1.title.broken'
  ) as HTMLElement;

  if (titleElement) {
    let r: number, g: number, b: number;

    if (customLogoColor) {
      // Use custom color
      r = parseInt(customLogoColor.slice(1, 3), 16);
      g = parseInt(customLogoColor.slice(3, 5), 16);
      b = parseInt(customLogoColor.slice(5, 7), 16);
    } else {
      // Use computed theme color
      const computedColor = globalThis
        .getComputedStyle(titleElement)
        .getPropertyValue('color');
      const match = computedColor.match(/^rgba?\((\d+),\s*(\d+),\s*(\d+)/);
      if (match && match[1] && match[2] && match[3]) {
        r = parseInt(match[1], 10);
        g = parseInt(match[2], 10);
        b = parseInt(match[3], 10);
      } else {
        // Fallback to purple
        r = 147;
        g = 51;
        b = 234;
      }
    }

    const color = `rgba(${r}, ${g}, ${b}, ${logoOpacity})`;
    titleElement.style.color = color;

    // Update the chevron ::before pseudo-element color via CSS variable
    if (chevron) {
      chevron.style.setProperty('--custom-logo-color', color);
    }
  }
}

function resetLogoColor() {
  const titleElement = globalThis.document.querySelector(
    'h1.title'
  ) as HTMLElement;
  const chevron = globalThis.document.querySelector(
    'h1.title.broken'
  ) as HTMLElement;

  customLogoColor = null;
  logoOpacity = 1;

  if (titleElement) {
    titleElement.style.color = '';
  }

  if (chevron) {
    chevron.style.removeProperty('--custom-logo-color');
  }

  // Reset inputs to current theme color
  const colorInput = globalThis.document.querySelector(
    '.logo-color-input'
  ) as HTMLInputElement;
  const opacityInput = globalThis.document.querySelector(
    '.logo-opacity-input'
  ) as HTMLInputElement;
  const opacityLabel = globalThis.document.querySelector(
    '.opacity-value'
  ) as HTMLElement;

  if (colorInput && titleElement) {
    // Get the computed color from the theme
    const computedColor = globalThis
      .getComputedStyle(titleElement)
      .getPropertyValue('color');
    // Convert rgb to hex
    const hex = rgbToHex(computedColor);
    colorInput.value = hex;
  }
  if (opacityInput) {
    opacityInput.value = '1';
  }
  if (opacityLabel) {
    opacityLabel.textContent = '100%';
  }

  updatePreviews();
}

function rgbToHex(rgb: string): string {
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

function initializeColorPicker() {
  const titleElement = globalThis.document.querySelector(
    'h1.title'
  ) as HTMLElement;
  const colorInput = globalThis.document.querySelector(
    '.logo-color-input'
  ) as HTMLInputElement;

  if (titleElement && colorInput) {
    // Get the computed color from the theme
    const computedColor = globalThis
      .getComputedStyle(titleElement)
      .getPropertyValue('color');
    // Convert rgb to hex
    const hex = rgbToHex(computedColor);
    colorInput.value = hex;
  }
}

const initColorPicker = modifier(() => {
  // Initialize color picker after a short delay to ensure DOM is ready
  globalThis.setTimeout(() => {
    initializeColorPicker();
    updatePreviews();
  }, 100);
});

// Get title color with opacity
function getTitleColor(): string {
  const logoElement = globalThis.document.querySelector(
    '.square-logo'
  ) as HTMLElement;
  const titleElement = logoElement?.querySelector('h1.title') as HTMLElement;
  const titleStyles = titleElement
    ? globalThis.getComputedStyle(titleElement)
    : null;

  let titleColor: string;
  if (customLogoColor) {
    const r = parseInt(customLogoColor.slice(1, 3), 16);
    const g = parseInt(customLogoColor.slice(3, 5), 16);
    const b = parseInt(customLogoColor.slice(5, 7), 16);
    titleColor = `rgba(${r}, ${g}, ${b}, ${logoOpacity})`;
  } else {
    const computedColor =
      titleStyles?.getPropertyValue('color') || 'rgb(147, 51, 234)';
    const match = computedColor.match(/^rgba?\((\d+),\s*(\d+),\s*(\d+)/);
    if (match && match[1] && match[2] && match[3]) {
      const r = parseInt(match[1], 10);
      const g = parseInt(match[2], 10);
      const b = parseInt(match[3], 10);
      titleColor = `rgba(${r}, ${g}, ${b}, ${logoOpacity})`;
    } else {
      titleColor = `rgba(147, 51, 234, ${logoOpacity})`;
    }
  }
  return titleColor;
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
}

// Generate SVG - shared by both preview and download
function generateSVG(size: number, titleColor: string): Promise<SVGSVGElement> {
  const svgNS = 'http://www.w3.org/2000/svg';
  const svg = globalThis.document.createElementNS(svgNS, 'svg');

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

  svg.setAttribute('width', boxWidth.toString());
  svg.setAttribute('height', boxHeight.toString());
  svg.setAttribute('xmlns', svgNS);

  // Add background
  const rect = globalThis.document.createElementNS(svgNS, 'rect');
  rect.setAttribute('width', size.toString());
  rect.setAttribute('height', size.toString());

  if (!useTransparentBackground) {
    const skyColor = globalThis
      .getComputedStyle(globalThis.document.documentElement)
      .getPropertyValue('--bg-sky')
      .trim();
    rect.setAttribute('fill', skyColor || '#f3e8ff');
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

  canvas.width = boxWidth * scale;
  canvas.height = boxHeight * scale;

  ctx.scale(scale, scale);

  // Draw background
  if (!useTransparentBackground) {
    const skyColor = globalThis
      .getComputedStyle(globalThis.document.documentElement)
      .getPropertyValue('--bg-sky')
      .trim();
    ctx.fillStyle = skyColor || '#f3e8ff';
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
  const previewContainer = globalThis.document.getElementById('svg-preview');
  if (!previewContainer) return;

  const size = 300;
  const titleColor = getTitleColor();

  if (!fitToContent) {
    previewContainer.classList.remove('fit-to-content');
  } else {
    previewContainer.classList.add('fit-to-content');
  }

  // Use shared SVG generation
  generateSVG(size, titleColor)
    .then((svg) => {
      previewContainer.innerHTML = '';
      previewContainer.appendChild(svg);
    })
    .catch(() => {
      previewContainer.innerHTML = '<p>Error generating preview</p>';
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

<template>
  {{pageTitle "Bandits | The Bay Area Trail Running Community"}}

  <section class="page">
    {{(initializeColorScheme)}}

    <div class="landscape-container">

      <div class="sky branding">
        <div class="square-logo">
          {{! template-lint-disable require-presentational-children }}
          <h1
            class="title broken"
            role="button"
            aria-roledescription="toggle color scheme"
            {{on "click" toggleColorScheme}}
          >Bay<br />Bandits</h1>
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
          <div class="opacity-control-group">
            <label for="logo-opacity">Opacity:
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
            {{on "click" resetLogoColor}}
          >
            Reset Color
          </button>
        </div>

        <div class="download-buttons">
          <button
            type="button"
            class="download-btn circle-toggle-btn"
            {{on "click" toggleCircleMask}}
          >
            Toggle Circle Mask
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
            Download as SVG
          </button>
          <button
            type="button"
            class="download-btn"
            {{on "click" downloadAsPNG}}
          >
            Download as PNG
          </button>
        </div>

        <div class="preview-section">
          <div class="preview-box">
            <h3>SVG Preview</h3>
            <div class="preview-container svg-preview" id="svg-preview"></div>
          </div>
          <div class="preview-box">
            <h3>PNG Preview</h3>
            <div class="preview-container png-preview">
              <canvas id="png-preview"></canvas>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>
