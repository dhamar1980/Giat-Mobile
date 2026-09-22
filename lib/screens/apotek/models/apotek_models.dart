// ─────────────────────────────────────────────────────────────────────────────
// MODEL DATA APOTEK & FARMASI (Berdasarkan Desain & Alur Figma GIAT)
// ─────────────────────────────────────────────────────────────────────────────

class ApotekOrderItem {
  final String medicineName;
  final String formAndPack; // e.g. "Tablet • 10 tablet"
  final String qtyText; // e.g. "2 Tablet"
  final bool isAvailable;

  const ApotekOrderItem({
    required this.medicineName,
    required this.formAndPack,
    required this.qtyText,
    this.isAvailable = true,
  });
}

enum ApotekOrderStatus {
  menunggu,
  diproses,
  selesai,
}

class ApotekOrder {
  final String id; // e.g. "ORD-0124"
  final String patientName;
  final String patientInitials;
  final int patientAge;
  final String patientGender;
  final String patientAddress;
  final String timeText; // e.g. "10 menit lalu"
  final String recipeRef; // e.g. "RX-00110"
  final String doctorName; // e.g. "dr. Andi Wijaya"
  final String recipeDate; // e.g. "1 Juni 2025"
  ApotekOrderStatus status;
  final List<ApotekOrderItem> items;

  ApotekOrder({
    required this.id,
    required this.patientName,
    required this.patientInitials,
    required this.patientAge,
    required this.patientGender,
    required this.patientAddress,
    required this.timeText,
    required this.recipeRef,
    required this.doctorName,
    required this.recipeDate,
    required this.status,
    required this.items,
  });
}

enum ApotekRecipeStatus {
  belumDiverifikasi,
  diverifikasi,
  selesai,
}

class ApotekRecipeItem {
  final String medicineName;
  final String formAndPack;
  final String doseRule; // e.g. "3 x 1 tablet"
  final String usageNotes; // e.g. "Sesudah Makan (Habiskan)"
  final String qtyText; // e.g. "2 Tablet"

  const ApotekRecipeItem({
    required this.medicineName,
    required this.formAndPack,
    required this.doseRule,
    required this.usageNotes,
    required this.qtyText,
  });
}

class ApotekRecipe {
  final String id; // e.g. "RSP-00125"
  final String patientName;
  final String patientInitials;
  final String medRecNo; // e.g. "#RM-48291"
  final String doctorName; // e.g. "dr. Andi Pratama"
  final String dateText; // e.g. "31 Agustus 2026"
  final String timeText; // e.g. "10 menit lalu"
  ApotekRecipeStatus status;
  final List<ApotekRecipeItem> items;
  String? verifiedTime;
  String? completedTime;

  ApotekRecipe({
    required this.id,
    required this.patientName,
    required this.patientInitials,
    required this.medRecNo,
    required this.doctorName,
    required this.dateText,
    required this.timeText,
    required this.status,
    required this.items,
    this.verifiedTime,
    this.completedTime,
  });
}

enum ApotekMedicineStatus {
  tersedia,
  stokMenipis,
  habis,
}

class ApotekMedicineBatch {
  final String batchNo; // e.g. "BATCH-2024-K12"
  final String qtyText; // e.g. "70 Tablet"
  final String expDate; // e.g. "14 Okt 2026"
  final String status; // e.g. "Tersedia"

  const ApotekMedicineBatch({
    required this.batchNo,
    required this.qtyText,
    required this.expDate,
    required this.status,
  });
}

class ApotekMedicine {
  final String id; // e.g. "#MED-8842"
  final String name;
  final String category; // e.g. "Analgesik & Antipiretik"
  final String form; // e.g. "Tablet"
  final String dose; // e.g. "500 mg"
  final String packageUnit; // e.g. "Strip / Box"
  int stock;
  final String stockUnit; // e.g. "Tablet", "Strip", "Box"
  int buyPrice;
  int sellPrice;
  final String expDate;
  final String? usageRule;
  final List<ApotekMedicineBatch> batches;

  ApotekMedicine({
    required this.id,
    required this.name,
    required this.category,
    required this.form,
    required this.dose,
    required this.packageUnit,
    required this.stock,
    required this.stockUnit,
    required this.buyPrice,
    required this.sellPrice,
    required this.expDate,
    this.usageRule,
    required this.batches,
  });

  ApotekMedicineStatus get status {
    if (stock <= 0) return ApotekMedicineStatus.habis;
    if (stock <= 10) return ApotekMedicineStatus.stokMenipis;
    return ApotekMedicineStatus.tersedia;
  }
}

class ApotekActivity {
  final String id;
  final String title;
  final String subtitle;
  final String timeText;
  final String type; // "stok" | "obat" | "pesanan" | "resep"

  const ApotekActivity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timeText,
    required this.type,
  });
}

class ApotekDaySchedule {
  final String dayName; // "Senin", "Selasa", dll
  final String shortDay; // "S", "S", "R", "K", "J", "S", "M"
  bool isOpen;
  String openTime; // "08:00 AM"
  String closeTime; // "09:00 PM"

  ApotekDaySchedule({
    required this.dayName,
    required this.shortDay,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });
}

class ApotekCoverageArea {
  final String name;
  final String details;
  bool isActive;

  ApotekCoverageArea({
    required this.name,
    required this.details,
    required this.isActive,
  });
}

class ApotekNotification {
  final String id;
  final String title;
  final String body;
  final String time;
  bool isRead;
  final String type; // 'pesanan', 'resep', 'stok', 'sistem'

  ApotekNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
    required this.type,
  });
}

class ApotekFaqStep {
  final int stepNumber;
  final String title;
  final String description;

  const ApotekFaqStep({
    required this.stepNumber,
    required this.title,
    required this.description,
  });
}

class ApotekFaqItem {
  final String id;
  final String question;
  final String overview;
  final List<ApotekFaqStep> steps;
  final String tipTitle;
  final String tipBody;

  const ApotekFaqItem({
    required this.id,
    required this.question,
    required this.overview,
    required this.steps,
    required this.tipTitle,
    required this.tipBody,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA AWAL (SESUAI DOKUMEN FIGMA)
// ─────────────────────────────────────────────────────────────────────────────

class ApotekMockData {
  static final List<ApotekOrder> orders = [
    ApotekOrder(
      id: 'ORD-0124',
      patientName: 'Budi Santoso',
      patientInitials: 'BS',
      patientAge: 42,
      patientGender: 'Laki-laki',
      patientAddress: 'Jalan Merpati 45 Madiun',
      timeText: '10 menit lalu',
      recipeRef: 'RX-00110',
      doctorName: 'Dr. Andi Wijaya',
      recipeDate: '1 Juni 2025',
      status: ApotekOrderStatus.menunggu,
      items: [
        const ApotekOrderItem(
          medicineName: 'Paracetamol 500 mg',
          formAndPack: 'Tablet • 10 tablet',
          qtyText: '2 Tablet',
        ),
        const ApotekOrderItem(
          medicineName: 'Amoxicillin 500 mg',
          formAndPack: 'Kapsul • 30 kapsul',
          qtyText: '1 Tablet',
        ),
      ],
    ),
    ApotekOrder(
      id: 'ORD-0123',
      patientName: 'Siti Aminah',
      patientInitials: 'SA',
      patientAge: 38,
      patientGender: 'Perempuan',
      patientAddress: 'Jl. Ahmad Yani No. 12 Malang',
      timeText: '25 menit lalu',
      recipeRef: 'RX-00109',
      doctorName: 'Dr. Dwi Lestari',
      recipeDate: '1 Juni 2025',
      status: ApotekOrderStatus.diproses,
      items: [
        const ApotekOrderItem(
          medicineName: 'Candesartan 8 mg',
          formAndPack: 'Tablet • 10 tablet',
          qtyText: '10 Tablet',
        ),
        const ApotekOrderItem(
          medicineName: 'Furosemide 40 mg',
          formAndPack: 'Tablet • 5 tablet',
          qtyText: '5 Tablet',
        ),
      ],
    ),
    ApotekOrder(
      id: 'ORD-0120',
      patientName: 'Ahmad Hidayat',
      patientInitials: 'AH',
      patientAge: 45,
      patientGender: 'Laki-laki',
      patientAddress: 'Jl. Hayam Wuruk No. 88 Malang',
      timeText: '1 jam lalu',
      recipeRef: 'RX-00105',
      doctorName: 'Dr. Andi Pratama',
      recipeDate: '31 Mei 2025',
      status: ApotekOrderStatus.selesai,
      items: [
        const ApotekOrderItem(
          medicineName: 'Ketosteril 600 mg',
          formAndPack: 'Kaplet • 20 kaplet',
          qtyText: '20 Kaplet',
        ),
      ],
    ),
  ];

  static final List<ApotekRecipe> recipes = [
    ApotekRecipe(
      id: 'RSP-00125',
      patientName: 'Budi Santoso',
      patientInitials: 'BS',
      medRecNo: '#RM-48291',
      doctorName: 'dr. Andi Pratama',
      dateText: '31 Agustus 2026',
      timeText: '10 menit lalu',
      status: ApotekRecipeStatus.belumDiverifikasi,
      items: [
        const ApotekRecipeItem(
          medicineName: 'Paracetamol 500 mg',
          formAndPack: 'Tablet • 10 tablet',
          doseRule: '3 x 1 tablet',
          usageNotes: 'Aturan Pakai: Sesudah Makan',
          qtyText: '2 Tablet',
        ),
        const ApotekRecipeItem(
          medicineName: 'Amoxicillin 500 mg',
          formAndPack: 'Kapsul • 30 kapsul',
          doseRule: '3 x 1 kapsul',
          usageNotes: 'Aturan Pakai: Sesudah Makan (Habiskan)',
          qtyText: '1 Tablet',
        ),
      ],
    ),
    ApotekRecipe(
      id: 'RSP-00123',
      patientName: 'Siti Aminah',
      patientInitials: 'SA',
      medRecNo: '#RM-48280',
      doctorName: 'dr. Dwi Lestari',
      dateText: '31 Agustus 2026',
      timeText: '20 menit lalu',
      status: ApotekRecipeStatus.diverifikasi,
      verifiedTime: '31 Agustus 2026, 22:15',
      items: [
        const ApotekRecipeItem(
          medicineName: 'Candesartan 8 mg',
          formAndPack: 'Tablet • 10 tablet',
          doseRule: '1 x 1 tablet',
          usageNotes: 'Aturan Pakai: Sesudah Makan',
          qtyText: '10 Tablet',
        ),
      ],
    ),
    ApotekRecipe(
      id: 'RSP-00118',
      patientName: 'Hendra Kurniawan',
      patientInitials: 'HK',
      medRecNo: '#RM-48260',
      doctorName: 'dr. Andi Pratama',
      dateText: '30 Agustus 2026',
      timeText: '1 hari lalu',
      status: ApotekRecipeStatus.selesai,
      verifiedTime: '30 Agustus 2026, 14:00',
      completedTime: '30 Agustus 2026, 15:30',
      items: [
        const ApotekRecipeItem(
          medicineName: 'Furosemide 40 mg',
          formAndPack: 'Tablet • 5 tablet',
          doseRule: '1 x 1 tablet',
          usageNotes: 'Aturan Pakai: Pagi hari, Sesudah Makan',
          qtyText: '5 Tablet',
        ),
      ],
    ),
  ];

  static final List<ApotekMedicine> medicines = [
    ApotekMedicine(
      id: '#MED-8842',
      name: 'Paracetamol 500 mg',
      category: 'Analgesik & Antipiretik',
      form: 'Tablet',
      dose: '500 mg',
      packageUnit: 'Strip / Box',
      stock: 120,
      stockUnit: 'Tablet',
      buyPrice: 3500,
      sellPrice: 5000,
      expDate: '12 Des 2027',
      usageRule: 'Diminum 3 kali sehari 1 tablet sesudah makan bila demam/nyeri.',
      batches: [
        const ApotekMedicineBatch(
          batchNo: 'BATCH-2024-K12',
          qtyText: '70 Tablet',
          expDate: '14 Okt 2026',
          status: 'Tersedia',
        ),
        const ApotekMedicineBatch(
          batchNo: 'BATCH-2024-J09',
          qtyText: '50 Tablet',
          expDate: '22 Agu 2026',
          status: 'Tersedia',
        ),
      ],
    ),
    ApotekMedicine(
      id: '#MED-8843',
      name: 'Amoxicillin 500 mg',
      category: 'Antibiotik Penicillin',
      form: 'Kapsul',
      dose: '500 mg',
      packageUnit: 'Strip / Box',
      stock: 8,
      stockUnit: 'Strip',
      buyPrice: 8500,
      sellPrice: 12000,
      expDate: '12 Des 2027',
      usageRule: 'Harus dihabiskan sesuai anjuran dokter untuk mencegah resistensi.',
      batches: [
        const ApotekMedicineBatch(
          batchNo: 'BATCH-2024-A01',
          qtyText: '8 Strip',
          expDate: '12 Des 2027',
          status: 'Stok Menipis',
        ),
      ],
    ),
    ApotekMedicine(
      id: '#MED-8844',
      name: 'Omeprazole 20 mg',
      category: 'Antasida & Antirefluks',
      form: 'Kapsul',
      dose: '20 mg',
      packageUnit: 'Strip / Box',
      stock: 0,
      stockUnit: 'Box',
      buyPrice: 28000,
      sellPrice: 35000,
      expDate: '12 Des 2027',
      usageRule: 'Diminum 30 menit sebelum sarapan pagi.',
      batches: [],
    ),
  ];

  static final List<ApotekActivity> activities = [
    const ApotekActivity(
      id: 'act-1',
      title: 'Memperbaiki Stok Obat',
      subtitle: 'Paracetamol 500 mg • Stok: 100 -> 120 Tablet',
      timeText: '14:10 WIB',
      type: 'stok',
    ),
    const ApotekActivity(
      id: 'act-2',
      title: 'Menambahkan Obat',
      subtitle: 'Cetirizine 10 mg • Registrasi obat baru ke katalog apotek',
      timeText: '31 Agu, 14:10 WIB',
      type: 'obat',
    ),
    const ApotekActivity(
      id: 'act-3',
      title: 'Memproses Pesanan',
      subtitle: 'TRX-2026-00981 (Andi Pratama) • Pesanan siap diserahkan ke kurir',
      timeText: '13:10 WIB',
      type: 'pesanan',
    ),
  ];

  static final List<ApotekDaySchedule> schedules = [
    ApotekDaySchedule(dayName: 'Senin', shortDay: 'S', isOpen: true, openTime: '08:00 AM', closeTime: '09:00 PM'),
    ApotekDaySchedule(dayName: 'Selasa', shortDay: 'S', isOpen: true, openTime: '08:00 AM', closeTime: '09:00 PM'),
    ApotekDaySchedule(dayName: 'Rabu', shortDay: 'R', isOpen: true, openTime: '08:00 AM', closeTime: '09:00 PM'),
    ApotekDaySchedule(dayName: 'Kamis', shortDay: 'K', isOpen: true, openTime: '08:00 AM', closeTime: '09:00 PM'),
    ApotekDaySchedule(dayName: 'Jumat', shortDay: 'J', isOpen: true, openTime: '08:00 AM', closeTime: '09:00 PM'),
    ApotekDaySchedule(dayName: 'Sabtu', shortDay: 'S', isOpen: true, openTime: '09:00 AM', closeTime: '06:00 PM'),
    ApotekDaySchedule(dayName: 'Minggu', shortDay: 'M', isOpen: false, openTime: '08:00 AM', closeTime: '05:00 PM'),
  ];

  static final List<ApotekCoverageArea> areas = [
    ApotekCoverageArea(name: 'Kota Malang', details: '5 Kecamatan • 57 Kelurahan', isActive: true),
    ApotekCoverageArea(name: 'Kabupaten Malang', details: '33 Kecamatan • Radius Utama', isActive: true),
    ApotekCoverageArea(name: 'Kota Batu', details: '3 Kecamatan • Akses Prioritas', isActive: true),
    ApotekCoverageArea(name: 'Kabupaten Pasuruan', details: '24 Kecamatan • Pengiriman Ekspres', isActive: false),
    ApotekCoverageArea(name: 'Kota Blitar', details: '3 Kecamatan • Hub Pengiriman Selatan', isActive: false),
    ApotekCoverageArea(name: 'Kabupaten Blitar', details: '22 Kecamatan • Jalur Kurir Reguler', isActive: false),
    ApotekCoverageArea(name: 'Kota Kediri', details: '3 Kecamatan • Distribusi Obat Siaga', isActive: false),
  ];

  static final List<ApotekNotification> notifications = [
    ApotekNotification(
      id: 'notif-1',
      title: 'Pesanan Resep Baru Masuk',
      body: 'Resep baru RSP-00125 dari dr. Andi Pratama untuk pasien Budi Santoso.',
      time: '10 menit lalu',
      isRead: false,
      type: 'resep',
    ),
    ApotekNotification(
      id: 'notif-2',
      title: 'Pesanan Siap Diproses',
      body: 'Pesanan ORD-0124 (Budi Santoso) menunggu untuk disiapkan obatnya.',
      time: '25 menit lalu',
      isRead: false,
      type: 'pesanan',
    ),
    ApotekNotification(
      id: 'notif-3',
      title: 'Peringatan Stok Menipis',
      body: 'Stok Amoxicillin 500 mg tersisa 8 Strip. Segera lakukan pengadaan.',
      time: '1 jam lalu',
      isRead: true,
      type: 'stok',
    ),
    ApotekNotification(
      id: 'notif-4',
      title: 'Pengingat Kedaluwarsa',
      body: 'Batch Paracetamol 500 mg (BATCH-2024-J09) kedaluwarsa dalam 3 bulan.',
      time: 'Kemarin',
      isRead: true,
      type: 'sistem',
    ),
  ];

  static final List<ApotekFaqItem> faqList = [
    const ApotekFaqItem(
      id: 'faq-1',
      question: 'Bagaimana cara memverifikasi resep?',
      overview: 'Verifikasi resep memastikan keamanan pasien dan keabsahan instruksi terapi dari dokter sebelum obat disiapkan oleh staf apotek.',
      steps: [
        ApotekFaqStep(stepNumber: 1, title: 'Buka menu Verifikasi Resep', description: 'Pilih tab atau modul verifikasi resep pada dashboard apoteker.'),
        ApotekFaqStep(stepNumber: 2, title: 'Pilih resep yang masuk', description: 'Klik pada antrean resep dengan status "Menunggu Verifikasi".'),
        ApotekFaqStep(stepNumber: 3, title: 'Periksa data pasien dan dokter', description: 'Validasi nama, nomor rekam medis (SIP dokter), dan dosis terapeutik.'),
        ApotekFaqStep(stepNumber: 4, title: 'Pastikan resep sesuai', description: 'Pastikan ketersediaan stok, aturan pakai (signa), serta tidak ada kontraindikasi.'),
        ApotekFaqStep(stepNumber: 5, title: 'Klik "Verifikasi"', description: 'Tekan tombol hijau untuk menyetujui dan memproses resep ke tahap penyiapan.'),
      ],
      tipTitle: 'TIPS APOTEKER',
      tipBody: 'Selalu cocokkan riwayat alergi pasien sebelum menekan tombol Verifikasi. Bila terdapat keraguan interaksi obat, hubungi dokter penulis resep langsung melalui tombol konsultasi cepat.',
    ),
    const ApotekFaqItem(
      id: 'faq-2',
      question: 'Bagaimana cara memperbarui stok obat?',
      overview: 'Pembaruan data stok secara berkala membantu mencegah terjadinya pembatalan pesanan akibat obat habis dan menjaga kepercayaan pasien.',
      steps: [
        ApotekFaqStep(stepNumber: 1, title: 'Buka menu Stok Obat', description: 'Akses panel utama apotek dan pilih menu pengelolaan stok fisik obat.'),
        ApotekFaqStep(stepNumber: 2, title: 'Pilih obat', description: 'Cari berdasarkan nama obat, merek dagang, atau nomor barcode produk.'),
        ApotekFaqStep(stepNumber: 3, title: 'Klik "Perbarui Stok"', description: 'Pilih tombol perbarui stok pada rincian data obat yang dipilih.'),
        ApotekFaqStep(stepNumber: 4, title: 'Masukkan jumlah stok terbaru', description: 'Ketik jumlah unit obat fisik yang tersedia di lemari penyimpanan apotek.'),
        ApotekFaqStep(stepNumber: 5, title: 'Klik "Simpan"', description: 'Sistem akan segera memperbarui ketersediaan obat secara real-time di aplikasi pasien.'),
      ],
      tipTitle: 'TIPS PENGELOLAAN STOK',
      tipBody: 'Aktifkan fitur pemberitahuan batas minimum stok agar Anda mendapat peringatan otomatis ketika sisa obat berada di bawah 10 unit.',
    ),
    const ApotekFaqItem(
      id: 'faq-3',
      question: 'Apa yang harus dilakukan jika pesanan dibatalkan pasien?',
      overview: 'Panduan langkah untuk mengonfirmasi pembatalan pesanan oleh pasien agar stok ter-rollback secara otomatis dan pencatatan kas tetap akurat.',
      steps: [
        ApotekFaqStep(stepNumber: 1, title: 'Buka menu Pesanan', description: 'Masuk ke daftar seluruh transaksi pemesanan apotek pada bilah navigasi.'),
        ApotekFaqStep(stepNumber: 2, title: 'Pilih pesanan yang dibatalkan', description: 'Klik pesanan yang berstatus "Permintaan Pembatalan" atau belum diambil.'),
        ApotekFaqStep(stepNumber: 3, title: 'Klik "Batalkan Pesanan"', description: 'Pilih tombol tindakan penyesuaian status pembatalan di detail pesanan.'),
        ApotekFaqStep(stepNumber: 4, title: 'Pilih alasan pembatalan', description: 'Tentukan alasan yang sesuai (misal: permintaan pasien, alamat tidak valid, dll.).'),
        ApotekFaqStep(stepNumber: 5, title: 'Klik "Konfirmasi"', description: 'Konfirmasi pembatalan. Dana pasien akan diproses refund otomatis jika sudah bayar.'),
      ],
      tipTitle: 'PENGEMBALIAN STOK OTOMATIS',
      tipBody: 'Setelah konfirmasi pembatalan selesai, sistem GIAT secara otomatis mengembalikan jumlah obat yang sempat dipesan kembali ke kuota stok siap jual.',
    ),
    const ApotekFaqItem(
      id: 'faq-4',
      question: 'Apa yang dilakukan jika obat tidak tersedia?',
      overview: 'Ikuti prosedur resmi ini untuk memberikan obat substitusi berizin atau memberikan opsi tindak lanjut yang aman kepada pasien.',
      steps: [
        ApotekFaqStep(stepNumber: 1, title: 'Buka pesanan terkait', description: 'Temukan nomor pesanan yang memuat obat yang saat ini habis di lemari stok.'),
        ApotekFaqStep(stepNumber: 2, title: 'Pilih "Obat Tidak Tersedia"', description: 'Tandai item obat spesifik pada daftar rincian sebagai "Stok Kosong".'),
        ApotekFaqStep(stepNumber: 3, title: 'Pilih alternatif obat jika tersedia', description: 'Rekomendasikan obat generik atau merek lain dengan zat aktif dan dosis identik.'),
        ApotekFaqStep(stepNumber: 4, title: 'Tambahkan catatan untuk pasien', description: 'Berikan penjelasan santun mengenai perbedaan harga atau kemasan bila relevan.'),
        ApotekFaqStep(stepNumber: 5, title: 'Klik "Kirim Notifikasi"', description: 'Pasien akan menerima konfirmasi persetujuan alternatif langsung di aplikasi mereka.'),
      ],
      tipTitle: 'KEPATUHAN MEDIS',
      tipBody: 'Penggantian obat berlogo \'Keras\' (Lingkaran Merah K) wajib memperoleh persetujuan konfirmasi tertulis dari pasien dan dokter terkait sebelum diserahkan.',
    ),
    const ApotekFaqItem(
      id: 'faq-5',
      question: 'Bagaimana cara mengubah status layanan apotek?',
      overview: 'Atur status operasional apotek Anda agar pasien mengetahui ketersediaan penerimaan resep dan tebus obat secara real-time.',
      steps: [
        ApotekFaqStep(stepNumber: 1, title: 'Buka menu Pengaturan Layanan', description: 'Masuk ke tab Pengaturan pada profil apotek Anda.'),
        ApotekFaqStep(stepNumber: 2, title: 'Pilih Status Layanan', description: 'Tekan kartu Status Layanan untuk melihat opsi ketersediaan apotek.'),
        ApotekFaqStep(stepNumber: 3, title: 'Pilih Aktif / Tidak Aktif / Maintenance', description: 'Tentukan kondisi terkini (Aktif untuk melayani, Tidak Aktif di luar jam kerja, atau Maintenance saat stock opname).'),
        ApotekFaqStep(stepNumber: 4, title: 'Tambahkan catatan jika diperlukan', description: 'Tulis pesan singkat untuk pasien (contoh: "Tutup sementara, buka kembali pkl 14:00").'),
        ApotekFaqStep(stepNumber: 5, title: 'Klik "Simpan"', description: 'Perubahan status langsung ditampilkan pada pencarian apotek terdekat bagi pasien.'),
      ],
      tipTitle: 'PENGATURAN JADWAL OTOMATIS',
      tipBody: 'Gunakan fitur "Jadwal Jam Operasional Otomatis" agar status apotek berganti otomatis menjadi Aktif/Tidak Aktif sesuai jam operasional harian Anda tanpa perlu diubah secara manual.',
    ),
    const ApotekFaqItem(
      id: 'faq-6',
      question: 'Bagaimana cara melihat riwayat resep?',
      overview: 'Pelajari cara meninjau arsip resep dokter yang pernah Anda verifikasi atau tolak sebelumnya untuk keperluan audit obat dan pencatatan farmasi.',
      steps: [
        ApotekFaqStep(stepNumber: 1, title: 'Buka menu Riwayat Verifikasi', description: 'Akses tab Riwayat Verifikasi dari navigasi modul resep.'),
        ApotekFaqStep(stepNumber: 2, title: 'Gunakan filter tanggal / status', description: 'Saring berdasarkan rentang tanggal tertentu atau status ("Disetujui" / "Ditolak").'),
        ApotekFaqStep(stepNumber: 3, title: 'Lihat daftar resep', description: 'Daftar resep yang cocok akan ditampilkan berurutan dari yang paling baru.'),
        ApotekFaqStep(stepNumber: 4, title: 'Klik resep untuk melihat detail verifikasi', description: 'Tekan salah satu resep untuk meninjau rincian obat, telaah resep, serta tanda tangan digital apoteker.'),
      ],
      tipTitle: 'EKSPOR DOKUMEN MEDIS',
      tipBody: 'Anda dapat mengunduh salinan berkas resep digital dan riwayat telaah apoteker dalam format PDF resmi dengan menekan tombol "Unduh Berkas Telaah" di sudut kanan atas layar detail.',
    ),
  ];

  /// Business flow: Apotek accepts doctor recipe
  /// 1. Updates recipe status to diverifikasi
  /// 2. Automatically creates and inserts a new order into MENUNGGU queue
  static ApotekOrder acceptRecipeAndCreateOrder(ApotekRecipe recipe) {
    recipe.status = ApotekRecipeStatus.diverifikasi;
    recipe.verifiedTime = '31 Agustus 2026, 22:15';

    // Generate matching order ID
    final orderId = 'ORD-${recipe.id.replaceAll('RSP-', '')}';

    // Check if already created
    final existingIndex = orders.indexWhere((o) => o.id == orderId || o.recipeRef == recipe.id);
    if (existingIndex != -1) {
      return orders[existingIndex];
    }

    final newOrder = ApotekOrder(
      id: orderId,
      patientName: recipe.patientName,
      patientInitials: recipe.patientInitials,
      patientAge: 42,
      patientGender: 'Laki-laki',
      patientAddress: 'Jalan Merpati 45 Madiun',
      timeText: 'Baru saja',
      recipeRef: recipe.id,
      doctorName: recipe.doctorName,
      recipeDate: recipe.dateText,
      status: ApotekOrderStatus.menunggu,
      items: recipe.items.map((it) => ApotekOrderItem(
        medicineName: it.medicineName,
        formAndPack: it.formAndPack,
        qtyText: it.qtyText,
        isAvailable: true,
      )).toList(),
    );

    orders.insert(0, newOrder);

    // Record activity
    activities.insert(0, ApotekActivity(
      id: 'act-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Menerima Resep Dokter',
      subtitle: '${recipe.id} (${recipe.patientName}) • Resep diverifikasi & masuk antrean pesanan',
      timeText: 'Baru saja',
      type: 'resep',
    ));

    return newOrder;
  }

  static void addMedicine(ApotekMedicine med) {
    medicines.insert(0, med);
    activities.insert(0, ApotekActivity(
      id: 'act-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Menambahkan Obat Baru',
      subtitle: '${med.name} • Registrasi obat baru ke katalog apotek',
      timeText: 'Baru saja',
      type: 'obat',
    ));
  }

  static void addStockBatch({
    required String medicineId,
    required String batchNo,
    required String expDate,
    required int quantity,
    required int buyPrice,
    required int sellPrice,
  }) {
    final med = medicines.firstWhere((m) => m.id == medicineId);
    final beforeStock = med.stock;
    med.stock += quantity;
    med.batches.insert(0, ApotekMedicineBatch(
      batchNo: batchNo,
      qtyText: '$quantity ${med.stockUnit}',
      expDate: expDate,
      status: 'Tersedia',
    ));

    activities.insert(0, ApotekActivity(
      id: 'act-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Memperbarui Stok Obat',
      subtitle: '${med.name} • Stok: $beforeStock -> ${med.stock} ${med.stockUnit}',
      timeText: 'Baru saja',
      type: 'stok',
    ));
  }
}
