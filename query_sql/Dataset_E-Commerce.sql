-- Dataset Optimasi Basis Data Lanjutan
-- Tema: Penjualan e-commerce sintetis
-- Menghasilkan tepat 500.000 baris transaksi sintetis.
-- Target: MySQL 5.7+ / MariaDB yang mendukung INSERT ... SELECT dan CROSS JOIN.
-- Jalankan pada database kosong/khusus latihan.

CREATE DATABASE IF NOT EXISTS optimasi_basis_data;
USE optimasi_basis_data;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS transaksi;
DROP TABLE IF EXISTS pelanggan;
DROP TABLE IF EXISTS produk;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE pelanggan (
    id_pelanggan INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nama_pelanggan VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    kota VARCHAR(60) NOT NULL,
    tanggal_daftar DATE NOT NULL,
    PRIMARY KEY (id_pelanggan),
    UNIQUE KEY uq_pelanggan_email (email)
) ENGINE=InnoDB;

CREATE TABLE produk (
    id_produk INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nama_produk VARCHAR(100) NOT NULL,
    kategori VARCHAR(50) NOT NULL,
    harga DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (id_produk),
    KEY idx_produk_kategori (kategori)
) ENGINE=InnoDB;

-- Tabel transaksi sengaja belum diberi secondary index.
-- Ini memungkinkan pengujian performa sebelum dan sesudah optimasi indeks.
CREATE TABLE transaksi (
    id_transaksi BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_pelanggan INT UNSIGNED NOT NULL,
    id_produk INT UNSIGNED NOT NULL,
    tanggal_transaksi DATETIME NOT NULL,
    jumlah SMALLINT UNSIGNED NOT NULL,
    harga_satuan DECIMAL(12,2) NOT NULL,
    total_harga DECIMAL(14,2) NOT NULL,
    metode_pembayaran VARCHAR(30) NOT NULL,
    status_transaksi VARCHAR(20) NOT NULL,
    kota_pengiriman VARCHAR(60) NOT NULL,
    PRIMARY KEY (id_transaksi),
    CONSTRAINT fk_transaksi_pelanggan
        FOREIGN KEY (id_pelanggan) REFERENCES pelanggan(id_pelanggan),
    CONSTRAINT fk_transaksi_produk
        FOREIGN KEY (id_produk) REFERENCES produk(id_produk)
) ENGINE=InnoDB;

-- Data master pelanggan: 10.000 baris
INSERT INTO pelanggan (nama_pelanggan, email, kota, tanggal_daftar)
SELECT
    CONCAT('Pelanggan ', n),
    CONCAT('pelanggan', n, '@contoh.test'),
    ELT(1 + MOD(n, 10),
        'Surabaya', 'Jakarta', 'Bandung', 'Yogyakarta', 'Semarang',
        'Malang', 'Medan', 'Makassar', 'Denpasar', 'Palembang'),
    DATE_ADD('2020-01-01', INTERVAL MOD(n * 17, 2200) DAY)
FROM (
    SELECT 1 + d0.d + d1.d*10 + d2.d*100 + d3.d*1000 + d4.d*10000 AS n
    FROM
      (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
       UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d0
    CROSS JOIN
      (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
       UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d1
    CROSS JOIN
      (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
       UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d2
    CROSS JOIN
      (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
       UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d3
    CROSS JOIN
      (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
       UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d4
) angka
WHERE n <= 10000;

-- Data master produk: 1.000 baris
INSERT INTO produk (nama_produk, kategori, harga)
SELECT
    CONCAT('Produk ', n),
    ELT(1 + MOD(n, 6), 'Elektronik', 'Pakaian', 'Rumah Tangga',
        'Olahraga', 'Aksesori', 'Perlengkapan Outdoor'),
    15000 + MOD(n * 7919, 1500000) / 100
FROM (
    SELECT 1 + d0.d + d1.d*10 + d2.d*100 AS n
    FROM
      (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
       UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d0
    CROSS JOIN
      (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
       UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d1
    CROSS JOIN
      (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
       UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d2
) angka
WHERE n <= 1000;

-- Data transaksi: tepat 500.000 baris
-- Kombinasi angka 0..999999 dibatasi sampai 500.000 nomor.
INSERT INTO transaksi
    (id_pelanggan, id_produk, tanggal_transaksi, jumlah,
     harga_satuan, total_harga, metode_pembayaran, status_transaksi, kota_pengiriman)
SELECT
    1 + MOD(n * 37, 10000),
    1 + MOD(n * 13, 1000),
    DATE_ADD('2023-01-01 08:00:00', INTERVAL MOD(n * 7919, 1360) DAY)
        + INTERVAL MOD(n * 47, 86400) SECOND,
    1 + MOD(n, 5),
    p.harga,
    (1 + MOD(n, 5)) * p.harga,
    ELT(1 + MOD(n, 4), 'Transfer Bank', 'E-Wallet', 'COD', 'Kartu Kredit'),
    ELT(1 + MOD(n, 5), 'Selesai', 'Selesai', 'Diproses', 'Dikirim', 'Dibatalkan'),
    c.kota
FROM (
    SELECT 1 + d0.d + d1.d*10 + d2.d*100 + d3.d*1000 + d4.d*10000 + d5.d*100000 AS n
    FROM
      (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
       UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d0
    CROSS JOIN
      (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
       UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d1
    CROSS JOIN
      (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
       UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d2
    CROSS JOIN
      (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
       UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d3
    CROSS JOIN
      (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
       UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d4
    CROSS JOIN
      (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
       UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d5
) angka
JOIN pelanggan c ON c.id_pelanggan = 1 + MOD(n * 37, 10000)
JOIN produk p ON p.id_produk = 1 + MOD(n * 13, 1000)
WHERE n <= 500000;

-- Verifikasi jumlah data
SELECT 'pelanggan' AS tabel, COUNT(*) AS jumlah_baris FROM pelanggan
UNION ALL
SELECT 'produk', COUNT(*) FROM produk
UNION ALL
SELECT 'transaksi', COUNT(*) FROM transaksi;

-- ==========================================================
-- PENGUJIAN OPTIMASI
-- Jalankan query A sebelum membuat indeks; catat waktu eksekusi.
-- Jalankan EXPLAIN sebelum dan sesudah optimasi untuk membandingkan rencana.
-- ==========================================================

-- A. Filter tanggal transaksi (belum ada indeks tanggal)
EXPLAIN
SELECT id_transaksi, id_pelanggan, total_harga
FROM transaksi
WHERE tanggal_transaksi >= '2025-01-01'
  AND tanggal_transaksi <  '2025-02-01';

-- B. Filter status transaksi
EXPLAIN
SELECT id_transaksi, tanggal_transaksi, total_harga
FROM transaksi
WHERE status_transaksi = 'Dikirim';

-- C. JOIN transaksi dan pelanggan, lalu filter kota pelanggan
EXPLAIN
SELECT c.kota, COUNT(*) AS jumlah_transaksi, SUM(t.total_harga) AS omzet
FROM transaksi t
JOIN pelanggan c ON c.id_pelanggan = t.id_pelanggan
WHERE c.kota = 'Surabaya'
GROUP BY c.kota;

-- Buat indeks untuk kolom yang sering dipakai pada WHERE / JOIN.
-- Catat kembali waktu eksekusi dan EXPLAIN sesudah indeks.
CREATE INDEX idx_transaksi_tanggal ON transaksi(tanggal_transaksi);
CREATE INDEX idx_transaksi_status ON transaksi(status_transaksi);
CREATE INDEX idx_transaksi_pelanggan ON transaksi(id_pelanggan);
CREATE INDEX idx_transaksi_produk ON transaksi(id_produk);

ANALYZE TABLE transaksi, pelanggan, produk;

-- Ulangi query A, B, C setelah indeks dibuat.
EXPLAIN
SELECT id_transaksi, id_pelanggan, total_harga
FROM transaksi
WHERE tanggal_transaksi >= '2025-01-01'
  AND tanggal_transaksi <  '2025-02-01';

EXPLAIN
SELECT id_transaksi, tanggal_transaksi, total_harga
FROM transaksi
WHERE status_transaksi = 'Dikirim';

EXPLAIN
SELECT c.kota, COUNT(*) AS jumlah_transaksi, SUM(t.total_harga) AS omzet
FROM transaksi t
JOIN pelanggan c ON c.id_pelanggan = t.id_pelanggan
WHERE c.kota = 'Surabaya'
GROUP BY c.kota;

-- Catatan:
-- 1) EXPLAIN menunjukkan perkiraan rencana query, bukan waktu eksekusi.
-- 2) Ukur waktu aktual melalui tab profil/profiling yang tersedia pada client,
--    atau jalankan query beberapa kali dan catat durasinya di phpMyAdmin/Workbench.
-- 3) Indeks mempercepat pencarian tertentu, tetapi menambah penggunaan ruang
--    dan biaya INSERT/UPDATE/DELETE. Jangan menganggap semua indeks selalu baik.
