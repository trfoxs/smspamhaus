#!/bin/bash
# smSpamHaus installer
# Installs dependencies, ipset, firewall rule, systemd service and weekly cron.
# Run as root.

set -euo pipefail

INSTALL_DIR="/usr/local/sbin"
SCRIPT_NAME="smSpamHaus.sh"
SERVICE_NAME="smSpamHaus.service"
CRON_NAME="smSpamHaus"
SET="smSpamHaus"
LOG="/var/log/smSpamHaus.log"

SCRIPT_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/smSpamHaus.sh"
SERVICE_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/systemd/smSpamHaus.service"
CRON_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/cron/smSpamHaus"

if [ "$(id -u)" -ne 0 ]; then
    echo "HATA: install.sh root olarak çalıştırılmalıdır."
    exit 1
fi

echo "[1/8] Gerekli paketler kontrol ediliyor..."

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y curl jq ipset iptables

echo "[2/8] Dosyalar kuruluyor..."

install -m 0755 "$SCRIPT_SOURCE" "$INSTALL_DIR/$SCRIPT_NAME"
install -m 0644 "$SERVICE_SOURCE" "/etc/systemd/system/$SERVICE_NAME"
install -m 0644 "$CRON_SOURCE" "/etc/cron.d/$CRON_NAME"
touch "$LOG"
chmod 0644 "$LOG"

echo "[3/8] ipset hazırlanıyor..."

if ipset list -name | grep -qx "$SET"; then
    echo "     smSpamHaus ipset zaten mevcut."
else
    ipset create "$SET" hash:net family inet
    echo "     smSpamHaus ipset oluşturuldu."
fi

echo "[4/8] Firewall kuralı kontrol ediliyor..."

if iptables -C INPUT -m set --match-set "$SET" src -j DROP 2>/dev/null; then
    echo "     DROP kuralı zaten mevcut."
else
    iptables -I INPUT 1 -m set --match-set "$SET" src -j DROP
    echo "     DROP kuralı eklendi."
fi

echo "[5/8] systemd hazırlanıyor..."

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"

echo "[6/8] Haftalık cron hazırlanıyor..."

chmod 0644 "/etc/cron.d/$CRON_NAME"

if systemctl list-unit-files 2>/dev/null | grep -q '^cron.service'; then
    systemctl enable --now cron
fi

echo "[7/8] İlk Spamhaus güncellemesi yapılıyor..."

"$INSTALL_DIR/$SCRIPT_NAME"

echo "[8/8] Servis başlatılıyor..."

systemctl start "$SERVICE_NAME"

echo
echo "========================================"
echo " smSpamHaus kurulum tamamlandı"
echo "========================================"
echo
echo "ipset:"
ipset list "$SET" | grep -E 'Name:|Type:|Number of entries:'
echo
echo "iptables:"
iptables -C INPUT -m set --match-set "$SET" src -j DROP 2>/dev/null && echo "DROP kuralı aktif."
echo
echo "systemd:"
systemctl is-enabled "$SERVICE_NAME"
echo
echo "cron:"
cat "/etc/cron.d/$CRON_NAME"
echo
echo "Log:"
echo "$LOG"
echo
echo "Manuel güncelleme:"
echo "$INSTALL_DIR/$SCRIPT_NAME"
echo
