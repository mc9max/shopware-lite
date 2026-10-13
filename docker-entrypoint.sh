#!/bin/bash
# Railway wrapper entrypoint for the dockware/shopware image.
# Runs as root: remaps Apache to Railway's PORT and seeds the MySQL datadir
# volume on first boot, then hands off to the upstream entrypoint as the
# dockware user (via gosu), exactly as the image was designed to run.
set -e

# Railway injects PORT at runtime (default 8080). Upstream Apache listens on
# port 80 (ports.conf + the <VirtualHost *:80> vhost); rewrite both.
PORT="${PORT:-8080}"
if [ "$PORT" != "80" ]; then
  sed -i "s/^Listen 80$/Listen ${PORT}/" /etc/apache2/ports.conf
  sed -i "s|<VirtualHost \*:80>|<VirtualHost *:${PORT}>|" /etc/apache2/sites-enabled/000-default.conf
  echo "RAILWAY: Apache remapped from port 80 to ${PORT}"
fi

# First boot only: the image ships a fully installed Shopware database in
# /var/lib/mysql, but the Railway volume mounted there starts empty and would
# shadow it. Seed-copy the image's datadir into the volume.
if [ ! -f /var/lib/mysql/ibdata1 ] && [ -f /seed/mysql/ibdata1 ]; then
  echo "RAILWAY: seeding MySQL datadir into empty volume (first boot)..."
  cp -a /seed/mysql/. /var/lib/mysql/
  echo "RAILWAY: MySQL datadir seeded."
fi

# Drop to the dockware user and run the upstream entrypoint as designed
# (it uses passwordless sudo internally for the privileged steps).
exec gosu dockware /bin/bash /entrypoint.sh "$@"
