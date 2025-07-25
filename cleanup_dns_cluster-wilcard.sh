#!/bin/bash

# === KONFIGURASI ===
TARGET_IP="162.0.227.145"
NAMED_DIR="/var/named"
BACKUP_LIST="/backup/list.txt"
BACKUP_DIR="/backup/namedhack"
USERDOMAINS="/etc/userdomains"

# Tangkap wildcard *, *.subdomain, *.abc.def yang mengarah ke TARGET_IP
WILDCARD_REGEX="(^\*\s+[0-9]+\s+IN\s+A\s+$TARGET_IP)|(^\*\.[a-zA-Z0-9.-]+\s+[0-9]+\s+IN\s+A\s+$TARGET_IP)"

echo "[INFO] Mencari domain dengan IP $TARGET_IP ..."
grep -irl "$TARGET_IP" "$NAMED_DIR" --include="*.db" | grep -v "cache" | xargs -n1 basename | sed 's/\.db$//' > "$BACKUP_LIST"

echo "[INFO] Membackup file .db ke $BACKUP_DIR ..."
mkdir -p "$BACKUP_DIR"
while read -r domain; do
    db_file="$NAMED_DIR/$domain.db"
    [ -f "$db_file" ] && cp -a "$db_file" "$BACKUP_DIR/"
done < "$BACKUP_LIST"

echo "[INFO] Memvalidasi domain yang ditemukan ..."
VALID_DOMAINS=()
while read -r domain; do
    if grep -q "^$domain:" "$USERDOMAINS"; then
        VALID_DOMAINS+=("$domain")
    else
        echo "[SKIP] $domain tidak ditemukan di $USERDOMAINS"
    fi
done < "$BACKUP_LIST"

echo "[INFO] Menghapus wildcard (termasuk *.subdomain) dan sync ke DNS Cluster ..."
for domain in "${VALID_DOMAINS[@]}"; do
    db_file="$NAMED_DIR/$domain.db"
    
    if grep -Pq "$WILDCARD_REGEX" "$db_file"; then
        echo "[EDIT] Menghapus wildcard di $domain"
        sed -i -E "/$WILDCARD_REGEX/d" "$db_file"

        # Validasi zone sebelum sync
        if named-checkzone "$domain" "$db_file" >/dev/null 2>&1; then
            echo "[SYNC] Sinkronisasi DNS cluster untuk $domain"
            /usr/local/cpanel/scripts/dnscluster synczone "$domain"
        else
            echo "[ERROR] Zone $domain tidak valid setelah diedit, dilewati"
        fi
    else
        echo "[INFO] Tidak ada wildcard yang cocok di $domain"
    fi
done

echo "[DONE] Proses selesai."