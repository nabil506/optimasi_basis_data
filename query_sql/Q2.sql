EXPLAIN
SELECT id_transaksi, tanggal_transaksi, total_harga
FROM transaksi
WHERE status_transaksi = 'Dikirim';
