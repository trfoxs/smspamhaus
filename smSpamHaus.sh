#!/bin/bash
# smSpamHaus project
# Update the Spamhaus DROP IPv4 CIDR list and load it into ipset.

set -u

URL="https://www.spamhaus.org/drop/drop_v4.json"
JSON="/root/drop_v4.json"
SET="smSpamHaus"
LOG="/var/log/smSpamHaus.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"
}

log "Update started."

rm -f "$JSON"

if ! curl -fsSL --retry 3 --connect-timeout 20 --max-time 120 "$URL" -o "$JSON"; then
    log "ERROR: Failed to download the JSON feed."
    exit 1
fi

# Spamhaus DROP is NDJSON: one JSON object per line.
# Metadata is deliberately excluded; only records containing cidr are used.
COUNT=$(jq -r 'select(.type != "metadata" and .cidr) | .cidr' "$JSON" | wc -l)

if [ "$COUNT" -lt 1 ]; then
    log "ERROR: No CIDR records found."
    exit 1
fi

if ! ipset list -name | grep -qx "$SET"; then
    ipset create "$SET" hash:net family inet
fi

ipset flush "$SET"

if ! jq -r 'select(.type != "metadata" and .cidr) | .cidr' "$JSON" |
    while read -r CIDR; do
        ipset add "$SET" "$CIDR" -exist || exit 1
    done
then
    log "ERROR: Failed to load CIDR records into ipset."
    exit 1
fi

ACTIVE=$(ipset list "$SET" | awk '/Number of entries:/ {print $4}')

if [ -z "$ACTIVE" ] || [ "$ACTIVE" -lt 1 ]; then
    log "ERROR: ipset is empty."
    exit 1
fi

log "Spamhaus: $ACTIVE unique CIDRs loaded. Source records: $COUNT."

if ! iptables -C INPUT -m set --match-set "$SET" src -j DROP 2>/dev/null; then
    iptables -I INPUT 1 -m set --match-set "$SET" src -j DROP
    log "iptables DROP rule added."
fi

if systemctl is-active --quiet fail2ban; then
    systemctl restart fail2ban
    log "Fail2Ban restarted."
fi

log "Update completed."
exit 0
