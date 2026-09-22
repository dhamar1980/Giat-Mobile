// ─────────────────────────────────────────────────────────────────────────────
// MODEL DATA DOKTER (Berdasarkan Desain & Alur Figma GIAT)
// ─────────────────────────────────────────────────────────────────────────────

class DokterPatient {
  final String id;
  final String name;
  final String initials;
  final int age;
  final String gender;
  final String address;
  final double weightKg;
  final double heightM;
  final String condition;
  final String complaint;
  final String complaintDetail;
  final List<DokterPrescriptionItem> currentMedicines;

  const DokterPatient({
    required this.id,
    required this.name,
    required this.initials,
    required this.age,
    required this.gender,
    required this.address,
    required this.weightKg,
    required this.heightM,
    required this.condition,
    required this.complaint,
    required this.complaintDetail,
    required this.currentMedicines,
  });
}

class DokterPrescriptionItem {
  final String id;
  final String medicineName;
  final String dose;
  final String frequency;
  final String quantity;
  final String duration;
  final String usageTime; // e.g. "Sesudah Makan", "Pagi hari, Sesudah Makan"
  final String? specialNotes;

  const DokterPrescriptionItem({
    required this.id,
    required this.medicineName,
    required this.dose,
    required this.frequency,
    required this.quantity,
    required this.duration,
    required this.usageTime,
    this.specialNotes,
  });

  DokterPrescriptionItem copyWith({
    String? id,
    String? medicineName,
    String? dose,
    String? frequency,
    String? quantity,
    String? duration,
    String? usageTime,
    String? specialNotes,
  }) {
    return DokterPrescriptionItem(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      dose: dose ?? this.dose,
      frequency: frequency ?? this.frequency,
      quantity: quantity ?? this.quantity,
      duration: duration ?? this.duration,
      usageTime: usageTime ?? this.usageTime,
      specialNotes: specialNotes ?? this.specialNotes,
    );
  }
}

enum KonsultasiStatus {
  berlangsung,
  terjadwal,
  selesai,
}

class DokterConsultation {
  final String id;
  final String patientName;
  final String initials;
  final KonsultasiStatus status;
  final String scheduledTimeText; // e.g. "14:00 WIB" / "Hari ini, 15:30 WIB" / "19 - 09 - 2026"
  final int messageCount;
  final String lastMessage;
  final String lastTime;
  final String patientId;

  const DokterConsultation({
    required this.id,
    required this.patientName,
    required this.initials,
    required this.status,
    required this.scheduledTimeText,
    required this.messageCount,
    required this.lastMessage,
    required this.lastTime,
    required this.patientId,
  });
}

class DokterScheduleItem {
  final String id;
  final String time;
  final String patientName;
  final String status; // "Selesai" | "Aktif" | "Mendatang"
  final String serviceType;
  final String patientId;

  const DokterScheduleItem({
    required this.id,
    required this.time,
    required this.patientName,
    required this.status,
    this.serviceType = 'Chat Konsultasi',
    required this.patientId,
  });
}

class DokterNotificationItem {
  final String id;
  final String title;
  final String senderOrCategory;
  final String timeText;
  final String initials;
  final String type; // "konsultasi" | "jadwal" | "sistem"

  const DokterNotificationItem({
    required this.id,
    required this.title,
    required this.senderOrCategory,
    required this.timeText,
    required this.initials,
    required this.type,
  });
}

class DokterDeviceSession {
  final String id;
  final String deviceName;
  final String lastActive;
  final String location;
  final bool isCurrent;

  const DokterDeviceSession({
    required this.id,
    required this.deviceName,
    required this.lastActive,
    required this.location,
    required this.isCurrent,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA AWAL (SESUAI DOKUMEN FIGMA)
// ─────────────────────────────────────────────────────────────────────────────

class DokterMockData {
  static final List<DokterPrescriptionItem> initialPrescriptions = [
    const DokterPrescriptionItem(
      id: 'rx-1',
      medicineName: 'Candesartan 8mg',
      dose: '8mg',
      frequency: '1 x 1 hari',
      quantity: '10 Tablet',
      duration: '10 hari',
      usageTime: 'Sesudah Makan',
      specialNotes: 'Minum teratur di waktu yang sama setiap hari.',
    ),
    const DokterPrescriptionItem(
      id: 'rx-2',
      medicineName: 'Furosemide 40mg',
      dose: '40mg',
      frequency: '1 x 1 hari',
      quantity: '5 Tablet',
      duration: '5 hari',
      usageTime: 'Pagi hari, Sesudah Makan',
      specialNotes: 'Dianjurkan diminum di pagi hari.',
    ),
  ];

  static final List<DokterPatient> patients = [
    DokterPatient(
      id: 'p-1',
      name: 'Budi Santoso',
      initials: 'BS',
      age: 42,
      gender: 'Laki-laki',
      address: 'Jalan Merpati 45 Madiun',
      weightKg: 65,
      heightM: 1.70,
      condition: 'Perlu Pengawasan',
      complaint: 'Follow-up CKD Stage 3',
      complaintDetail: 'Pasien mengeluhkan mudah lelah dan ingin konsultasi mengenai hasil pemeriksaan lab ginjal terbaru.',
      currentMedicines: initialPrescriptions,
    ),
    DokterPatient(
      id: 'p-2',
      name: 'Siti Wijaya',
      initials: 'SW',
      age: 42,
      gender: 'Perempuan',
      address: 'Jalan Merpati 45 Madiun',
      weightKg: 48,
      heightM: 1.60,
      condition: 'Kurang Baik',
      complaint: 'Mudah Lelah',
      complaintDetail: 'Keluhan Pasien kepada dokter: badan terasa lemas sejak 3 hari terakhir, nafsu makan berkurang, dan ada bengkak ringan di pergelangan kaki.',
      currentMedicines: [
        const DokterPrescriptionItem(
          id: 'rx-sw-1',
          medicineName: 'Candesartan 8mg',
          dose: '8mg',
          frequency: '1 x 1',
          quantity: '10 Tablet',
          duration: '10 hari',
          usageTime: 'Sesudah Makan',
        ),
        const DokterPrescriptionItem(
          id: 'rx-sw-2',
          medicineName: 'Furosemide 40mg',
          dose: '40mg',
          frequency: '1 x 1',
          quantity: '5 Tablet',
          duration: '5 hari',
          usageTime: 'Pagi hari, Sesudah Makan',
        ),
      ],
    ),
    const DokterPatient(
      id: 'p-3',
      name: 'Lina Norvita',
      initials: 'LN',
      age: 38,
      gender: 'Perempuan',
      address: 'Jl. Ahmad Yani No. 18 Jember',
      weightKg: 52,
      heightM: 1.58,
      condition: 'Stabil',
      complaint: 'Kontrol Rutin',
      complaintDetail: 'Pemeriksaan rutin tekanan darah dan fungsi ginjal bulanan.',
      currentMedicines: [],
    ),
    const DokterPatient(
      id: 'p-4',
      name: 'Lestari Putri',
      initials: 'LP',
      age: 35,
      gender: 'Perempuan',
      address: 'Jl. Mastrip Timur No. 12',
      weightKg: 55,
      heightM: 1.62,
      condition: 'Stabil',
      complaint: 'Evaluasi Terapi Obat',
      complaintDetail: 'Mengevaluasi efek samping obat antihipertensi yang dikonsumsi.',
      currentMedicines: [],
    ),
    const DokterPatient(
      id: 'p-5',
      name: 'Hendra Kurniawan',
      initials: 'HK',
      age: 45,
      gender: 'Laki-laki',
      address: 'Jl. Hayam Wuruk No. 88',
      weightKg: 70,
      heightM: 1.72,
      condition: 'Membaik',
      complaint: 'Pasca Rawat Inap',
      complaintDetail: 'Kondisi ureum dan kreatinin menunjukkan tren perbaikan signifikan.',
      currentMedicines: [],
    ),
  ];

  static final List<DokterConsultation> consultations = [
    const DokterConsultation(
      id: 'c-1',
      patientName: 'Budi Santoso',
      initials: 'BS',
      status: KonsultasiStatus.berlangsung,
      scheduledTimeText: '14:00 WIB',
      messageCount: 2,
      lastMessage: '“Dok, saya sudah mengirim hasil lab”',
      lastTime: '2 menit',
      patientId: 'p-1',
    ),
    const DokterConsultation(
      id: 'c-2',
      patientName: 'Lestari Putri',
      initials: 'LP',
      status: KonsultasiStatus.terjadwal,
      scheduledTimeText: 'Hari ini, 15:30 WIB',
      messageCount: 0,
      lastMessage: 'Konsultasi Terjadwal',
      lastTime: '15:30',
      patientId: 'p-4',
    ),
    const DokterConsultation(
      id: 'c-3',
      patientName: 'Lesti Purnama',
      initials: 'LP',
      status: KonsultasiStatus.terjadwal,
      scheduledTimeText: 'Hari ini, 17:30 WIB',
      messageCount: 0,
      lastMessage: 'Konsultasi Terjadwal',
      lastTime: '17:30',
      patientId: 'p-4',
    ),
    const DokterConsultation(
      id: 'c-4',
      patientName: 'Hendra Kurniawan',
      initials: 'HK',
      status: KonsultasiStatus.selesai,
      scheduledTimeText: '19 - 09 - 2026',
      messageCount: 14,
      lastMessage: 'Terima kasih atas sarannya, Dok.',
      lastTime: 'Selesai',
      patientId: 'p-5',
    ),
  ];

  static final List<DokterScheduleItem> schedules = [
    const DokterScheduleItem(
      id: 'sch-1',
      time: '09:00',
      patientName: 'Siti Wijaya',
      status: 'Selesai',
      patientId: 'p-2',
    ),
    const DokterScheduleItem(
      id: 'sch-2',
      time: '10:00',
      patientName: 'Siti Rahmawati',
      status: 'Aktif',
      patientId: 'p-2',
    ),
    const DokterScheduleItem(
      id: 'sch-3',
      time: '11:00',
      patientName: 'Andi Wijaya',
      status: 'Mendatang',
      patientId: 'p-1',
    ),
  ];

  static final List<DokterNotificationItem> notifications = [
    const DokterNotificationItem(
      id: 'notif-1',
      title: 'Konsultasi Baru',
      senderOrCategory: 'Hermanto Kurniawan',
      timeText: 'Waktu Konsultasi: 19 - 09 - 2026',
      initials: 'HK',
      type: 'konsultasi',
    ),
    const DokterNotificationItem(
      id: 'notif-2',
      title: 'Jadwal konsultasi',
      senderOrCategory: 'Hermanto Kurniawan',
      timeText: '15 menit yang akan datang',
      initials: 'HK',
      type: 'jadwal',
    ),
    const DokterNotificationItem(
      id: 'notif-3',
      title: 'Update Sistem',
      senderOrCategory: 'Perbaikan bug pada bagian profile',
      timeText: '30 menit lalu',
      initials: 'US',
      type: 'sistem',
    ),
  ];

  static final List<DokterDeviceSession> devices = [
    const DokterDeviceSession(
      id: 'dev-1',
      deviceName: 'Smartphoone Android',
      lastActive: 'Terakhir aktif hari ini, 18:42 WIB',
      location: 'Lokasi: Indonesia',
      isCurrent: true,
    ),
    const DokterDeviceSession(
      id: 'dev-2',
      deviceName: 'Iphone 18',
      lastActive: 'Terakhir aktif hari ini, 13:42 WIB',
      location: 'Lokasi: Malaysia',
      isCurrent: false,
    ),
  ];
}
