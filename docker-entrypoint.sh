#!/bin/bash
# Railway wrapper entrypoint for the dockware/shopware image.
# Runs as root: remaps Apache to Railway's PORT, prepares the single /data
# volume (MySQL datadir relocation + seed), then hands off to the upstream
# entrypoint as the dockware user (via gosu), exactly as the image was
# designed to run.
set -e

# Railway injects PORT at runtime (default 8080). Upstream Apache listens on
# port 80 (ports.conf + the <VirtualHost *:80> vhost); rewrite both.
PORT="${PORT:-8080}"
if [ "$PORT" != "80" ]; then
  sed -i "s/^Listen 80$/Listen ${PORT}/" /etc/apache2/ports.conf
  sed -i "s|<VirtualHost \*:80>|<VirtualHost *:${PORT}>|" /etc/apache2/sites-enabled/000-default.conf
  echo "RAILWAY: Apache remapped from port 80 to ${PORT}"
fi

# Railway terminates TLS at its edge proxy and forwards plain HTTP without an
# X-Forwarded-Proto header, so PHP would see every request as http:// and
# Shopware could never match the https:// sales-channel domain. Force HTTPS
# for all requests: the public URL is always https on Railway.
if ! grep -q "SetEnv HTTPS on" /etc/apache2/sites-enabled/000-default.conf; then
  sed -i "s|<VirtualHost \*:${PORT}>|<VirtualHost *:${PORT}>\n    SetEnv HTTPS on|" /etc/apache2/sites-enabled/000-default.conf
  echo "RAILWAY: forcing HTTPS in Apache vhost (TLS is terminated at Railway's proxy)"
fi

# Single-volume layout: everything persistent lives under /data.
mkdir -p /data/mysql /data/media /data/files /data/theme /data/thumbnail /data/sitemap
# The upstream entrypoint chowns this path on boot; keep it (now unused by
# MySQL itself) so that step keeps working.
mkdir -p /var/lib/mysql

# Relocate the MySQL datadir onto the volume. The image's my.cnf points at
# /var/lib/mysql, but the Railway volume is mounted at /data.
if grep -q '^datadir *= /var/lib/mysql' /etc/mysql/my.cnf; then
  sed -i 's|^datadir *= /var/lib/mysql|datadir = /data/mysql|' /etc/mysql/my.cnf
  echo "RAILWAY: MySQL datadir relocated to /data/mysql"
fi

# First boot only: the image ships a fully installed Shopware database; seed
# it into the volume (an empty volume would otherwise mean an empty shop).
if [ ! -f /data/mysql/ibdata1 ] && [ -f /seed/mysql/ibdata1 ]; then
  echo "RAILWAY: seeding MySQL datadir into empty volume (first boot)..."
  cp -a /seed/mysql/. /data/mysql/
  echo "RAILWAY: MySQL datadir seeded."
fi
chown -R mysql:mysql /data/mysql

# Drop to the dockware user and run the upstream entrypoint as designed
# (it uses passwordless sudo internally for the privileged steps).
exec gosu dockware /bin/bash /entrypoint.sh "$@"
