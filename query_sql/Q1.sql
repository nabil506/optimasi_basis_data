EXPLAIN
SELECT id_transaksi, id_pelanggan, total_harga
FROM transaksi
WHERE tanggal_transaksi >= '2025-01-01'
  AND tanggal_transaksi <  '2025-02-01';
