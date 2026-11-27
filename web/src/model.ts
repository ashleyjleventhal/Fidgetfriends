export const colors = { grape: ['Grape', '#b99ae9', '#ece2fa'], bubblegum: ['Bubblegum', '#f5a9c6', '#fce4ee'], tangerine: ['Tangerine', '#f9b16c', '#ffead6'], sunshine: ['Sunshine', '#f5d76d', '#fff3c7'], mint: ['Mint', '#8cd6b0', '#def4e7'], sky: ['Sky', '#94cbed', '#e3f1fb'], coral: ['Coral', '#f3a195', '#ffe5df'], rainbow: ['Rainbow', '#ba9be9', '#eee6fb'] } as const;
export type Color = keyof typeof colors;
export const species = { blob: 'Mochi blob', cat: 'Kitty', bunny: 'Bunny', bear: 'Bear', frog: 'Frog', axolotl: 'Axolotl', star: 'Star', popIt: 'Pop-it', cube: 'Fidget cube', spinner: 'Spinner', otherSquishy: 'Other squishy', otherFidget: 'Other fidget' } as const;
export type Species = keyof typeof species;
export const buddySpecies: Species[] = ['blob', 'cat', 'bunny', 'bear', 'frog', 'axolotl', 'star'];
export const fidgetSpecies: Species[] = ['popIt', 'cube', 'spinner', 'otherFidget'];
export const tags = ['Soft', 'Slow-rise', 'Squeezy', 'Stretchy', 'Clicky', 'Poppy', 'Sparkly', 'Smells yummy', 'Glows'];
export type Look = { species: Species; color: Color; eyes: 'sparkle' | 'dots' | 'happy' | 'sleepy' | 'wink'; accessory: 'none' | 'crown' | 'bow' | 'partyHat'; cheeks: boolean };
export type Profile = { nickname: string; buddyName: string; look: Look };
export type Item = { id: string; name: string; kind: 'squishy' | 'fidget'; species: Species; color: Color; tags: string[]; notes: string; favorite: boolean; photo?: string; createdAt: number };
export type Collection = { version: 1; profile: Profile | null; items: Item[] };
export type Filter = 'all' | 'squishy' | 'fidget' | 'favorite';
export const defaultLook: Look = { species: 'blob', color: 'grape', eyes: 'sparkle', accessory: 'crown', cheeks: true };
export const emptyCollection: Collection = { version: 1, profile: null, items: [] };
export function newItem(): Item { return { id: crypto.randomUUID(), name: '', kind: 'squishy', species: 'blob', color: 'bubblegum', tags: [], notes: '', favorite: false, createdAt: Date.now() }; }
export function filteredItems(items: Item[], filter: Filter, query: string): Item[] {
  const normalize = (s: string) => s.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLocaleLowerCase();
  const q = normalize(query.trim());
  return items.filter(i => (filter === 'all' || (filter === 'favorite' ? i.favorite : i.kind === filter)) && normalize([i.name, i.kind, species[i.species], i.notes, ...i.tags].join(' ')).includes(q));
}
export function sampleItems(): Item[] {
  return [
    { name: 'Peachy', species: 'axolotl', color: 'bubblegum', kind: 'squishy', tags: ['Soft', 'Slow-rise'], favorite: true },
    { name: 'Rainbow Pop', species: 'popIt', color: 'rainbow', kind: 'fidget', tags: ['Poppy', 'Clicky'] },
    { name: 'Mochi', species: 'cat', color: 'tangerine', kind: 'squishy', tags: ['Squeezy'] },
    { name: 'Pickles', species: 'frog', color: 'mint', kind: 'squishy', tags: ['Stretchy'], favorite: true },
    { name: 'Sunny', species: 'star', color: 'sunshine', kind: 'squishy', tags: ['Sparkly', 'Glows'] },
    { name: 'Blue Bean', species: 'bunny', color: 'sky', kind: 'squishy', tags: ['Soft', 'Smells yummy'] },
    { name: 'Clicky Cube', species: 'cube', color: 'grape', kind: 'fidget', tags: ['Clicky'] },
  ].map(i => ({ ...newItem(), ...i }) as Item);
}
// Sharing is an explicit allowlist. Photos, notes, nickname and buddy name never enter a poster.
export function publicItems(items: Item[]) { return items.map(({ name, species, color, kind }) => ({ name, species, color, kind })); }
export function isCollection(value: unknown): value is Collection {
  if (!value || typeof value !== 'object') return false;
  const c = value as Collection;
  const validLook = (l: Look) => l && buddySpecies.includes(l.species) && l.color in colors && ['sparkle', 'dots', 'happy', 'sleepy', 'wink'].includes(l.eyes) && ['none', 'crown', 'bow', 'partyHat'].includes(l.accessory) && typeof l.cheeks === 'boolean';
  return c.version === 1 && (c.profile === null || (typeof c.profile?.nickname === 'string' && typeof c.profile?.buddyName === 'string' && validLook(c.profile.look))) && Array.isArray(c.items) && c.items.every(i => i && typeof i.id === 'string' && typeof i.name === 'string' && i.species in species && i.color in colors && ['squishy', 'fidget'].includes(i.kind) && typeof i.notes === 'string' && typeof i.favorite === 'boolean' && Number.isFinite(i.createdAt) && Array.isArray(i.tags) && i.tags.every(t => tags.includes(t)) && (i.photo === undefined || /^data:image\/(jpeg|png|webp);base64,/.test(i.photo)));
}
