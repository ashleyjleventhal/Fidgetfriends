const scope = self.registration.scope;
const entry = new URL('index.html', scope).href;
const assets = new Set(files.map(file => new URL(file, scope).href));
const cachePrefix = `fidget-friends:${scope}:`;
const cacheName = cachePrefix + version;

self.addEventListener('install', event => {
  event.waitUntil(caches.open(cacheName).then(cache =>
    cache.addAll([...assets].map(url => new Request(url, { cache: 'reload' })))
  ));
});

self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys
    .filter(key => key.startsWith(cachePrefix) && key !== cacheName)
    .map(key => caches.delete(key))
  )).then(() => self.clients.claim()));
});

self.addEventListener('fetch', event => {
  const { request } = event;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  const location = url.origin + url.pathname;
  const isAppNavigation = request.mode === 'navigate' && (location === scope || location === entry);
  if (!isAppNavigation && !assets.has(request.url)) return;
  event.respondWith(caches.open(cacheName).then(async cache =>
    (await cache.match(isAppNavigation ? entry : request, { ignoreVary: true })) ?? fetch(request)
  ));
});
