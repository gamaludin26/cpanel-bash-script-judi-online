**cleanup_dns_cluster-wilcard.sh ** untuk memperbaiki serangan hack dns pada server cpanel 

Script ini digunakan untuk menghapus entri DNS wildcard (* dan *.subdomain) yang mengarah ke IP tertentu contoh  (162.0.227.145), memvalidasi domain yang aktif, dan menyinkronkan perubahan ke DNS cluster di server berbasis cPanel.

🔧 Langkah-langkah Utama Script:
Cari Domain yang Mengarah ke IP Target
Mencari file .db di /var/named/ yang mengandung IP target (162.0.227.145) dan menyimpannya dalam list (list.txt).

Backup File DNS (.db)
Semua file zona domain yang ditemukan dibackup ke folder /backup/namedhack.

Validasi Domain Aktif
Mengecek apakah domain yang ditemukan benar-benar masih aktif (terdaftar di /etc/userdomains).

Hapus Entri Wildcard DNS
Untuk setiap domain aktif, entri wildcard DNS yang cocok akan dihapus menggunakan sed.

Sinkronisasi ke DNS Cluster
Jika file .db valid setelah edit, maka disinkronkan ke cluster DNS menggunakan script dnscluster.

🧹 Manfaat:
Script ini bermanfaat untuk:

Membersihkan entri DNS wildcard yang bisa disalahgunakan (misal: deface massal).

Mencegah penyebaran DNS wildcard ke seluruh DNS cluster.

Melindungi domain dari konfigurasi DNS yang tidak sah.

