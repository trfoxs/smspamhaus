#!/bin/bash
# smSpamHaus project
# Update Spamhaus DROP IPv4 CIDR list and load it into ipset.

set -u

URL="https://www.spamhaus.org/drop/drop_v4.json"
JSON="/root/drop_v4.json"
SET="smSpamHaus"
LOG="/var/log/smSpamHaus.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"
}

log "Güncelleme başladı."

rm -f "$JSON"

if ! curl -fsSL --retry 3 --connect-timeout 20 --max-time 120 "$URL" -o "$JSON"; then
    log "HATA: JSON indirilemedi."
    exit 1
fi

# Spamhaus DROP is NDJSON: one JSON object per line.
# Metadata is deliberately excluded; only records containing cidr are used.
COUNT=$(jq -r 'select(.type != "metadata" and .cidr) | .cidr' "$JSON" | wc -l)

if [ "$COUNT" -lt 1 ]; then
    log "HATA: CIDR bulunamadı."
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
    log "HATA: CIDR'lar ipset'e yüklenemedi."
    exit 1
fi

ACTIVE=$(ipset list "$SET" | awk '/Number of entries:/ {print $4}')

if [ -z "$ACTIVE" ] || [ "$ACTIVE" -lt 1 ]; then
    log "HATA: ipset boş kaldı."
    exit 1
fi

log "Spamhaus: $ACTIVE benzersiz CIDR yüklendi. Kaynak kayıt: $COUNT."

if ! iptables -C INPUT -m set --match-set "$SET" src -j DROP 2>/dev/null; then
    iptables -I INPUT 1 -m set --match-set "$SET" src -j DROP
    log "iptables DROP kuralı eklendi."
fi

if systemctl is-active --quiet fail2ban; then
    systemctl restart fail2ban
    log "Fail2Ban yeniden başlatıldı."
fi

log "Güncelleme tamamlandı."
exit 0
