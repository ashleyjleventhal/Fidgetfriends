import { test } from 'node:test';
import assert from 'node:assert/strict';
import { filteredItems, isCollection, limitText, publicItems, shortName } from '../src/model.ts';
import type { Item } from '../src/model.ts';
const item: Item = { id: 'one', name: 'Péachy', species: 'axolotl', color: 'bubblegum', kind: 'squishy', notes: 'PRIVATE birthday note', photo: 'data:image/jpeg;base64,PRIVATE', tags: ['Soft'], favorite: true, createdAt: 1 };
test('sharing is an allowlist and does not leak photos or notes', () => {
  assert.deepEqual(publicItems([item]), [{ name: 'Péachy', species: 'axolotl', color: 'bubblegum', kind: 'squishy' }]);
  assert.ok(!JSON.stringify(publicItems([item])).includes('PRIVATE'));
});
test('filters intersect with case/diacritic-insensitive search across tags and notes', () => {
  assert.equal(filteredItems([item], 'favorite', 'peachy').length, 1);
  assert.equal(filteredItems([item], 'squishy', ' soft ').length, 1);
  assert.equal(filteredItems([item], 'all', 'birthday').length, 1);
  assert.equal(filteredItems([item], 'fidget', '').length, 0);
  assert.equal(filteredItems([item], 'all', 'missing').length, 0);
});
test('invalid saved data is rejected instead of silently overwritten', () => {
  const collection = { version: 1, profile: null, items: [item] };
  assert.equal(isCollection(collection), true);
  assert.equal(isCollection({ ...collection, version: 9 }), false);
  assert.equal(isCollection({ ...collection, items: [{ ...item, color: 'invalid' }] }), false);
  assert.equal(isCollection({ ...collection, items: [{ ...item, photo: 'https://external.example/photo' }] }), false);
  assert.equal(isCollection({ ...collection, profile: { nickname: 'Secret', buddyName: 'Pip', look: null } }), false);
});
test('name limits count whole emoji instead of splitting them', () => {
  const family = '👨‍👩‍👧‍👦';
  assert.equal(limitText(family.repeat(41), 40), family.repeat(40));
  assert.equal(limitText('Peachy 🦄', 40), 'Peachy 🦄');
  assert.equal(shortName(`${'🦄'.repeat(19)}${family}${family}`, 20), `${'🦄'.repeat(19)}${family}…`);
  assert.equal(shortName('Mochi', 20), 'Mochi');
});
test('typing past a limit drops the new text, never the text already there', () => {
  assert.equal(limitText('abXYcd', 5, 'abcd'), 'abXcd');
  assert.equal(limitText('abXYZcd', 4, 'abcd'), 'abcd');
  assert.equal(limitText('ab🦄🌈cd', 5, 'abcd'), 'ab🦄cd');
  assert.equal(limitText('abcdef', 4, ''), 'abcd');
});
