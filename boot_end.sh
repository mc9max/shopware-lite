#!/bin/sh
# boot_end.sh — executed by dockware's entrypoint on every boot, after MySQL
# and Apache are up and the shop domain has been rewritten, just before the
# container is marked ready. Runs as the dockware user (passwordless sudo
# available).
set -e

SHOP_DOMAIN="${SHOP_DOMAIN:-localhost}"

# Every boot: force https on sales-channel domains. Railway terminates TLS at
# its proxy and forwards plain HTTP to the container, so the shop must serve
# its canonical https:// URLs to avoid mixed-content and redirect issues.
mysql -h127.0.0.1 -uroot -proot shopware \
  -e "UPDATE sales_channel_domain SET url = REPLACE(url, 'http://', 'https://');" 2>/dev/null \
  || echo "RAILWAY: note: sales-channel https rewrite skipped (DB not ready?)"

# Every boot: keep APP_URL accurate (dockware blanks the old line and appends
# a new one per boot; normalize to a single correct entry).
sed -i '/^APP_URL=/d' /var/www/html/.env
echo "APP_URL=https://${SHOP_DOMAIN}" >> /var/www/html/.env

# First boot only: production mode, admin credential rotation, prod cache.
if ! sudo test -f /var/lib/mysql/.railway-ready; then
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

  sudo touch /var/lib/mysql/.railway-ready
  echo "RAILWAY: first boot complete."
fi
