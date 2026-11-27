import { test, expect } from '@playwright/test';
import type { Locator } from '@playwright/test';
async function start(page: import('@playwright/test').Page, samples = true) {
  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'Let’s make a little friend' })).toBeVisible();
  await page.getByLabel('Buddy’s name').fill('Bubbles');
  await page.getByLabel('Your nickname').fill('PRIVATE NICKNAME');
  if (!samples) await page.getByRole('button', { name: 'Empty shelf', exact: true }).click();
  await page.getByRole('button', { name: 'Meet my happy shelf' }).click();
  await expect(page.getByRole('dialog')).not.toBeVisible();
}
test('makes a buddy and first toys without typing, then finds the grown-up gate', async ({ page, hasTouch }) => {
  const press = (target: Locator) => hasTouch ? target.tap() : target.click();
  const dialog = page.getByRole('dialog');
  await page.goto('/');
  await expect(dialog.getByRole('button', { name: 'Close', exact: true })).toHaveCount(0);
  const finishBuddy = dialog.getByRole('button', { name: 'Meet my happy shelf' });
  await expect(finishBuddy).toBeInViewport({ ratio: 1 });
  await press(dialog.getByRole('button', { name: 'Bunny', exact: true }));
  const mint = dialog.getByRole('button', { name: 'Mint', exact: true });
  expect((await mint.boundingBox())?.width).toBeGreaterThanOrEqual(44);
  expect((await mint.boundingBox())?.height).toBeGreaterThanOrEqual(44);
  await press(mint);
  await expect(mint).toHaveAttribute('aria-pressed', 'true');
  const emptyShelf = dialog.getByRole('button', { name: 'Empty shelf', exact: true });
  await expect(emptyShelf).toBeInViewport({ ratio: 1 });
  await press(emptyShelf.locator('svg').first());
  await expect(emptyShelf).toHaveAttribute('aria-pressed', 'true');
  await press(finishBuddy);
  await expect(dialog).not.toBeVisible();
  await expect(page.getByText('You + Pip')).toBeVisible();
  await expect(page.getByRole('article')).toHaveCount(0);

  const mobile = page.getByRole('navigation', { name: 'Mobile navigation' });
  const isMobile = await mobile.isVisible();
  const add = isMobile ? mobile.getByRole('button', { name: 'Add friend' }) : page.getByRole('button', { name: 'Add a little friend', exact: true });
  const share = isMobile ? mobile.getByRole('button', { name: 'Share', exact: true }) : page.getByRole('navigation', { name: 'Main' }).getByRole('button', { name: 'Share collection' });
  await expect(share).toBeInViewport({ ratio: 1 });
  expect((await share.boundingBox())?.height).toBeGreaterThanOrEqual(44);
  await expect(share).toBeDisabled();
  await press(add);
  const saveToy = dialog.getByRole('button', { name: 'Add to my shelf' });
  await expect(saveToy).toBeInViewport({ ratio: 1 });
  await press(dialog.getByRole('button', { name: 'Kitty', exact: true }));
  await expect(dialog.getByRole('button', { name: 'Kitty', exact: true })).toHaveAttribute('aria-pressed', 'true');
  await press(saveToy);
  const kitten = page.getByRole('button', { name: 'View Kitty' });
  await expect(kitten).toBeInViewport({ ratio: 1 });
  await expect(kitten).toBeFocused();
  await press(add);
  const fidget = dialog.getByRole('button', { name: 'Fidget', exact: true });
  await press(fidget);
  const spinner = dialog.getByRole('button', { name: 'Spinner', exact: true });
  await expect(spinner).toBeInViewport({ ratio: 1 });
  await press(spinner);
  await press(fidget);
  await expect(spinner).toHaveAttribute('aria-pressed', 'true');
  await press(saveToy);
  await expect(page.getByRole('button', { name: 'View Spinner' })).toBeInViewport({ ratio: 1 });
  await press(share);
  await expect(dialog.getByRole('heading', { name: 'A little help from a grown-up' })).toBeVisible();
  await expect(dialog.getByRole('img', { name: /Collection picture/ })).toHaveCount(0);
});
test('starts with seven pretend toys if the illustrated shelf choice is left alone', async ({ page, hasTouch }) => {
  await page.goto('/');
  const dialog = page.getByRole('dialog');
  await expect(dialog.getByRole('button', { name: '7 pretend toys', exact: true })).toHaveAttribute('aria-pressed', 'true');
  await expect(dialog.getByRole('button', { name: 'Empty shelf', exact: true })).toHaveAttribute('aria-pressed', 'false');
  const finish = dialog.getByRole('button', { name: 'Meet my happy shelf' });
  if (hasTouch) await finish.tap();
  else await finish.click();
  await expect(dialog).not.toBeVisible();
  await expect(page.getByRole('article')).toHaveCount(7);
});
test('scrolls and saves a buddy in a very short landscape viewport', async ({ page, hasTouch }) => {
  await page.setViewportSize({ width: 320, height: 160 });
  await page.goto('/');
  const dialog = page.getByRole('dialog');
  const finish = dialog.getByRole('button', { name: 'Meet my happy shelf' });
  await expect(dialog).toBeVisible();
  await expect(dialog).toHaveCSS('overflow-y', 'auto');
  await dialog.evaluate(sheet => { sheet.scrollTop = sheet.scrollHeight; });
  await expect(finish).toBeInViewport({ ratio: 1 });
  if (hasTouch) await finish.tap();
  else await finish.click();
  await expect(dialog).not.toBeVisible();
});
test('draws frog eyes above its face instead of bear ears', async ({ page }) => {
  await page.goto('/');
  const dialog = page.getByRole('dialog');
  const frog = dialog.getByRole('button', { name: 'Frog', exact: true });
  const bear = dialog.getByRole('button', { name: 'Bear', exact: true });
  const eyesAboveFace = 'svg ellipse[cy="55"]';
  await expect(frog.locator(eyesAboveFace)).toHaveCount(2);
  await expect(bear.locator(eyesAboveFace)).toHaveCount(0);
  await expect(frog.locator('svg circle')).toHaveCount(0);
  await expect(bear.locator('svg circle')).toHaveCount(2);
});
test('gives Other squishy different artwork from Mochi blob', async ({ page }) => {
  await start(page, false);
  await page.getByRole('button', { name: 'Add my first friend' }).click();
  const dialog = page.getByRole('dialog');
  const artwork = (name: string) => dialog.getByRole('button', { name, exact: true })
    .locator('svg path').evaluateAll(paths => paths.map(path => path.getAttribute('d')));
  const mochi = await artwork('Mochi blob');
  expect(mochi.length).toBeGreaterThan(0);
  expect(await artwork('Other squishy')).not.toEqual(mochi);
});

test('keeps buddy and toy drafts usable across iPad layout changes', async ({ page }) => {
  await page.setViewportSize({ width: 834, height: 1194 });
  await page.goto('/');
  const dialog = page.getByRole('dialog');
  await expect(dialog.getByRole('button', { name: 'Close' })).toHaveCount(0);
  await page.getByLabel('Buddy’s name').fill('Jellybean');
  await page.setViewportSize({ width: 320, height: 834 });
  await expect(page.getByLabel('Buddy’s name')).toHaveValue('Jellybean');
  await page.getByRole('button', { name: 'Meet my happy shelf' }).click();
  await expect(dialog).not.toBeVisible();

  const mobile = page.getByRole('navigation', { name: 'Mobile navigation' });
  await mobile.getByRole('button', { name: 'Add friend' }).click();
  await page.getByLabel('Toy name').fill('Mermaid Pop');
  await page.getByLabel('Private little notes').fill('Blue on the back');
  await page.setViewportSize({ width: 1194, height: 834 });
  await dialog.getByRole('button', { name: 'Fidget', exact: true }).click();
  await page.setViewportSize({ width: 507, height: 834 });
  await expect(page.getByLabel('Private little notes')).toHaveValue('Blue on the back');
  await expect(dialog.getByRole('button', { name: 'Fidget', exact: true })).toHaveAttribute('aria-pressed', 'true');
  await dialog.getByRole('button', { name: 'Add to my shelf' }).click();
  await expect(page.getByRole('button', { name: 'View Mermaid Pop' })).toBeVisible();

  for (const width of [1194, 981, 678, 507, 375, 320]) {
    await page.setViewportSize({ width, height: 834 });
    expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBe(width);
  }
  for (const target of [
    mobile.getByRole('button', { name: 'Add friend' }),
    page.getByRole('button', { name: 'Favorite Mermaid Pop' }),
    page.getByRole('button', { name: 'Favorites', exact: true }),
  ]) {
    const bounds = (await target.boundingBox())!;
    expect(bounds.width).toBeGreaterThanOrEqual(44);
    expect(bounds.height).toBeGreaterThanOrEqual(44);
  }
  await mobile.getByRole('button', { name: 'Add friend' }).click();
  const swatch = (await dialog.locator('.swatch').first().boundingBox())!;
  expect(swatch.width).toBeGreaterThanOrEqual(44);
  expect(swatch.height).toBeGreaterThanOrEqual(44);
});

test('keeps navigation, dialogs and poster actions inside available space', async ({ page }) => {
  await page.addInitScript(() => {
    Object.defineProperties(navigator, {
      canShare: { value: () => true },
      share: { value: async () => {} },
    });
  });
  await page.setViewportSize({ width: 320, height: 834 });
  await start(page);
  await page.addStyleTag({ content: ':root { --safe-top: 24px; --safe-right: 16px; --safe-bottom: 20px; --safe-left: 24px; }' });
  const mobile = page.getByRole('navigation', { name: 'Mobile navigation' });
  expect(await mobile.evaluate(el => getComputedStyle(el).paddingBottom)).toBe('29px');
  expect(await mobile.evaluate(el => getComputedStyle(el).paddingLeft)).toBe('34px');
  expect((await page.locator('.topbar').boundingBox())!.y).toBeGreaterThanOrEqual(24);
  await mobile.getByRole('button', { name: 'Share' }).click();
  const dialog = page.getByRole('dialog');
  const question = (await dialog.getByText(/Grown-ups: what is/).textContent())!.match(/(\d+) × (\d+)/)!;
  await dialog.getByRole('textbox').fill(String(Number(question[1]) * Number(question[2])));
  await dialog.getByRole('button', { name: 'Make collection picture' }).click();
  await expect(dialog.getByRole('img', { name: /Collection picture/ })).toBeVisible();
  const poster = dialog.getByRole('region', { name: 'Scrollable collection picture' });
  expect(await poster.evaluate(el => el.scrollWidth > el.clientWidth)).toBe(true);
  expect(await dialog.evaluate(el => el.scrollWidth <= el.clientWidth + 1)).toBe(true);
  await page.setViewportSize({ width: 1194, height: 500 });
  const bounds = (await dialog.boundingBox())!;
  expect(bounds.y).toBeGreaterThanOrEqual(24);
  expect(bounds.y + bounds.height).toBeLessThanOrEqual(480);
  expect(await dialog.evaluate(el => el.scrollHeight <= el.clientHeight + 1)).toBe(true);
  const size = await poster.getByRole('img').evaluate((image: HTMLImageElement) => ({
    width: image.getBoundingClientRect().width, height: image.getBoundingClientRect().height,
  }));
  expect(size.width).toBeGreaterThanOrEqual(560);
  expect(size.height).toBeGreaterThan((await poster.boundingBox())!.height);
  expect(await poster.evaluate(el => {
    el.scrollTop = el.scrollHeight;
    return el.scrollTop;
  })).toBeGreaterThan(0);
  await expect(dialog.getByRole('button', { name: 'Share picture' })).toBeInViewport();
  await expect(dialog.getByRole('link', { name: 'Save picture' })).toBeInViewport();
  await dialog.getByRole('button', { name: 'Close', exact: true }).click();
  const sidebar = page.locator('.sidebar');
  expect((await sidebar.boundingBox())!.x).toBe(24);
  const note = sidebar.getByRole('button', { name: /On this device/ });
  await note.scrollIntoViewIfNeeded();
  await expect(note).toBeInViewport();
  await note.click();
  await expect(dialog.getByRole('heading', { name: 'Your own little world' })).toBeVisible();
});

test('reopens the built shelf and saves a toy without a network connection', async ({ page, context }) => {
  await start(page, false);
  await page.waitForFunction(() => navigator.serviceWorker.controller !== null);
  await context.setOffline(true);
  await page.reload();
  await page.getByRole('button', { name: 'Add my first friend' }).click();
  await page.getByLabel('Toy name').fill('Offline friend');
  await page.getByRole('button', { name: 'Add to my shelf' }).click();
  await expect(page.getByRole('dialog')).not.toBeVisible();
  await page.reload();
  await expect(page.getByRole('button', { name: 'View Offline friend' })).toBeVisible();
  await page.getByRole('button', { name: 'Edit my buddy' }).click();
  await expect(page.getByLabel('Buddy’s name')).toHaveValue('Bubbles');
});
test('sets up a buddy, adds/edits/deletes toys and persists across reloads', async ({ page }) => {
  await start(page, false);
  await expect(page.getByRole('heading', { name: 'Your first little joy goes here' })).toBeVisible();
  await page.getByRole('button', { name: 'Add my first friend' }).click();
  await page.getByLabel('Toy name').fill('Cloud Nine');
  await page.getByLabel('Private little notes').fill('PRIVATE NOTE');
  await page.getByRole('button', { name: 'Soft', exact: true }).click();
  await page.getByRole('button', { name: 'Add to my shelf' }).click();
  await expect(page.getByRole('dialog')).not.toBeVisible();
  await page.reload();
  await expect(page.getByRole('button', { name: 'View Cloud Nine' })).toBeVisible();
  await page.getByRole('button', { name: 'Favorite Cloud Nine', exact: true }).click();
  await page.getByRole('button', { name: 'Favorites', exact: true }).click();
  await page.getByRole('searchbox').fill('soft');
  await expect(page.getByRole('button', { name: 'View Cloud Nine' })).toBeVisible();
  await page.getByRole('button', { name: 'View Cloud Nine' }).click();
  await expect(page.getByText('PRIVATE NOTE', { exact: true })).toBeVisible();
  await page.getByRole('button', { name: 'Edit little friend' }).click();
  await page.getByLabel('Toy name').fill('Cloud Ten');
  await page.getByRole('button', { name: 'Save changes' }).click();
  await page.getByRole('button', { name: 'View Cloud Ten' }).click();
  await page.getByRole('button', { name: 'Remove from my shelf' }).click();
  await page.getByRole('button', { name: 'Keep my friend' }).click();
  await expect(page.getByRole('heading', { name: 'Cloud Ten' })).toBeVisible();
  await page.getByRole('button', { name: 'Remove from my shelf' }).click();
  await page.getByRole('button', { name: 'Remove friend', exact: true }).click();
  await expect(page.getByRole('heading', { name: 'Your first little joy goes here' })).toBeVisible();
});
test('grown-up gate rejects a wrong answer and prepares a private PNG', async ({ page }) => {
  await start(page);
  const share = page.getByRole('navigation', { name: 'Mobile navigation' }).getByRole('button', { name: 'Share', exact: true });
  if (await share.isVisible()) await share.click();
  else await page.getByRole('button', { name: 'Share my collection', exact: true }).click();
  const dialog = page.getByRole('dialog');
  await dialog.getByRole('textbox').fill('0');
  await dialog.getByRole('button', { name: 'Make collection picture' }).click();
  await expect(dialog.getByRole('alert')).toContainText('Not quite');
  const question = await dialog.getByText(/Grown-ups: what is/).textContent();
  const numbers = question!.match(/(\d+) × (\d+)/)!;
  await dialog.getByRole('textbox').fill(String(Number(numbers[1]) * Number(numbers[2])));
  await dialog.getByRole('button', { name: 'Make collection picture' }).click();
  await expect(dialog.getByRole('img', { name: /Collection picture/ })).toBeVisible();
  const download = page.waitForEvent('download');
  await dialog.getByRole('link', { name: 'Save picture' }).click();
  expect((await download).suggestedFilename()).toBe('fidget-friends-1.png');
  await dialog.getByRole('button', { name: 'Close', exact: true }).click();
  if (await share.isVisible()) await share.click();
  else await page.getByRole('button', { name: 'Share my collection', exact: true }).click();
  await expect(page.getByRole('heading', { name: 'A little help from a grown-up' })).toBeVisible();
});
async function openShare(page: import('@playwright/test').Page) {
  const share = page.getByRole('navigation', { name: 'Mobile navigation' }).getByRole('button', { name: 'Share', exact: true });
  if (await share.isVisible()) await share.click();
  else await page.getByRole('button', { name: 'Share my collection', exact: true }).click();
  return page.getByRole('dialog');
}
async function makePicture(page: import('@playwright/test').Page) {
  const dialog = page.getByRole('dialog');
  const question = await dialog.getByText(/Grown-ups: what is/).textContent();
  const [, a, b] = question!.match(/(\d+) × (\d+)/)!;
  await dialog.getByRole('textbox').fill(String(Number(a) * Number(b)));
  await dialog.getByRole('button', { name: 'Make collection picture' }).click();
  await expect(dialog.getByRole('img', { name: /Collection picture/ })).toBeVisible();
}
for (const scenario of ['missing share', 'missing canShare', 'files unsupported'] as const) {
  test(`offers only Save picture when ${scenario}`, async ({ page }) => {
    await page.addInitScript(scenario => {
      Object.defineProperties(navigator, {
        share: { value: scenario === 'missing share' ? undefined : async () => {} },
        canShare: { value: scenario === 'missing canShare' ? undefined : () => scenario !== 'files unsupported' },
      });
    }, scenario);
    await start(page);
    const dialog = await openShare(page);
    await makePicture(page);
    await expect(dialog.getByRole('button', { name: 'Share picture' })).toHaveCount(0);
    const save = dialog.getByRole('link', { name: 'Save picture' });
    await expect(save).toHaveClass(/\bprimary\b/);
    const download = page.waitForEvent('download');
    await save.click();
    expect((await download).suggestedFilename()).toBe('fidget-friends-1.png');
  });
}
test('clears a share error when a grown-up retries successfully', async ({ page }) => {
  await page.addInitScript(() => {
    let calls = 0;
    Object.defineProperties(navigator, {
      canShare: { value: () => true },
      share: { value: async () => {
        if (++calls === 1) throw new DOMException('Denied for this test', 'NotAllowedError');
        return new Promise<void>(resolve => document.addEventListener('finish-share', () => {
          document.body.dataset.shareFinished = 'yes';
          resolve();
        }, { once: true }));
      } },
    });
  });
  await start(page);
  const dialog = await openShare(page);
  await makePicture(page);
  const share = dialog.getByRole('button', { name: 'Share picture' });
  await share.click();
  await expect(dialog.getByRole('alert')).toContainText('Sharing is unavailable here');
  await expect(dialog.getByRole('link', { name: 'Save picture' })).toBeVisible();
  await share.click();
  await expect(dialog.getByRole('alert')).toHaveCount(0);
  await page.evaluate(() => document.dispatchEvent(new Event('finish-share')));
  await expect(page.locator('body')).toHaveAttribute('data-share-finished', 'yes');
  await expect(dialog.getByRole('alert')).toHaveCount(0);
});
test('does not count blank grown-up answers or change the question', async ({ page }) => {
  await start(page);
  const dialog = await openShare(page);
  const question = dialog.getByText(/Grown-ups: what is/);
  const input = dialog.getByRole('textbox');
  const submit = dialog.getByRole('button', { name: 'Make collection picture' });
  const initial = await question.textContent();
  for (const blank of ['', ' ', '']) {
    await input.fill(blank);
    await submit.click();
    await expect(question).toHaveText(initial!);
    await expect(dialog.getByRole('alert')).toHaveCount(0);
    await expect(submit).toBeEnabled();
  }
  for (let miss = 0; miss < 2; miss++) {
    await input.fill('0');
    await submit.click();
    await expect(submit).toBeEnabled();
  }
  await makePicture(page);
});
test('locks the grown-up gate for 30 seconds after three wrong answers', async ({ page }) => {
  const now = new Date('2026-01-01T12:00:00Z');
  await page.clock.install({ time: now });
  await page.clock.pauseAt(new Date(now.getTime() + 1_000));
  await start(page);
  const dialog = await openShare(page);
  const question = dialog.getByText(/Grown-ups: what is/);
  const input = dialog.getByRole('textbox');
  const submit = dialog.getByRole('button', { name: 'Make collection picture' });
  for (let miss = 1; miss <= 3; miss++) {
    const previous = await question.textContent();
    await expect(submit).toBeEnabled();
    await input.fill('0');
    await submit.click();
    await expect(question).not.toHaveText(previous!);
  }
  await expect(dialog.getByRole('status')).toContainText('Grown-ups, please wait 30 seconds');
  await expect(input).toBeDisabled();
  await expect(submit).toBeDisabled();
  await expect(dialog.getByRole('img', { name: /Collection picture/ })).toHaveCount(0);
  await dialog.getByRole('button', { name: 'Close', exact: true }).click();
  await openShare(page);
  await page.clock.fastForward(29_999);
  await expect(submit).toBeDisabled();
  await page.clock.fastForward(1);
  await expect(submit).toBeEnabled();
  await expect(dialog.getByRole('status')).toHaveCount(0);
  await input.fill('0');
  await submit.click();
  await expect(submit).toBeEnabled();
  await makePicture(page);
});
test('has no horizontal overflow and loads no third-party resources', async ({ page }) => {
  const external: string[] = [];
  page.on('request', request => { if (/^https?:/.test(request.url()) && new URL(request.url()).hostname !== '127.0.0.1') external.push(request.url()); });
  await start(page);
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
  await page.getByRole('searchbox').fill('no such friend');
  await expect(page.getByRole('heading', { name: 'No little friends found' })).toBeVisible();
  expect(external).toEqual([]);
});
test('a poster keeps a maximum-width toy name inside its tile', async ({ page }) => {
  await start(page, false);
  await page.getByRole('button', { name: 'Add my first friend' }).click();
  await page.getByLabel('Toy name').fill('W'.repeat(40));
  await page.getByRole('button', { name: 'Add to my shelf' }).click();
  await expect(page.getByRole('dialog')).not.toBeVisible();

  const share = page.getByRole('navigation', { name: 'Mobile navigation' }).getByRole('button', { name: 'Share', exact: true });
  if (await share.isVisible()) await share.click();
  else await page.getByRole('button', { name: 'Share my collection', exact: true }).click();
  const dialog = page.getByRole('dialog');
  const question = await dialog.getByText(/Grown-ups: what is/).textContent();
  const numbers = question!.match(/(\d+) × (\d+)/)!;
  await dialog.getByRole('textbox').fill(String(Number(numbers[1]) * Number(numbers[2])));
  await dialog.getByRole('button', { name: 'Make collection picture' }).click();

  const bounds = await dialog.getByRole('img', { name: /Collection picture/ }).evaluate(async (image: HTMLImageElement) => {
    await image.decode();
    const canvas = document.createElement('canvas');
    canvas.width = image.naturalWidth;
    canvas.height = image.naturalHeight;
    const ctx = canvas.getContext('2d')!;
    ctx.drawImage(image, 0, 0);
    const pixels = ctx.getImageData(0, 434, canvas.width, 56).data;
    let left = canvas.width, right = -1;
    for (let i = 0; i < pixels.length; i += 4) {
      if (pixels[i] !== 0x35 || pixels[i + 1] !== 0x25 || pixels[i + 2] !== 0x4f) continue;
      const x = (i / 4) % canvas.width;
      left = Math.min(left, x);
      right = Math.max(right, x);
    }
    return { left, right };
  });
  expect(bounds.right).toBeGreaterThan(bounds.left);
  expect(bounds.left).toBeGreaterThanOrEqual(48);
  expect(bounds.right).toBeLessThan(364);
});
test('a stale second tab cannot erase a newly added friend', async ({ page, context }) => {
  await start(page, false);
  const other = await context.newPage();
  await other.goto('/');
  await expect(other.getByRole('heading', { name: 'Your first little joy goes here' })).toBeVisible();
  await page.getByRole('button', { name: 'Add my first friend' }).click();
  await page.getByLabel('Toy name').fill('Keep me');
  await page.getByRole('button', { name: 'Add to my shelf' }).click();
  await expect(page.getByRole('dialog')).not.toBeVisible();
  await other.getByRole('button', { name: 'Add my first friend' }).click();
  await other.getByLabel('Toy name').fill('Stale addition');
  await other.getByRole('button', { name: 'Add to my shelf' }).click();
  await expect(other.getByRole('dialog').getByRole('alert')).toContainText('changed in another tab');
  await page.reload();
  await expect(page.getByRole('button', { name: 'View Keep me' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'View Stale addition' })).toHaveCount(0);
});
test('an extremely narrow local photo stays valid after reload', async ({ page }) => {
  await start(page, false);
  await page.getByRole('button', { name: 'Add my first friend' }).click();
  await page.getByLabel('Toy name').fill('Tiny photo');
  const image = await page.evaluate(() => { const canvas = document.createElement('canvas'); canvas.width = 1; canvas.height = 3000; const ctx = canvas.getContext('2d')!; ctx.fillStyle = '#ffaaaa'; ctx.fillRect(0, 0, 1, 3000); return canvas.toDataURL('image/png').split(',')[1]; });
  await page.locator('input[type=file]').setInputFiles({ name: 'narrow.png', mimeType: 'image/png', buffer: Buffer.from(image, 'base64') });
  await expect(page.getByRole('img', { name: 'Your toy preview' })).toBeVisible();
  await page.getByRole('button', { name: 'Add to my shelf' }).click();
  await expect(page.getByRole('dialog')).not.toBeVisible();
  await page.reload();
  await page.getByRole('button', { name: 'View Tiny photo' }).click();
  await expect(page.getByRole('dialog').getByRole('img', { name: 'Tiny photo' })).toBeVisible();
});
