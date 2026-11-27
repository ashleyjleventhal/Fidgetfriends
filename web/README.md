# Fidget Friends for Safari

An independent, local-only web companion to the native iOS app. No native app files or Xcode settings are changed.

## Develop

Use Node 24 LTS. No pre-commit hooks are configured in this repository.

```sh
cd web
npm ci
npm run dev
```

`npm run build` checks TypeScript and produces `dist/`. `npm run preview` serves the production build. Deploy only `web/dist/` to any static HTTPS host. Vite uses relative asset paths, so the same build works under GitHub Pages' repository subpath or a custom domain.

## Checks

```sh
npm test
npm run build
npx playwright install --with-deps chromium webkit
npm run test:ui
```

UI coverage uses a fresh browser context for every test, with iPhone and iPad viewports and both Chromium and WebKit. WebKit automation is not a substitute for testing Safari's actual iOS home-screen installation and OS share sheet on an Apple device.

## Privacy and storage

- One collection in IndexedDB, local to this origin, browser and device. No API, analytics, remote fonts, account or collection uploads.
- Save failures are visible; state changes only after the database transaction succeeds. A failed load does not overwrite stored data.
- Photos are resized locally to 1000px and stripped of original file metadata through canvas re-encoding. HEIC support depends on the browser; JPG/PNG are portable.
- Poster data uses an explicit allowlist: toy names, kind, shape and color only. Nickname, buddy name, notes, and photos are excluded. Grown-ups should check toy names for identifying information. The multiplication check is a speed bump, not identity or age verification.
- Posters paginate at 12 toys each; every page can be saved or shared. Web Share is invoked from a separate user tap after PNG preparation, preserving Safari's transient user activation. Unsupported browsers can save the PNG instead.
- Clearing website data or deleting the home-screen app can erase collections. Private Browsing is not durable. Safari and standalone home-screen storage may differ; there is no device sync or native-app migration.

## Install on iPhone or iPad

Open the public HTTPS link in Safari, tap **Share → Add to Home Screen → Add**. Launch from the icon before building your real collection. Manifest, standalone metadata, and local PNG icons are included. This first version requires a network connection to load; no offline cache/service worker is installed.

## Hosting

The `web-checks` workflow checks pull requests. `publish-web` runs on web changes merged to main, or can be manually dispatched against a chosen branch after the workflow reaches main. It updates the existing `gh-pages` branch with only the built static directory. Pages uses **Deploy from a branch → gh-pages → / (root)**. The first deployment bootstraps that branch with the same `dist/` output. Never change repository visibility from a script; the owner controls it.
