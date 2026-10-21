EXPLAIN
SELECT c.kota, COUNT(*) AS jumlah_transaksi, SUM(t.total_harga) AS omzet
FROM transaksi t
JOIN pelanggan c ON c.id_pelanggan = t.id_pelanggan
WHERE c.kota = 'Surabaya'
GROUP BY c.kota;
