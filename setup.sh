#!/bin/bash
set -e
cd "$(dirname "$0")"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   CrossFit Tracker — VPS Setup       ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── 1. Dependencies ────────────────────────────────────────────────────────
echo "[1/6] Installing dependencies..."
apt-get update -qq
apt-get install -y -qq nginx certbot python3-certbot-nginx python3 python3-pip
pip3 install flask --break-system-packages -q
echo "      ✓ Done"

# ── 2. Files ───────────────────────────────────────────────────────────────
echo "[2/6] Copying files..."
mkdir -p /var/www/crossfit
cp server.py     /var/www/crossfit/server.py
cp index.html    /var/www/crossfit/index.html
touch /var/www/crossfit/data.json
echo "{}" > /var/www/crossfit/data.json
echo "      ✓ Done"

# ── 3. API key ─────────────────────────────────────────────────────────────
echo "[3/6] Generating API key..."
API_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(24))")
sed -i "s/CF_SECRET_KEY_PLACEHOLDER/$API_KEY/g" /var/www/crossfit/server.py
sed -i "s/CF_SECRET_KEY_PLACEHOLDER/$API_KEY/g" /var/www/crossfit/index.html
echo "      ✓ Key embedded in both files"

# ── 4. Permissions ─────────────────────────────────────────────────────────
chown -R www-data:www-data /var/www/crossfit
chmod 755 /var/www/crossfit
chmod 644 /var/www/crossfit/server.py /var/www/crossfit/index.html
chmod 664 /var/www/crossfit/data.json

# ── 5. Nginx ───────────────────────────────────────────────────────────────
echo "[4/6] Configuring nginx..."
cp crossfit.nginx.conf /etc/nginx/sites-available/crossfit.lpconsultings.com
ln -sf /etc/nginx/sites-available/crossfit.lpconsultings.com \
       /etc/nginx/sites-enabled/crossfit.lpconsultings.com
nginx -t
systemctl reload nginx
echo "      ✓ Done"

# ── 6. Systemd ─────────────────────────────────────────────────────────────
echo "[5/6] Starting Flask service..."
cp crossfit-tracker.service /etc/systemd/system/crossfit-tracker.service
systemctl daemon-reload
systemctl enable crossfit-tracker
systemctl restart crossfit-tracker
sleep 2
if systemctl is-active --quiet crossfit-tracker; then
  echo "      ✓ Service running"
else
  echo "      ✗ Service failed — check: journalctl -u crossfit-tracker"
  exit 1
fi

# ── 7. SSL ─────────────────────────────────────────────────────────────────
echo "[6/6] Setting up SSL..."
echo ""
echo "      Enter your email for Let's Encrypt:"
read -r EMAIL
certbot --nginx -d crossfit.lpconsultings.com \
        --non-interactive --agree-tos -m "$EMAIL" --redirect
echo "      ✓ HTTPS enabled"

# ── Done ───────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════╗"
echo "║   Setup complete!                    ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "  URL  →  https://crossfit.lpconsultings.com"
echo ""
echo "  Useful commands:"
echo "    systemctl status crossfit-tracker"
echo "    journalctl -u crossfit-tracker -f"
echo "    systemctl restart crossfit-tracker"
echo ""
