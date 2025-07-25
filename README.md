****cleanup_dns_cluster-wilcard.sh** ** untuk memperbaiki serangan hack dns dns wildcard * pada server cpanel 
=======================================================================================================

Script ini digunakan untuk menghapus entri DNS wildcard (* dan *.subdomain) yang mengarah ke IP tertentu contoh  (162.0.227.145), memvalidasi domain yang aktif, dan menyinkronkan perubahan ke DNS cluster di server berbasis cPanel.

1.Cari Domain yang Mengarah ke IP Target
Mencari file .db di /var/named/ yang mengandung IP target (162.0.227.145) dan menyimpannya dalam list (list.txt).

2.Backup File DNS (.db)
Semua file zona domain yang ditemukan dibackup ke folder /backup/namedhack.

3.Validasi Domain Aktif
Mengecek apakah domain yang ditemukan benar-benar masih aktif (terdaftar di /etc/userdomains).

4.Hapus Entri Wildcard DNS
Untuk setiap domain aktif, entri wildcard DNS yang cocok akan dihapus menggunakan sed.

5.Sinkronisasi ke DNS Cluster
Jika file .db valid setelah edit, maka disinkronkan ke cluster DNS menggunakan script dnscluster.

=======================================================================================================

****clean_dns_www.shh** ** untuk memperbaiki serangan hack www dns pada server cpanel 
------------------------------------------------------------------------------------------

🎯 Tujuan Utama:
Script ini digunakan untuk mengganti entri DNS www yang mengarah ke IP target (15.235.228.189) dengan IP dari domain utamanya atau dari subdomain terkait, dan kemudian menyinkronkan perubahan ke DNS cluster.


1.	Backup Semua File Zona .db

2.	Semua file zona DNS di /var/named dibackup ke folder /backup/named_www_replace.

3.	Cari Domain yang Mengandung IP Target

4.	Mencari domain yang file DNS-nya mengarah ke IP target (15.235.228.189).

5.	Validasi Domain Aktif

6.	Memastikan domain masih aktif dengan mencocokkannya di /etc/userdomains.

7.	Proses Penggantian IP untuk Entri www

8.	Untuk setiap domain valid:

9.	Dicari entri www, www.subdomain, dll yang mengarah ke IP target.

10.	Jika www saja, diganti dengan IP dari domain utama.

11.	Jika www.sub, diganti dengan IP dari sub.

12.	Perubahan dilakukan langsung di file .db.

13.	Update Serial DNS

Serial DNS di SOA akan di-update (diperbarui otomatis agar perubahan dikenali oleh server DNS).

Sinkronisasi ke DNS Cluster

Perubahan pada setiap domain disinkronkan ke cluster DNS cPanel.
