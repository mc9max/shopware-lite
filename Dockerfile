# syntax=docker/dockerfile:1
# =============================================================================
# Railway Template: Shopware  (v1)
# Upstream: https://www.shopware.com  (MIT) — Shopware 6 open-source e-commerce
# Image:    dockware/shopware:6.7.15.1-amd64@sha256:fcf31b8567c7d36aaa6af4cbc8ae7e86bfe383d7a1d126feb6d21089ec27aa1f
#           (pinned 2026-10-13 — Shopware 6.7.15.1, image built 2026-10-12;
#            dockware/shopware repo is MIT-licensed, maintained by dasistweb)
# =============================================================================
# Why this wrapper:
#   * Upstream ends with USER dockware (uid 33). Railway mounts persistent
#     volumes root-owned, so the entrypoint starts as root: it prepares the
#     /data volume and remaps Apache's port, then drops to the dockware user
#     (via gosu, which the image ships) to run the upstream entrypoint
#     exactly as designed.
#   * Railway services take a single volume, mounted here at /data. The image
#     ships a fully installed Shopware 6 (with demo data) plus its MySQL 8
#     datadir INSIDE the image at /var/lib/mysql, so the entrypoint relocates
#     the datadir to /data/mysql (via my.cnf) and seed-copies the prebuilt
#     database there on first boot. Web data dirs (media/files/theme/
#     thumbnail/sitemap) are moved into /data on first boot and symlinked back
#     into the docroot (Apache follows symlinks), so uploads survive redeploys.
#   * Upstream Apache listens on port 80. The wrapper rewrites it to Railway's
#     injected PORT (default 8080) before the upstream entrypoint starts Apache.
#   * Upstream's SHOP_DOMAIN env rewrites sales-channel URLs on boot; the
#     wrapper forces https (Railway terminates TLS at the proxy), rotates the
#     well-known default admin password (admin/shopware) to a generated secret
#     on first boot, and switches APP_ENV to prod.
#   * No in-container HEALTHCHECK override — the base already ships an
#     accurate file-based one (/var/www/container.launched); Railway's
#     external healthcheck (healthcheckPath="/") runs instead.
#   * Never hardcode PORT: Railway injects its own PORT env at runtime
#     (default 8080), which overrides any Dockerfile ENV.
FROM dockware/shopware:6.7.15.1-amd64@sha256:fcf31b8567c7d36aaa6af4cbc8ae7e86bfe383d7a1d126feb6d21089ec27aa1f

USER root

# Seed copy of the pre-installed MySQL datadir (MySQL was shut down cleanly at
# image build time). The entrypoint copies this into the /var/lib/mysql volume
# on first boot, when the volume is still empty.
RUN mkdir -p /seed/mysql && cp -a /var/lib/mysql/. /seed/mysql/

COPY --chmod=0755 docker-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
COPY --chmod=0755 boot_end.sh /var/www/boot_end.sh

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]

LABEL org.opencontainers.image.source="https://github.com/mc9max/shopware-lite"
LABEL org.opencontainers.image.description="Shopware 6 Railway template"
