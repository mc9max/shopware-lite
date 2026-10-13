# Shopware

The open-source e-commerce platform for building your own online store — storefront, product catalog, checkout, and admin backend, all self-hosted. This template deploys Shopware 6.7 with demo data pre-installed, so your shop is browsable seconds after the first boot.

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.com/deploy/shopware-latest?utm_campaign=shopware-lite)

> The deploy URL slug above is finalized after the template is published; the button always points at the live marketplace listing.

# Deploy and Host

One click. Railway provisions a single service (Shopware + MySQL 8 in one container) with six persistent volumes and starts your shop. The admin password is auto-generated per deployment — find it in the service variables (`SHOPWARE_ADMIN_PASSWORD`), then open `https://<your-domain>/admin` and log in as `admin`.

- **Runtime** — PHP 8.4 + Apache + MySQL 8, single container (pinned `dockware/shopware:6.7.15.1` image, Shopware 6.7.15.1, MIT-licensed).
- **Memory** — ~1 GB at rest; give the service 2 GB for comfortable headroom. Fits Railway Hobby.
- **Port** — Railway's injected `PORT` (default 8080); the wrapper remaps Apache from port 80 automatically.
- **Persistence** — MySQL datadir plus media, files, theme, thumbnail, and sitemap directories live on volumes. Survives redeploys and restarts.
- **Public URL** — attach/generate a Railway domain; sales-channel URLs and `APP_URL` are rewritten to it on every boot (https enforced — Railway terminates TLS at the proxy).
- **Workers** — `SW_TASKS_ENABLED=1` runs Shopware's scheduled tasks and message-queue consumers via cron every minute (order flows, index updates, mail).

## Why Deploy

- **Real stores stay online.** A shop that takes orders can't sleep — this is the canonical always-on workload.
- **One container, zero database to manage.** MySQL 8 rides inside the service; no companion database to wire or pay for separately.
- **Demo data included.** The storefront ships with sample products and categories, so you can evaluate the full shopping experience before adding your catalog.
- **Full commerce stack.** Product management, promotions, checkout, customer accounts, and the Rule Builder — plus the Shopware Store plugin ecosystem.

## Common Use Cases

- **Online store** — launch a storefront with catalog, cart, and checkout in minutes.
- **Headless commerce** — use the Store API / Admin API as the backend for a custom frontend.
- **Staging clone** — spin up a full Shopware copy to test plugins and theme changes.
- **Agency demos** — one-click demo shops for client pitches.

### Deployment Dependencies

- **Railway Hobby or above** — 2 GB RAM recommended.
- **Six volumes** (provisioned automatically): `shopware-mysql`, `shopware-media`, `shopware-files`, `shopware-theme`, `shopware-thumbnail`, `shopware-sitemap`.
- **A public domain** — generate one in Railway; the shop rewrites its URLs to it on boot.

## First-run setup

1. Deploy and wait for the service to go green (first boot takes a few minutes: the shop files unpack and caches warm).
2. Open the public URL — the demo storefront should render.
3. Go to `/admin`, log in as `admin` with the generated `SHOPWARE_ADMIN_PASSWORD` from the service variables.
4. Change the shop name, currency, and sales-channel settings; add your products; configure a mailer (Settings → Mailer) so order emails actually send — outbound mail defaults to a local catcher.

## Troubleshooting

- **Storefront shows the wrong domain / redirect loop** — the shop rewrites its sales-channel URLs to `SHOP_DOMAIN` on every boot. Make sure a Railway domain is attached; `SHOP_DOMAIN` defaults to `${{RAILWAY_PUBLIC_DOMAIN}}`.
- **First boot is slow** — expected: ~3–6 minutes while MySQL seeds, the shop unpacks, and production caches build. Later boots are ~1–2 minutes.
- **Admin login fails** — use username `admin` and the `SHOPWARE_ADMIN_PASSWORD` value from the service variables (the public default `admin/shopware` is rotated on first boot). If you redeployed without the volume, the marker resets and the password is re-rotated to the current variable value.
- **Out of memory** — bump the service to 2 GB+; Shopware + MySQL together want headroom.

## License

Upstream [Shopware](https://www.shopware.com) is MIT-licensed; the [dockware/shopware](https://github.com/dockware/shopware) base image repo is MIT-licensed. This template's wrapper Dockerfile, entrypoint, and config are provided as-is.
