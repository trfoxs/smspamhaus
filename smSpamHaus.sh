#!/bin/bash
set -u -o pipefail

URL="https://www.spamhaus.org/drop/drop_v4.json"
SET="smSpamHaus"
TMP_SET="${SET}_new"
JSON="/run/${SET}.json"
LOG="/var/log/smSpamHaus.log"
LOCK="/run/lock/${SET}.lock"

mkdir -p "$(dirname "$LOCK")"
touch "$LOG"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }

exec 9>"$LOCK"
if ! flock -n 9; then
    log "Update skipped: another update is already running."
    exit 0
fi

cleanup() {
    rm -f "$JSON"
    if ipset list -name 2>/dev/null | grep -qx "$TMP_SET"; then
        ipset destroy "$TMP_SET" 2>/dev/null || true
    fi
}
trap cleanup EXIT

log "Update started."

if ! curl -fsSL --retry 3 --connect-timeout 20 --max-time 120 "$URL" -o "$JSON"; then
    log "ERROR: Failed to download Spamhaus DROP IPv4 feed. Existing ipset left unchanged."
    exit 1
fi

COUNT=$(jq -r 'select(.type != "metadata" and (.cidr | type == "string")) | .cidr' "$JSON" | wc -l)
if [ "$COUNT" -lt 1 ]; then
    log "ERROR: No valid CIDR records found. Existing ipset left unchanged."
    exit 1
fi

# Build a new set first. The live set is never flushed until the new data is ready.
ipset destroy "$TMP_SET" 2>/dev/null || true
if ! ipset create "$TMP_SET" hash:net family inet hashsize 1024 maxelem 65536; then
    log "ERROR: Failed to create temporary ipset."
    exit 1
fi

while IFS= read -r CIDR; do
    [ -n "$CIDR" ] || continue
    if ! ipset add "$TMP_SET" "$CIDR" -exist; then
        log "ERROR: Invalid/unloadable CIDR: $CIDR. Existing ipset left unchanged."
        exit 1
    fi
done < <(jq -r 'select(.type != "metadata" and (.cidr | type == "string")) | .cidr' "$JSON")

ACTIVE=$(ipset list "$TMP_SET" | awk '/Number of entries:/ {print $4}')
if [ -z "$ACTIVE" ] || [ "$ACTIVE" -lt 1 ]; then
    log "ERROR: Temporary ipset is empty. Existing ipset left unchanged."
    exit 1
fi

# Ensure the live set exists before the firewall check.
if ! ipset list -name | grep -qx "$SET"; then
    ipset create "$SET" hash:net family inet hashsize 1024 maxelem 65536
fi

# Atomic replacement: iptables continues to reference the same set name.
if ! ipset swap "$TMP_SET" "$SET"; then
    log "ERROR: Failed to atomically swap ipsets."
    exit 1
fi

# The temporary name now contains the old live data and is removed by cleanup().

if ! iptables -C INPUT -m set --match-set "$SET" src -j DROP 2>/dev/null; then
    if iptables -I INPUT 1 -m set --match-set "$SET" src -j DROP; then
        log "iptables DROP rule added."
    else
        log "ERROR: Failed to add iptables DROP rule."
        exit 1
    fi
fi

log "Spamhaus: $ACTIVE unique IPv4 CIDRs loaded. Source records: $COUNT."
log "Update completed. Fail2Ban was not restarted."
exit 0
