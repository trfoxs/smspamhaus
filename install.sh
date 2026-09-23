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
    echo "ERROR: install.sh must be run as root."
    exit 1
fi

echo "[1/8] Checking required packages..."

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y curl jq ipset iptables

echo "[2/8] Installing files..."

install -m 0755 "$SCRIPT_SOURCE" "$INSTALL_DIR/$SCRIPT_NAME"
install -m 0644 "$SERVICE_SOURCE" "/etc/systemd/system/$SERVICE_NAME"
install -m 0644 "$CRON_SOURCE" "/etc/cron.d/$CRON_NAME"
touch "$LOG"
chmod 0644 "$LOG"

echo "[3/8] Preparing ipset..."

if ipset list -name | grep -qx "$SET"; then
    echo "     smSpamHaus ipset already exists."
else
    ipset create "$SET" hash:net family inet
    echo "     smSpamHaus ipset created."
fi

echo "[4/8] Checking firewall rule..."

if iptables -C INPUT -m set --match-set "$SET" src -j DROP 2>/dev/null; then
    echo "     DROP rule already exists."
else
    iptables -I INPUT 1 -m set --match-set "$SET" src -j DROP
    echo "     DROP rule added."
fi

echo "[5/8] Preparing systemd..."

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"

echo "[6/8] Preparing weekly cron..."

chmod 0644 "/etc/cron.d/$CRON_NAME"

if systemctl list-unit-files 2>/dev/null | grep -q '^cron.service'; then
    systemctl enable --now cron
fi

echo "[7/8] Running the initial Spamhaus update..."

"$INSTALL_DIR/$SCRIPT_NAME"

echo "[8/8] Starting the service..."

systemctl start "$SERVICE_NAME"

echo
echo "========================================"
echo " smSpamHaus installation completed"
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
echo "Manual update:"
echo "$INSTALL_DIR/$SCRIPT_NAME"
echo
