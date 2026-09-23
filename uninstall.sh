#!/bin/bash
# smSpamHaus uninstaller
# Removes the smSpamHaus service, cron job, script, ipset and firewall rule.
# Dependencies such as curl, jq, ipset and iptables are intentionally NOT removed.
# Run as root.

set -u

INSTALL_DIR="/usr/local/sbin"
SCRIPT_NAME="smSpamHaus.sh"
SERVICE_NAME="smSpamHaus.service"
CRON_NAME="smSpamHaus"
SET="smSpamHaus"
LOG="/var/log/smSpamHaus.log"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: uninstall.sh must be run as root."
    exit 1
fi

echo "[1/6] Stopping and disabling systemd service..."
systemctl disable --now "$SERVICE_NAME" 2>/dev/null || true

systemctl daemon-reload 2>/dev/null || true

echo "[2/6] Removing cron job..."
rm -f "/etc/cron.d/$CRON_NAME"

echo "[3/6] Removing iptables rule..."
while iptables -C INPUT -m set --match-set "$SET" src -j DROP 2>/dev/null; do
    iptables -D INPUT -m set --match-set "$SET" src -j DROP 2>/dev/null || break
done

echo "[4/6] Removing ipset..."
if ipset list -name 2>/dev/null | grep -qx "$SET"; then
    ipset destroy "$SET" 2>/dev/null || {
        ipset flush "$SET" 2>/dev/null || true
        ipset destroy "$SET" 2>/dev/null || true
    }
fi

echo "[5/6] Removing installed files..."
rm -f "$INSTALL_DIR/$SCRIPT_NAME"
rm -f "/etc/systemd/system/$SERVICE_NAME"

systemctl daemon-reload 2>/dev/null || true

echo "[6/6] Removing project log..."
rm -f "$LOG"

echo
echo "========================================"
echo " smSpamHaus uninstall completed"
echo "========================================"
echo
echo "The smSpamHaus service, cron job, firewall rule, ipset and installed script were removed."
echo "Required system packages were NOT removed."
echo
echo "NOTE: If you manually saved iptables rules to /etc/iptables/rules.v4, review that file separately."
