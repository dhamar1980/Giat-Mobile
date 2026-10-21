/// Model data sinyal video call realtime (Firebase RTDB Signaling)
class CallSignalModel {
  final String status; // 'ringing' | 'accepted' | 'rejected' | 'ended' | 'busy'
  final String callerId;
  final String callerName;
  final String callerRole; // 'dokter' | 'pasien'
  final String roomId;
  final String? videoCallUrl;
  final int? timestamp;

  CallSignalModel({
    required this.status,
    required this.callerId,
    required this.callerName,
    this.callerRole = 'dokter',
    required this.roomId,
    this.videoCallUrl,
    this.timestamp,
  });

  factory CallSignalModel.fromMap(Map<dynamic, dynamic> map) {
    return CallSignalModel(
      status: map['status']?.toString() ?? '',
      callerId: (map['caller_id'] ?? map['id_caller'])?.toString() ?? '',
      callerName: (map['caller_name'] ?? map['nama_caller'])?.toString() ?? 'Lawan Bicara',
      callerRole: (map['caller_role'] ?? map['role'])?.toString() ?? 'dokter',
      roomId: (map['room_id'] ?? map['room'])?.toString() ?? '',
      videoCallUrl: (map['video_call_url'] ?? map['url'])?.toString(),
      timestamp: map['timestamp'] is int
          ? map['timestamp'] as int
          : int.tryParse(map['timestamp']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'caller_id': callerId,
      'caller_name': callerName,
      'caller_role': callerRole,
      'room_id': roomId,
      if (videoCallUrl != null) 'video_call_url': videoCallUrl,
      'timestamp': timestamp ?? DateTime.now().millisecondsSinceEpoch,
    };
  }
}
