import { test, expect } from '@playwright/test';
async function start(page: import('@playwright/test').Page, samples = true) {
  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'Let’s make a little friend' })).toBeVisible();
  await page.getByLabel('Buddy’s name').fill('Bubbles');
  await page.getByLabel('Your nickname').fill('PRIVATE NICKNAME');
  if (!samples) await page.getByLabel('Start with 7 pretend toys').uncheck();
  await page.getByRole('button', { name: 'Meet my happy shelf' }).click();
  await expect(page.getByRole('dialog')).not.toBeVisible();
}
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
