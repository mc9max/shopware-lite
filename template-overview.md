# Deploy and Host Shopware with Railway

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.com/deploy/shopware-latest)

Shopware is the open-source e-commerce platform for running your own online store: storefront, product catalog, cart and checkout, promotions, and a full admin backend. This template deploys Shopware 6.7 with demo data pre-installed — your shop is browsable seconds after the first boot finishes.

## About Hosting Shopware

This template deploys Shopware as a single Railway service from a pinned image (`dockware/shopware:6.7.15.1`, Shopware 6.7.15.1, MIT-licensed): PHP 8.2 + Apache + MySQL 8 in one container, no external database to manage. One Railway volume mounted at `/data` holds the MySQL datadir plus media, files, theme, thumbnail, and sitemap directories, so products, orders, customers, and uploads survive redeploys. On boot the wrapper remaps Apache to Railway's `PORT`, rewrites sales-channel URLs to your public domain (https enforced), rotates the default admin password to a generated secret, and warms the production cache. Cron runs Shopware's scheduled tasks and message-queue workers every minute.

## Why Deploy

- **Stores can't sleep.** A shop that takes orders is the canonical always-on workload — steady compute around the clock.
- **One container, zero database to babysit.** MySQL 8 rides inside the service; nothing external to wire, secure, or pay for separately.
- **Demo data included.** Sample products and categories ship in the image, so the full shopping experience is evaluable immediately.
- **Full commerce stack.** Catalog, promotions, checkout, customer accounts, Rule Builder, plus the Shopware Store plugin ecosystem and Store/Admin APIs for headless builds.

## Common Use Cases

- **Online store** — catalog, cart, and checkout live in minutes.
- **Headless commerce** — Store API and Admin API as the backend for a custom frontend.
- **Staging clone** — a full Shopware copy for testing plugins and theme changes.
- **Agency demos** — one-click demo shops for client pitches.

## Dependencies for Shopware Hosting

- **Railway account** (Hobby or higher; 2 GB RAM recommended — Shopware + MySQL together want headroom).
- **One `/data` volume** provisioned automatically (MySQL datadir + media/files/theme/thumbnail/sitemap).
- **A public domain** — generate one in Railway; the shop rewrites its sales-channel URLs to it on every boot.
- **Upstream image** `dockware/shopware:6.7.15.1-amd64`, pinned by digest (Shopware is MIT-licensed; the dockware/shopware image repo is MIT-licensed).

### Deployment Dependencies

- Source repository `https://github.com/mc9max/shopware-lite` (Dockerfile wrapper: pinned digest, runs the entrypoint as root to seed the root-owned MySQL volume, remaps Apache to Railway's `PORT`, rotates the default admin credentials on first boot).
- Railway-provided `PORT` (default 8080) — the wrapper follows it automatically.
- Template variables: `SHOPWARE_ADMIN_PASSWORD` (auto-generated secret), `SHOP_DOMAIN` (auto-filled from `RAILWAY_PUBLIC_DOMAIN`), `SW_TASKS_ENABLED=1`, `SW_CURRENCY`, `TZ` — all defaulted, nothing to configure.
- [Railway health checks](https://docs.railway.com/guides/healthchecks) on `/`.
- [Template best practices](https://docs.railway.com/templates/best-practices)
