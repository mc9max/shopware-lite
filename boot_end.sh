#!/bin/sh
# boot_end.sh — executed by dockware's entrypoint on every boot, after MySQL
# and Apache are up and the shop domain has been rewritten, just before the
# container is marked ready. Runs as the dockware user (passwordless sudo
# available).
set -e

SHOP_DOMAIN="${SHOP_DOMAIN:-localhost}"

# Every boot: drop plain-http sales-channel domains that already have an https
# twin. Railway terminates TLS at its proxy, so the shop must serve canonical
# https:// URLs. (An UPDATE would hit the UNIQUE key on url, since the https
# twin already exists — hence DELETE of the redundant http rows.)
mysql -h127.0.0.1 -uroot -proot shopware -e \
  "DELETE h FROM sales_channel_domain h JOIN sales_channel_domain s ON s.url = REPLACE(h.url, 'http://', 'https://') WHERE h.url LIKE 'http://%';" \
  || echo "RAILWAY: warning: sales-channel http cleanup skipped (DB not ready?)"

# Every boot: keep APP_URL accurate (dockware blanks the old line and appends
# a new one per boot; normalize to a single correct entry).
sed -i '/^APP_URL=/d' /var/www/html/.env
echo "APP_URL=https://${SHOP_DOMAIN}" >> /var/www/html/.env

# Every boot: export TRUSTED_PROXIES via .env. PHP-FPM clears the container
# environment, so Symfony can't see the real TRUSTED_PROXIES variable;
# Dotenv makes it visible so %env(TRUSTED_PROXIES)% in config/packages/
# railway.yaml resolves.
TP="${TRUSTED_PROXIES:-127.0.0.1,10.0.0.0/8}"
sed -i '/^TRUSTED_PROXIES=/d' /var/www/html/.env
echo "TRUSTED_PROXIES=${TP}" >> /var/www/html/.env

# Every boot (idempotent): relocate the web data dirs onto the /data volume.
# On first boot the upstream entrypoint has just unpacked the Shopware tarball
# into /var/www/html; move that content into the volume once, then symlink so
# the app keeps working across redeploys.
for spec in "public/media media" "files files" "public/theme theme" "public/thumbnail thumbnail" "public/sitemap sitemap"; do
  # shellcheck disable=SC2086
  set -- $spec
  rel="$1"; name="$2"
  link="/var/www/html/$rel"
  if [ ! -L "$link" ]; then
    if [ -d "$link" ]; then
      if [ -z "$(ls -A "/data/$name" 2>/dev/null || true)" ]; then
        echo "RAILWAY: moving $rel into the volume (first boot)..."
        sudo cp -a "$link/." "/data/$name/"
      fi
      rm -rf "$link"
    fi
    ln -s "/data/$name" "$link"
  fi
done
sudo chown -R 33:33 /data/media /data/files /data/theme /data/thumbnail /data/sitemap

# First boot only: production mode, admin credential rotation, prod cache.
if ! sudo test -f /data/.railway-ready; then
  echo "RAILWAY: first boot — finalizing Shopware installation..."

  # The image ships APP_ENV=dev; a marketplace template should run prod.
  sed -i 's/^APP_ENV=dev$/APP_ENV=prod/' /var/www/html/.env

  # Rotate the well-known default admin login (admin/shopware) to the
  # generated secret from the template variables.
  if [ -n "${SHOPWARE_ADMIN_PASSWORD:-}" ]; then
    HASH=$(SHOPWARE_ADMIN_PASSWORD="$SHOPWARE_ADMIN_PASSWORD" \
      php -r 'echo password_hash(getenv("SHOPWARE_ADMIN_PASSWORD"), PASSWORD_BCRYPT), "\n";')
    mysql -h127.0.0.1 -uroot -proot shopware \
      -e "UPDATE \`user\` SET password='${HASH}' WHERE username='admin';"
    echo "RAILWAY: admin password rotated to the generated secret."
  else
    echo "RAILWAY: warning: SHOPWARE_ADMIN_PASSWORD not set; default admin/shopware login unchanged."
  fi

  # Warm the production cache now so the first visitor doesn't pay for it.
  php /var/www/html/bin/console cache:clear --no-interaction

  sudo touch /data/.railway-ready
  echo "RAILWAY: first boot complete."
fi
