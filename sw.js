/* Service worker de Diana Score: guarda la app para usarla sin conexión. */
const CACHE = "diana-score-v6";
const SHELL = [
  "./", "./index.html", "./manifest.webmanifest",
  "./icons/icon-192.png", "./icons/icon-512.png", "./icons/icon-512-maskable.png",
  "./apple-touch-icon.png"
];

self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys()
      .then((ks) => Promise.all(ks.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (e) => {
  const req = e.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);
  if (url.origin !== location.origin) return;

  // La página (navegación): busca SIEMPRE la última versión en la red (saltándose la caché
  // del navegador) y, si no hay conexión, sirve la copia guardada.
  if (req.mode === "navigate") {
    e.respondWith(
      fetch(req, { cache: "reload" })
        .then((r) => { const cp = r.clone(); caches.open(CACHE).then((c) => c.put("./index.html", cp)); return r; })
        .catch(() => caches.match("./index.html").then((r) => r || caches.match("./")))
    );
    return;
  }

  // Resto de archivos: caché primero, y si no está, red (y se guarda).
  e.respondWith(
    caches.match(req).then((c) => c || fetch(req).then((r) => {
      const cp = r.clone(); caches.open(CACHE).then((cc) => cc.put(req, cp)); return r;
    }))
  );
});
