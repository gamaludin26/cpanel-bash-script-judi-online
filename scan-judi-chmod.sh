#!/bin/bash

# Lokasi file keyword
keyword_file="/backup/keywords.txt"

# Lokasi log global
global_log="/backup/scan_gacor_all.log"
echo "=== Global Scan Started: $(date) ===" > "$global_log"

# Ambil daftar user dari cPanel
user_list=$(ls /var/cpanel/users)

# Gabungkan keyword jadi pola regex
if [[ -f "$keyword_file" ]]; then
    keyword_pattern=$(paste -sd'|' "$keyword_file")
else
    echo "Keyword file tidak ditemukan: $keyword_file"
    exit 1
fi

for user in $user_list; do
    homedir="/home/$user/public_html"
    logdir="$homedir/scan"
    logfile="$logdir/scan.log"
    backupdir="/backup/backupgacor/$user"

    if [ -d "$homedir" ]; then
        mkdir -p "$logdir"
        mkdir -p "$backupdir"
        echo "=== Scan Start: $(date) ===" > "$logfile"

        # Scan berdasarkan keyword pattern
        infected_items=$(grep -r -i -l -E "$keyword_pattern" "$homedir" 2>/dev/null)

        if [ ! -z "$infected_items" ]; then
            echo "[+] User $user: TERDETEKSI file terinfeksi" >> "$global_log"

            while IFS= read -r item; do
                echo "[INFECTED] $item" >> "$logfile"

                # Buat struktur direktori backup
                target_backup_path="$backupdir$(dirname "$item" | sed "s|$homedir||")"
                mkdir -p "$target_backup_path"

                # Backup file
                cp -a "$item" "$target_backup_path/" 2>/dev/null

                # Lock file/folder
                chmod 000 "$item" 2>/dev/null
            done <<< "$infected_items"

        else
            echo "[OK] User $user: Tidak ditemukan file mencurigakan" >> "$global_log"
        fi

        echo "=== Scan End: $(date) ===" >> "$logfile"
    fi
done

echo "=== Global Scan Selesai: $(date) ===" >> "$global_log"