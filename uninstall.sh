#!/bin/bash
set -u

INSTALL_DIR="/usr/local/sbin"
SCRIPT_NAME="smSpamHaus.sh"
SERVICE_NAME="smSpamHaus.service"
CRON_NAME="smSpamHaus"
SET="smSpamHaus"
TMP_SET="${SET}_new"
LOG="/var/log/smSpamHaus.log"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: uninstall.sh must be run as root."
    exit 1
fi

echo "[1/6] Stopping and disabling smSpamHaus..."
systemctl disable --now "$SERVICE_NAME" 2>/dev/null || true
systemctl daemon-reload 2>/dev/null || true

echo "[2/6] Removing cron job..."
rm -f "/etc/cron.d/$CRON_NAME"

echo "[3/6] Removing only smSpamHaus iptables rule(s)..."
while iptables -C INPUT -m set --match-set "$SET" src -j DROP 2>/dev/null; do
    iptables -D INPUT -m set --match-set "$SET" src -j DROP 2>/dev/null || break
done

echo "[4/6] Removing only smSpamHaus ipsets..."
for S in "$TMP_SET" "$SET"; do
    if ipset list -name 2>/dev/null | grep -qx "$S"; then
        ipset destroy "$S" 2>/dev/null || {
            ipset flush "$S" 2>/dev/null || true
            ipset destroy "$S" 2>/dev/null || true
        }
    fi
done

echo "[5/6] Removing installed files..."
rm -f "$INSTALL_DIR/$SCRIPT_NAME"
rm -f "/etc/systemd/system/$SERVICE_NAME"
systemctl daemon-reload 2>/dev/null || true

echo "[6/6] Removing project log..."
rm -f "$LOG"

echo "smSpamHaus uninstalled. Plesk Firewall and Fail2Ban were not stopped or restarted."
