import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import type { Page } from '@playwright/test';

async function finishSetup(page: Page, samples = true) {
  if (!samples) await page.getByLabel('Start with 7 pretend toys').uncheck();
  await page.getByRole('button', { name: 'Meet my happy shelf' }).click();
  await expect(page.getByRole('dialog')).not.toBeVisible();
}
async function expectNoSeriousA11yIssues(page: Page) {
  const { violations } = await new AxeBuilder({ page }).analyze();
  expect(violations.filter(v => v.impact === 'serious' || v.impact === 'critical').map(v => `${v.id}: ${v.nodes.map(n => n.target.join(' ')).join(', ')}`)).toEqual([]);
}
async function openAdd(page: Page) {
  await page.locator('.add-card').click();
  await expect(page.getByRole('dialog', { name: 'A new little friend' })).toBeVisible();
}

test('setup, shelf, editor and empty shelf have readable contrast and matching names', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'Let’s make a little friend' })).toBeVisible();
  await expectNoSeriousA11yIssues(page);
  await finishSetup(page);
  await expect(page.getByRole('button', { name: 'Edit my buddy: Hello, friend You + Pip' })).toBeVisible();
  await expectNoSeriousA11yIssues(page);
  await openAdd(page);
  await expectNoSeriousA11yIssues(page);
});

test('empty shelf has no serious accessibility issues', async ({ page }) => {
  await page.goto('/');
  await finishSetup(page, false);
  await expect(page.getByRole('heading', { name: 'Your first little joy goes here' })).toBeVisible();
  await expectNoSeriousA11yIssues(page);
});

test('reloading in the middle of setup keeps the choices made so far', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: 'Kitty' }).click();
  await page.getByLabel('Buddy’s name').fill('Whiskers');
  await page.getByLabel('Start with 7 pretend toys').uncheck();
  await page.reload();
  await expect(page.getByLabel('Buddy’s name')).toHaveValue('Whiskers');
  await expect(page.getByRole('button', { name: 'Kitty' })).toHaveAttribute('aria-pressed', 'true');
  await expect(page.getByLabel('Start with 7 pretend toys')).not.toBeChecked();
  await page.getByRole('button', { name: 'Meet my happy shelf' }).click();
  await expect(page.getByText('You + Whiskers')).toBeVisible();
  await expect(page.getByRole('heading', { name: 'Your first little joy goes here' })).toBeVisible();
  expect(await page.evaluate(() => sessionStorage.length)).toBe(0);
});

test('emoji names are limited by whole emoji, not split in half', async ({ page }) => {
  await page.goto('/');
  await finishSetup(page);
  await openAdd(page);
  const family = '👨‍👩‍👧‍👦';
  await page.getByLabel('Toy name').fill(family.repeat(45));
  await expect(page.getByLabel('Toy name')).toHaveValue(family.repeat(40));
});

test('very large text scales the app without sideways scrolling', async ({ page }) => {
  await page.goto('/');
  await finishSetup(page);
  const heading = page.getByRole('heading', { level: 1, name: 'My happy shelf' });
  const normal = await heading.evaluate(e => parseFloat(getComputedStyle(e).fontSize));
  await page.evaluate(() => { document.documentElement.style.fontSize = '53px'; });
  expect(await heading.evaluate(e => parseFloat(getComputedStyle(e).fontSize))).toBeGreaterThan(normal * 2);
  expect(await page.evaluate(() => document.documentElement.scrollWidth - innerWidth)).toBeLessThanOrEqual(0);
  await openAdd(page);
  expect(await page.evaluate(() => document.documentElement.scrollWidth - innerWidth)).toBeLessThanOrEqual(0);
});

test('buddy editor fits without sideways scrolling at very large text', async ({ page }) => {
  await page.goto('/');
  await finishSetup(page);
  await page.evaluate(() => { document.documentElement.style.fontSize = '53px'; });
  await page.getByRole('button', { name: /Edit my buddy/ }).filter({ visible: true }).first().click();
  const dialog = page.getByRole('dialog');
  await expect(dialog.getByRole('button', { name: 'Kitty' })).toBeVisible();
  expect(await dialog.getByRole('button', { name: 'Kitty' }).locator('span').last().evaluate(e => parseFloat(getComputedStyle(e).fontSize))).toBeGreaterThan(30);
  expect(await dialog.evaluate(e => e.scrollWidth - e.clientWidth)).toBeLessThanOrEqual(0);
});

test('saved messages are announced through a live region that is already on the page', async ({ page }) => {
  await page.goto('/');
  await finishSetup(page);
  const region = page.locator('[role="status"][aria-live="polite"]');
  await expect(region).toHaveCount(1);
  await page.getByRole('button', { name: /^Favorite / }).first().click();
  await expect(region).toContainText('A favorite little friend!');
});
