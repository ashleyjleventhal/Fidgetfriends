const version = "75f80c26feda4d102dc977253fa3837501a4fd9f14774840c326da9766868f74";
const files = ["manifest.webmanifest","icon.svg","apple-touch-icon.png","icon-192.png","icon-512.png","assets/nunito-latin-700-normal-Dort48En.woff2","assets/nunito-latin-900-normal-BVB1fGs6.woff2","assets/nunito-latin-400-normal-r8SDr6Up.woff2","assets/nunito-latin-800-normal-Dz8SOQK_.woff2","assets/nunito-latin-600-normal-Br8yIETf.woff2","assets/nunito-latin-400-normal-DKg4f3fz.woff","assets/nunito-latin-900-normal-CVn49sIn.woff","assets/nunito-latin-700-normal-OcDqTBcA.woff","assets/nunito-latin-800-normal-D-J0wlBY.woff","assets/nunito-latin-600-normal-Cd0eNu1l.woff","assets/index-DNxzFCuh.css","assets/index-Bkd8WIBL.js","index.html"];
const scope = self.registration.scope;
const entry = new URL('index.html', scope).href;
const generatedAssets = new URL('assets/', scope).href;
const assets = new Set(files.map(file => new URL(file, scope).href));
const cachePrefix = `fidget-friends:${scope}:`;
const cacheName = cachePrefix + version;

async function olderCaches() {
  const versions = (await caches.keys()).filter(key => key.startsWith(cachePrefix));
  const current = versions.indexOf(cacheName);
  return current < 0 ? [] : versions.slice(0, current);
}

self.addEventListener('install', event => {
  event.waitUntil(caches.open(cacheName).then(cache =>
    cache.addAll([...assets].map(url => new Request(url, { cache: 'reload' })))
  ).catch(async error => {
    await caches.delete(cacheName);
    throw error;
  }).then(() => self.skipWaiting()));
});

self.addEventListener('activate', event => {
  event.waitUntil(olderCaches().then(keys =>
    Promise.all(keys.slice(0, -1).map(key => caches.delete(key)))
  ).then(() => self.clients.claim()));
});

self.addEventListener('fetch', event => {
  const { request } = event;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  const location = url.origin + url.pathname;
  const isAppNavigation = request.mode === 'navigate' && (location === scope || location === entry);
  const isGeneratedAsset = request.url.startsWith(generatedAssets);
  if (!isAppNavigation && !assets.has(request.url) && !isGeneratedAsset) return;
  event.respondWith((async () => {
    const options = { ignoreVary: true };
    const current = await caches.open(cacheName);
    const cached = await current.match(isAppNavigation ? entry : request, options);
    if (cached) return cached;
    if (isGeneratedAsset) {
      const previous = (await olderCaches()).at(-1);
      if (previous) {
        const cachedPrevious = await (await caches.open(previous)).match(request, options);
        if (cachedPrevious) return cachedPrevious;
      }
    }
    return fetch(request);
  })());
});
