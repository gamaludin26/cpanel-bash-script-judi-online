#!/bin/bash

# Nama file: change_password_from_domain.sh
# Lokasi file domain
LIST_FILE="/backup/list.txt"
OUTPUT_FILE="/backup/userchange3"

# Periksa apakah file list domain ada
if [[ ! -f "$LIST_FILE" ]]; then
    echo "File $LIST_FILE tidak ditemukan!"
    exit 1
fi

# Kosongkan file output jika sudah ada
> "$OUTPUT_FILE"

# Proses setiap domain
while read -r domain; do
    # Skip baris kosong
    [[ -z "$domain" ]] && continue

    # Ambil username berdasarkan domain
    user=$(grep -i "^${domain}:" /etc/userdomains | awk '{print $2}')

    if [[ -z "$user" ]]; then
        echo "? Domain $domain tidak ditemukan"
        continue
    fi

    # Buat password berdasarkan hash username
    pass=$(echo "$user" | sha256sum | cut -c10-26)

    # Simpan ke file
    echo "$user|$domain|$pass" >> "$OUTPUT_FILE"

    # Jalankan perintah WHM API
    whmapi1 --output=jsonpretty passwd user="$user" password="$pass"

done < "$LIST_FILE"