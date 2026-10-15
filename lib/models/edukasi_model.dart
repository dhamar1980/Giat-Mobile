/// Models for Edukasi Kesehatan Ginjal

class EdukasiArtikel {
  final dynamic id;
  final String judul;
  final String kategori;
  final String konten;
  final String? ringkasan;
  final String? gambar;
  final String tanggal;
  final String? penulis;

  EdukasiArtikel({
    required this.id,
    required this.judul,
    required this.kategori,
    required this.konten,
    this.ringkasan,
    this.gambar,
    required this.tanggal,
    this.penulis,
  });

  factory EdukasiArtikel.fromJson(Map<String, dynamic> json) {
    return EdukasiArtikel(
      id: json['id'],
      judul: json['judul']?.toString() ?? json['title']?.toString() ?? 'Artikel Edukasi',
      kategori: json['kategori']?.toString() ?? json['category']?.toString() ?? 'Kesehatan Ginjal',
      konten: json['konten']?.toString() ?? json['content']?.toString() ?? '',
      ringkasan: json['ringkasan']?.toString() ?? json['summary']?.toString(),
      gambar: json['gambar']?.toString() ?? json['image']?.toString() ?? json['thumbnail']?.toString(),
      tanggal: json['tanggal']?.toString() ?? json['created_at']?.toString() ?? '',
      penulis: json['penulis']?.toString() ?? json['author']?.toString() ?? 'Tim Medis GIAT',
    );
  }
}

class EdukasiKategori {
  final dynamic id;
  final String nama;

  EdukasiKategori({
    required this.id,
    required this.nama,
  });

  factory EdukasiKategori.fromJson(Map<String, dynamic> json) {
    return EdukasiKategori(
      id: json['id'],
      nama: json['nama']?.toString() ?? json['name']?.toString() ?? '',
    );
  }
}
