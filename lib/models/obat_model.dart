/// Models for Obat, Resep & Pelacakan Pesanan

class ObatModel {
  final dynamic id;
  final String nama;
  final String kategori;
  final int harga;
  final String hargaFormatted;
  final String deskripsi;
  final String? peringatanGinjal;
  final String? gambar;
  final bool perluResep;
  final int stok;
  final String? kemasan;
  final String? aturanPakai;

  ObatModel({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.harga,
    required this.hargaFormatted,
    required this.deskripsi,
    this.peringatanGinjal,
    this.gambar,
    this.perluResep = false,
    this.stok = 100,
    this.kemasan,
    this.aturanPakai,
  });

  factory ObatModel.fromJson(Map<String, dynamic> json) {
    final rawHarga = int.tryParse(json['harga_jual']?.toString() ?? json['harga']?.toString() ?? '0') ?? 0;
    final cat = (json['kategori'] ?? json['category'] ?? 'Umum').toString();
    final name = (json['nama_obat'] ?? json['nama'] ?? json['name'] ?? 'Obat').toString();
    final catLower = cat.toLowerCase();
    final nameLower = name.toLowerCase();
    final bool isRx = json['perlu_resep'] == true ||
        json['perlu_resep'] == 1 ||
        json['is_resep'] == 1 ||
        catLower.contains('keras') ||
        catLower.contains('resep') ||
        catLower.contains('ginjal') ||
        catLower.contains('hipertensi') ||
        catLower.contains('arb') ||
        catLower.contains('diuretik') ||
        nameLower.contains('ketosteril') ||
        nameLower.contains('candesartan') ||
        nameLower.contains('furosemide') ||
        nameLower.contains('amlodipine');

    return ObatModel(
      id: json['id_obat'] ?? json['id'] ?? 0,
      nama: name,
      kategori: cat,
      harga: rawHarga,
      hargaFormatted: json['harga_formatted']?.toString() ?? 'Rp ${rawHarga.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
      deskripsi: json['aturan_pakai_umum']?.toString() ?? json['deskripsi']?.toString() ?? json['description']?.toString() ?? '',
      peringatanGinjal: json['peringatan_ginjal']?.toString() ?? json['ginjal_warning']?.toString(),
      gambar: json['foto_obat']?.toString() ?? json['gambar']?.toString() ?? json['foto']?.toString() ?? json['image']?.toString(),
      perluResep: isRx,
      stok: int.tryParse(json['stok_total']?.toString() ?? json['stok']?.toString() ?? '100') ?? 100,
      kemasan: json['satuan_kemasan']?.toString() ?? json['kemasan']?.toString() ?? json['package_info']?.toString(),
      aturanPakai: json['aturan_pakai_umum']?.toString() ?? json['aturan_pakai']?.toString(),
    );
  }
}

class ResepModel {
  final dynamic id;
  final String nomorResep;
  final String namaDokter;
  final String tanggal;
  final String status;
  final List<dynamic> items;

  ResepModel({
    required this.id,
    required this.nomorResep,
    required this.namaDokter,
    required this.tanggal,
    required this.status,
    required this.items,
  });

  factory ResepModel.fromJson(Map<String, dynamic> json) {
    return ResepModel(
      id: json['id'],
      nomorResep: json['nomor_resep']?.toString() ?? json['no_resep']?.toString() ?? 'RSP-${json['id']}',
      namaDokter: json['nama_dokter']?.toString() ?? json['dokter']?['nama']?.toString() ?? 'Dokter GIAT',
      tanggal: json['tanggal']?.toString() ?? json['created_at']?.toString() ?? '',
      status: json['status']?.toString() ?? 'aktif',
      items: json['items'] is List ? json['items'] as List : (json['obat'] is List ? json['obat'] as List : []),
    );
  }
}

class TrackingStep {
  final String status;
  final String keterangan;
  final String waktu;
  final bool isCompleted;

  TrackingStep({
    required this.status,
    required this.keterangan,
    required this.waktu,
    required this.isCompleted,
  });

  factory TrackingStep.fromJson(Map<String, dynamic> json) {
    return TrackingStep(
      status: json['status']?.toString() ?? '',
      keterangan: json['keterangan']?.toString() ?? json['deskripsi']?.toString() ?? '',
      waktu: json['waktu']?.toString() ?? json['tanggal']?.toString() ?? '',
      isCompleted: json['is_completed'] == true || json['selesai'] == true,
    );
  }
}

class PesananObatModel {
  final dynamic id;
  final String noPesanan;
  final String tanggal;
  final int totalHarga;
  final String status;
  final String statusPembayaran;
  final String? snapToken;
  final String? redirectUrl;
  final String? alamatPengiriman;
  final String? metodePembayaran;
  final List<dynamic> items;
  final List<TrackingStep> tracking;

  PesananObatModel({
    required this.id,
    required this.noPesanan,
    required this.tanggal,
    required this.totalHarga,
    required this.status,
    this.statusPembayaran = 'menunggu_pembayaran',
    this.snapToken,
    this.redirectUrl,
    this.alamatPengiriman,
    this.metodePembayaran,
    required this.items,
    this.tracking = const [],
  });

  factory PesananObatModel.fromJson(Map<String, dynamic> json) {
    List<TrackingStep> parsedTracking = [];
    if (json['lacak'] is List) {
      parsedTracking = (json['lacak'] as List).map((e) => TrackingStep.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } else if (json['tracking'] is List) {
      parsedTracking = (json['tracking'] as List).map((e) => TrackingStep.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }

    final rawTotal = double.tryParse(
          (json['total_bayar'] ?? json['total_harga'] ?? json['total'] ?? '0').toString(),
        )?.round() ??
        0;

    return PesananObatModel(
      id: json['id'] ?? json['id_pembelian'],
      noPesanan: json['no_pesanan']?.toString() ?? json['kode_pesanan']?.toString() ?? 'ORD-${json['id'] ?? json['id_pembelian'] ?? ''}',
      tanggal: json['tanggal']?.toString() ?? json['waktu_bayar']?.toString() ?? json['created_at']?.toString() ?? '',
      totalHarga: rawTotal,
      status: json['status_pesanan']?.toString() ?? json['status']?.toString() ?? 'menunggu_konfirmasi',
      statusPembayaran: json['status_pembayaran']?.toString() ?? 'menunggu_pembayaran',
      snapToken: json['snap_token']?.toString(),
      redirectUrl: json['redirect_url']?.toString(),
      alamatPengiriman: json['alamat_pengiriman']?.toString(),
      metodePembayaran: json['metode_pembayaran']?.toString(),
      items: json['items'] is List ? json['items'] as List : [],
      tracking: parsedTracking,
    );
  }
}
