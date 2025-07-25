#!/bin/bash

# === KONFIGURASI ===
TARGET_IP="15.235.228.189"
NAMED_DIR="/var/named"
BACKUP_DIR="/backup/named_www_replace"
USERDOMAINS="/etc/userdomains"
LIST_DOM="/tmp/list_www_target.$$"

echo "[INFO] Membuat backup zonafile ke ➜ $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp -a "$NAMED_DIR"/*.db "$BACKUP_DIR"/

echo "[INFO] Menyusun daftar domain yang mengandung IP target ..."
grep -irl --include="*.db" "$TARGET_IP" "$NAMED_DIR" | xargs -n1 basename | sed 's/\.db$//' > "$LIST_DOM"

echo "[INFO] Validasi domain yang ada di $USERDOMAINS ..."
VALID_DOMAINS=()
while IFS= read -r domain; do
    result=$(grep "^$domain:" "$USERDOMAINS" | cut -d':' -f1)
    if [[ -n "$result" ]]; then
        VALID_DOMAINS+=("$result")
    fi
done < "$LIST_DOM"

for domain in "${VALID_DOMAINS[@]}"; do
    db_file="$NAMED_DIR/$domain.db"

    echo "[INFO] Memproses $domain …"

    # Ambil IP utama domain (tanpa www)
    main_ip=$(awk -v dom="$domain" '$1==dom"." && $4=="A"{print $5; exit}' "$db_file")
    [ -z "$main_ip" ] && main_ip=$(awk -v dom="$domain" '$1==dom && $4=="A"{print $5; exit}' "$db_file")

    if [[ -z "$main_ip" ]]; then
        echo "[SKIP] $domain ➜ IP utama tidak ditemukan"
        continue
    fi

    # Temukan semua baris www* yang mengarah ke IP target
    matched_lines=$(grep -E "^[[:space:]]*www(\.[a-zA-Z0-9.-]*)?[[:space:]]+[0-9]+[[:space:]]+IN[[:space:]]+A[[:space:]]+$TARGET_IP" "$db_file")
    if [[ -z "$matched_lines" ]]; then
        echo "[SKIP] $domain ➜ tidak ada www* yang mengarah ke IP target"
        continue
    fi

    echo "$matched_lines" | while read -r line; do
        full_www=$(echo "$line" | awk '{print $1}')
        sub="${full_www#www.}"

        # Jika www saja, gunakan IP domain utama
        if [[ "$full_www" == "www" || "$full_www" == "www." ]]; then
            replace_ip="$main_ip"
        else
            # Ambil IP dari subdomain (tanpa www)
            replace_ip=$(grep -E "^[[:space:]]*${sub}[[:space:]]+[0-9]+[[:space:]]+IN[[:space:]]+A[[:space:]]+" "$db_file" | awk '{print $NF}' | head -n1)
        fi

        if [[ -n "$replace_ip" ]]; then
            echo "[EDIT] $full_www ➜ ganti IP $TARGET_IP → $replace_ip"
            escaped=$(echo "$full_www" | sed 's/\./\\./g')
            sed -i -E "s/^(${escaped}[[:space:]]+[0-9]+[[:space:]]+IN[[:space:]]+A[[:space:]]+)$TARGET_IP/\1$replace_ip/" "$db_file"
        else
            echo "[SKIP] $full_www ➜ tidak ditemukan IP untuk $sub"
        fi
    done

    # Update serial zona DNS (SOA)
    perl -0777 -i -pe '
        s/(\(\s*)(\d{10})(\s*\n)/$1.(($2+1)).$3/e
    ' "$db_file"

    # Sinkronisasi DNS cluster
    /usr/local/cpanel/scripts/dnscluster synczone "$domain"
done

rm -f "$LIST_DOM"
echo "[DONE] Proses selesai untuk ${#VALID_DOMAINS[@]} domain yang valid."