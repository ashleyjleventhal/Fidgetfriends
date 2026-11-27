import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { defineConfig } from 'vite';

export default defineConfig({
  base: './',
  build: { target: 'safari17' },
  plugins: [{
    name: 'offline-app-shell',
    apply: 'build',
    generateBundle: {
      order: 'post',
      handler(_, bundle) {
        const publicFiles = ['manifest.webmanifest', 'icon.svg', 'apple-touch-icon.png', 'icon-192.png', 'icon-512.png'];
        const worker = readFileSync(new URL('./service-worker.js', import.meta.url), 'utf8');
        const hash = createHash('sha256').update(worker);
        for (const file of publicFiles) hash.update(readFileSync(new URL(`./public/${file}`, import.meta.url)));
        for (const output of Object.values(bundle)) {
          hash.update(output.fileName);
          hash.update(output.type === 'chunk' ? output.code : output.source);
        }
        const files = [...publicFiles, ...Object.keys(bundle)];
        this.emitFile({
          type: 'asset',
          fileName: 'sw.js',
          source: `const version = ${JSON.stringify(hash.digest('hex'))};\nconst files = ${JSON.stringify(files)};\n${worker}`,
        });
      },
    },
  }],
});
