/// Model data pesan chat konsultasi realtime (Firebase RTDB & REST API)
class ChatMessage {
  final String id;
  final String idSender;
  final String senderName;
  final String senderRole; // 'pasien' | 'dokter'
  final String pesan;
  final String tipe; // 'text' | 'image' | 'prescription' | 'call'
  final String? attachmentUrl;
  final String createdAt;

  ChatMessage({
    required this.id,
    required this.idSender,
    required this.senderName,
    required this.senderRole,
    required this.pesan,
    this.tipe = 'text',
    this.attachmentUrl,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<dynamic, dynamic> map) {
    return ChatMessage(
      id: (map['id'] ?? map['message_id'] ?? map['id_pesan'])?.toString() ?? '',
      idSender: (map['id_sender'] ?? map['id_pengirim'] ?? map['sender_id'] ?? map['user_id'])?.toString() ?? '',
      senderName: (map['sender_name'] ?? map['nama_pengirim'] ?? map['user_name'] ?? map['name'] ?? map['nama'])?.toString() ?? 'Pengguna',
      senderRole: (map['sender_role'] ?? map['role'])?.toString() ?? 'pasien',
      pesan: (map['pesan'] ?? map['message'] ?? map['text'] ?? map['isi_pesan'])?.toString() ?? '',
      tipe: (map['tipe'] ?? map['type'])?.toString() ?? 'text',
      attachmentUrl: (map['attachment_url'] ?? map['attachment'])?.toString(),
      createdAt: (map['created_at'] ?? map['waktu'] ?? map['time'] ?? map['timestamp'])?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_sender': idSender,
      'sender_name': senderName,
      'sender_role': senderRole,
      'pesan': pesan,
      'tipe': tipe,
      'attachment_url': attachmentUrl,
      'created_at': createdAt,
    };
  }
}
