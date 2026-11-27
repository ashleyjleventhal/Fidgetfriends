import { once } from 'node:events';
import { readFile } from 'node:fs/promises';
import { createServer } from 'node:http';
import { test, expect } from '@playwright/test';

test('uses a new offline shell on reload even with a draft open in another tab', async ({ page, context }) => {
  const base = '/Fidgetfriends/';
  const dist = new URL('../dist/', import.meta.url);
  const files = new Set(await readFile(new URL('sw.js', dist), 'utf8')
    .then(worker => JSON.parse(worker.match(/^const files = (.*);$/m)![1]) as string[]));
  const mediaTypes: Record<string, string> = { html: 'text/html', js: 'text/javascript', css: 'text/css' };
  let release = 1;
  const server = createServer(async (request, response) => {
    const pathname = new URL(request.url!, 'http://localhost').pathname;
    const file = pathname.slice(base.length) || 'index.html';
    const releaseAsset = `assets/release-${release}.js`;
    response.setHeader('Cache-Control', 'no-store');
    if (pathname.startsWith(base) && (files.has(file) || file === 'sw.js' || file === releaseAsset)) {
      response.setHeader('Content-Type', mediaTypes[file.split('.').at(-1)!] ?? 'application/octet-stream');
      try {
        if (file === releaseAsset) response.end(`/* Release ${release} */`);
        else if (file === 'index.html') {
          const html = await readFile(new URL(file, dist), 'utf8');
          response.end(html.replace(/<title>.*?<\/title>/, `<title>Release ${release}</title>`));
        } else if (file === 'sw.js') {
          const worker = await readFile(new URL(file, dist), 'utf8');
          response.end(worker.replace(/^const version = .*;$/m, `const version = "${release}";`)
            .replace(/^const files = .*;$/m, `const files = ${JSON.stringify([...files, releaseAsset])};`));
        } else response.end(await readFile(new URL(file, dist)));
      } catch {
        response.writeHead(500).end();
      }
    } else response.writeHead(404).end();
  });

  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  const address = server.address();
  if (!address || typeof address === 'string') throw new Error('Could not start the app server');
  const url = `http://127.0.0.1:${address.port}${base}`;
  try {
    await page.goto(url);
    await expect(page).toHaveTitle('Release 1');
    await page.getByLabel('Buddy’s name').fill('Unfinished buddy');
    await page.waitForFunction(() => !!navigator.serviceWorker.controller);
    const other = await context.newPage();
    await other.goto(url);
    await expect(other).toHaveTitle('Release 1');

    release = 2;
    await page.evaluate(async () => {
      const registration = await navigator.serviceWorker.ready;
      const updated = new Promise<void>(resolve => navigator.serviceWorker.addEventListener('controllerchange', () => resolve(), { once: true }));
      await registration.update();
      await updated;
    });
    await other.reload();
    await expect(other).toHaveTitle('Release 2');
    await expect(page.getByLabel('Buddy’s name')).toHaveValue('Unfinished buddy');

    await context.setOffline(true);
    expect(await page.evaluate(async () => (await fetch('assets/release-1.js')).text())).toBe('/* Release 1 */');
    await other.reload();
    await expect(other).toHaveTitle('Release 2');
    await expect(other.getByLabel('Buddy’s name')).toBeVisible();
  } finally {
    server.close();
    server.closeAllConnections();
  }
});
