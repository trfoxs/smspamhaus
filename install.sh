#!/bin/bash
set -euo pipefail

INSTALL_DIR="/usr/local/sbin"
SCRIPT_NAME="smSpamHaus.sh"
SERVICE_NAME="smSpamHaus.service"
CRON_NAME="smSpamHaus"
SET="smSpamHaus"
LOG="/var/log/smSpamHaus.log"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: install.sh must be run as root."
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "[1/7] Checking dependencies..."
apt-get update
apt-get install -y curl jq ipset iptables

install -m 0755 "$BASE_DIR/smSpamHaus.sh" "$INSTALL_DIR/$SCRIPT_NAME"
install -m 0644 "$BASE_DIR/systemd/$SERVICE_NAME" "/etc/systemd/system/$SERVICE_NAME"
install -m 0644 "$BASE_DIR/cron/$CRON_NAME" "/etc/cron.d/$CRON_NAME"
touch "$LOG"
chmod 0644 "$LOG"

echo "[2/7] Preparing ipset..."
if ! ipset list -name | grep -qx "$SET"; then
    ipset create "$SET" hash:net family inet hashsize 1024 maxelem 65536
fi

echo "[3/7] Preparing iptables DROP rule..."
if ! iptables -C INPUT -m set --match-set "$SET" src -j DROP 2>/dev/null; then
    iptables -I INPUT 1 -m set --match-set "$SET" src -j DROP
fi

echo "[4/7] Installing systemd and cron..."
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
if systemctl list-unit-files 2>/dev/null | grep -q '^cron.service'; then
    systemctl enable --now cron
fi

echo "[5/7] Initial Spamhaus update..."
"$INSTALL_DIR/$SCRIPT_NAME"

echo "[6/7] Starting smSpamHaus..."
systemctl start "$SERVICE_NAME"

echo "[7/7] Verification..."

ipset list "$SET" | grep -E 'Name:|Type:|Number of entries:'
iptables -C INPUT -m set --match-set "$SET" src -j DROP 2>/dev/null
echo "DROP rule: active"
systemctl is-enabled "$SERVICE_NAME"
echo "Cron:"
cat "/etc/cron.d/$CRON_NAME"

echo
printf '%s\n' "smSpamHaus installed successfully."
printf '%s\n' "Fail2Ban was NOT restarted or reconfigured."
printf '%s\n' "Plesk Firewall was NOT restarted or reconfigured."
