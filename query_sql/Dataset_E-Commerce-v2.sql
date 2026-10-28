-- Dataset Optimasi Basis Data Lanjutan
-- Tema: Penjualan E-Commerce Sintetis
-- Target: MySQL 5.7+ / MariaDB
-- Volume Data:
--   1. Tabel pelanggan : 100.000 baris
--   2. Tabel produk    : 100.000 baris
--   3. Tabel transaksi : 500.000 baris (berelasi ke pelanggan & produk)

CREATE DATABASE IF NOT EXISTS optimasi_basis_data;
USE optimasi_basis_data;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS transaksi;
DROP TABLE IF EXISTS pelanggan;
DROP TABLE IF EXISTS produk;
SET FOREIGN_KEY_CHECKS = 1;

-- ==========================================================
-- 1. PEMBUATAN TABEL UTAMA YANG SALING BERELASI
-- ==========================================================

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

-- Tabel transaksi sengaja belum diberi secondary index selain Foreign Key
-- untuk menguji performa sebelum dan sesudah optimasi indeks.
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

-- ==========================================================
-- 2. PEMBANGKITAN DATA DUMMY (100.000 - 500.000 BARIS)
-- ==========================================================

-- Data master pelanggan: tepat 100.000 baris
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
WHERE n <= 100000;

-- Data master produk: tepat 100.000 baris
INSERT INTO produk (nama_produk, kategori, harga)
SELECT
    CONCAT('Produk ', n),
    ELT(1 + MOD(n, 6), 'Elektronik', 'Pakaian', 'Rumah Tangga',
        'Olahraga', 'Aksesori', 'Perlengkapan Outdoor'),
    15000 + MOD(n * 7919, 1500000) / 100
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
WHERE n <= 100000;

-- Data transaksi: tepat 500.000 baris (berelasi ke 100.000 pelanggan & 100.000 produk)
INSERT INTO transaksi
    (id_pelanggan, id_produk, tanggal_transaksi, jumlah,
     harga_satuan, total_harga, metode_pembayaran, status_transaksi, kota_pengiriman)
SELECT
    1 + MOD(n * 37, 100000),
    1 + MOD(n * 13, 100000),
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
JOIN pelanggan c ON c.id_pelanggan = 1 + MOD(n * 37, 100000)
JOIN produk p ON p.id_produk = 1 + MOD(n * 13, 100000)
WHERE n <= 500000;

-- Verifikasi jumlah baris pada masing-masing tabel
SELECT 'pelanggan' AS nama_tabel, COUNT(*) AS jumlah_baris FROM pelanggan
UNION ALL
SELECT 'produk', COUNT(*) FROM produk
UNION ALL
SELECT 'transaksi', COUNT(*) FROM transaksi;

-- ==========================================================
-- 3. PENGUJIAN 3 QUERY KOMPLEKS (SEBELUM OPTIMASI INDEKS)
-- Masing-masing melibatkan JOIN, WHERE, GROUP BY, dan ORDER BY
-- ==========================================================

-- Query 1: Analisis omzet dan jumlah transaksi per kota & kategori produk pada tahun 2024
EXPLAIN
SELECT 
    c.kota,
    p.kategori,
    COUNT(t.id_transaksi) AS jumlah_transaksi,
    SUM(t.total_harga) AS total_omzet
FROM transaksi t
JOIN pelanggan c ON c.id_pelanggan = t.id_pelanggan
JOIN produk p ON p.id_produk = t.id_produk
WHERE t.status_transaksi = 'Selesai'
  AND t.tanggal_transaksi >= '2024-01-01 00:00:00'
  AND t.tanggal_transaksi <  '2025-01-01 00:00:00'
GROUP BY c.kota, p.kategori
ORDER BY total_omzet DESC;

-- Query 2: Daftar 20 pelanggan dengan nilai belanja tertinggi di Surabaya dan Jakarta
EXPLAIN
SELECT 
    c.id_pelanggan,
    c.nama_pelanggan,
    c.kota,
    COUNT(t.id_transaksi) AS frekuensi_belanja,
    SUM(t.total_harga) AS total_belanja
FROM transaksi t
JOIN pelanggan c ON c.id_pelanggan = t.id_pelanggan
WHERE c.kota IN ('Surabaya', 'Jakarta')
  AND t.metode_pembayaran IN ('E-Wallet', 'Kartu Kredit')
  AND t.status_transaksi = 'Selesai'
GROUP BY c.id_pelanggan, c.nama_pelanggan, c.kota
ORDER BY total_belanja DESC
LIMIT 20;

-- Query 3: Performa penjualan produk kategori Elektronik & Olahraga yang selesai/dikirim
EXPLAIN
SELECT 
    p.id_produk,
    p.nama_produk,
    p.kategori,
    SUM(t.jumlah) AS total_unit_terjual,
    SUM(t.total_harga) AS total_pendapatan
FROM transaksi t
JOIN produk p ON p.id_produk = t.id_produk
WHERE p.kategori IN ('Elektronik', 'Olahraga')
  AND t.status_transaksi IN ('Selesai', 'Dikirim')
  AND t.jumlah >= 2
GROUP BY p.id_produk, p.nama_produk, p.kategori
ORDER BY total_unit_terjual DESC, total_pendapatan DESC
LIMIT 50;

-- ==========================================================
-- 4. PEMBUATAN INDEKS OPTIMASI
-- ==========================================================

CREATE INDEX idx_transaksi_tanggal ON transaksi(tanggal_transaksi);
CREATE INDEX idx_transaksi_status ON transaksi(status_transaksi);
CREATE INDEX idx_transaksi_status_tanggal ON transaksi(status_transaksi, tanggal_transaksi);
CREATE INDEX idx_transaksi_status_metode ON transaksi(status_transaksi, metode_pembayaran);
CREATE INDEX idx_pelanggan_kota ON pelanggan(kota);

ANALYZE TABLE transaksi, pelanggan, produk;

-- ==========================================================
-- 5. PENGUJIAN ULANG 3 QUERY KOMPLEKS (SESUDAH OPTIMASI INDEKS)
-- ==========================================================

-- Ulangi Query 1
EXPLAIN
SELECT 
    c.kota,
    p.kategori,
    COUNT(t.id_transaksi) AS jumlah_transaksi,
    SUM(t.total_harga) AS total_omzet
FROM transaksi t
JOIN pelanggan c ON c.id_pelanggan = t.id_pelanggan
JOIN produk p ON p.id_produk = t.id_produk
WHERE t.status_transaksi = 'Selesai'
  AND t.tanggal_transaksi >= '2024-01-01 00:00:00'
  AND t.tanggal_transaksi <  '2025-01-01 00:00:00'
GROUP BY c.kota, p.kategori
ORDER BY total_omzet DESC;

-- Ulangi Query 2
EXPLAIN
SELECT 
    c.id_pelanggan,
    c.nama_pelanggan,
    c.kota,
    COUNT(t.id_transaksi) AS frekuensi_belanja,
    SUM(t.total_harga) AS total_belanja
FROM transaksi t
JOIN pelanggan c ON c.id_pelanggan = t.id_pelanggan
WHERE c.kota IN ('Surabaya', 'Jakarta')
  AND t.metode_pembayaran IN ('E-Wallet', 'Kartu Kredit')
  AND t.status_transaksi = 'Selesai'
GROUP BY c.id_pelanggan, c.nama_pelanggan, c.kota
ORDER BY total_belanja DESC
LIMIT 20;

-- Ulangi Query 3
EXPLAIN
SELECT 
    p.id_produk,
    p.nama_produk,
    p.kategori,
    SUM(t.jumlah) AS total_unit_terjual,
    SUM(t.total_harga) AS total_pendapatan
FROM transaksi t
JOIN produk p ON p.id_produk = t.id_produk
WHERE p.kategori IN ('Elektronik', 'Olahraga')
  AND t.status_transaksi IN ('Selesai', 'Dikirim')
  AND t.jumlah >= 2
GROUP BY p.id_produk, p.nama_produk, p.kategori
ORDER BY total_unit_terjual DESC, total_pendapatan DESC
LIMIT 50;
