// Offline support for MAZE DINO.
// Pages are fetched from the network first so updates arrive as soon as you are online;
// the cached copy is used only when the network is not available.
const CACHE = 'mdd-maze-v1';
const PREFIX = 'mdd-maze-';
const ASSETS = ["./", "./index.html", "./manifest.webmanifest", "./manifest-kids.webmanifest", "./icon-192.png", "./icon-512.png", "./assets/maze-dino-logo.jpg", "./favicon.ico"];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE)
      .then(c => Promise.allSettled(ASSETS.map(a => c.add(a))))   // a missing optional file never blocks install
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k.startsWith(PREFIX) && k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== location.origin) return;            // wallets, RPC calls, Etherscan: never touched

  if (req.mode === 'navigate') {
    e.respondWith(
      fetch(req)
        .then(res => { if (res.ok) { const copy = res.clone(); caches.open(CACHE).then(c => c.put('./index.html', copy)); } return res; })
        .catch(() => caches.match('./index.html'))
    );
    return;
  }

  e.respondWith(
    caches.match(req).then(hit => hit || fetch(req).then(res => {
      if (res.ok) { const copy = res.clone(); caches.open(CACHE).then(c => c.put(req, copy)); }
      return res;
    }))
  );
});
