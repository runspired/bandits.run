import { readdir, readFile, writeFile } from 'node:fs/promises';
import { join, extname } from 'node:path';
import { brotliCompress, constants } from 'node:zlib';
import { promisify } from 'node:util';

const compress = promisify(brotliCompress);

// File extensions to compress
const COMPRESSIBLE_EXTENSIONS = new Set([
  '.js',
  '.mjs',
  '.css',
  '.html',
  '.json',
  '.svg',
  '.xml',
  '.txt',
  '.manifest',
  '.ttf',
  '.eot',
]);

// Minimum file size to compress (bytes)
const MIN_SIZE = 256; // 256 B

async function compressFile(filePath: string): Promise<void> {
  let content = await readFile(filePath);
  const originalSize = content.length;

  // Skip files that are too small
  if (content.length < MIN_SIZE) {
    return;
  }

  // Minify JSON files before compression
  if (filePath.endsWith('.json')) {
    try {
      const parsed = JSON.parse(content.toString('utf-8'));
      const minified = JSON.stringify(parsed);
      content = Buffer.from(minified, 'utf-8');

      if (content.length < originalSize) {
        // Overwrite the original file with minified version
        await writeFile(filePath, content);
      }
    } catch (error) {
      // If JSON parsing fails, continue with original content
      console.warn(`⚠️  Could not minify ${filePath}: ${error}`);
    }
  }

  // Compress with max level (11)
  const compressed = await compress(content, {
    params: {
      [constants.BROTLI_PARAM_QUALITY]: constants.BROTLI_MAX_QUALITY,
      [constants.BROTLI_PARAM_MODE]: constants.BROTLI_MODE_TEXT,
    },
  });

  // Write .br file
  await writeFile(`${filePath}.br`, compressed);

  const savings = ((1 - compressed.length / originalSize) * 100).toFixed(1);
  console.log(`✓ ${filePath} (${originalSize} → ${compressed.length} bytes, ${savings}% savings)`);
}

async function walkDirectory(dir: string): Promise<void> {
  const entries = await readdir(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = join(dir, entry.name);

    if (entry.isDirectory()) {
      await walkDirectory(fullPath);
    } else if (entry.isFile()) {
      const ext = extname(entry.name);
      if (COMPRESSIBLE_EXTENSIONS.has(ext)) {
        await compressFile(fullPath);
      }
    }
  }
}

async function main() {
  const distDir = join(process.cwd(), 'dist');

  console.log('🗜️  Compressing static assets with Brotli (level 11)...\n');

  const startTime = Date.now();
  await walkDirectory(distDir);
  const duration = ((Date.now() - startTime) / 1000).toFixed(2);

  console.log(`\n✅ Compression complete in ${duration}s`);
}

main().catch((error) => {
  console.error('Error compressing assets:', error);
  process.exit(1);
});
