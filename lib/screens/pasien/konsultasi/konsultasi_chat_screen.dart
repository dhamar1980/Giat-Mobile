import 'dart:async';
import 'package:giat/widgets/giat_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'konsultasi_video_call_screen.dart';
import '../../../models/user_model.dart';
import '../../../models/chat_message_model.dart';
import '../../../models/call_signal_model.dart';
import '../../../services/konsultasi_api_service.dart';
import '../../../services/firebase_realtime_service.dart';
import '../../../services/jitsi_video_service.dart';
import '../../../services/ringtone_player.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/incoming_call_dialog.dart';
import '../../../widgets/typing_indicator_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// KONSULTASI CHAT SCREEN (Realtime Chat & Video Call GIAT Telemedicine)
// ─────────────────────────────────────────────────────────────────────────────

class KonsultasiChatScreen extends StatefulWidget {
  final String consultationId;
  final String doctorName;
  final String specialty;
  final String avatarUrl;

  const KonsultasiChatScreen({
    super.key,
    required this.consultationId,
    this.doctorName = 'Dokter GIAT',
    this.specialty = 'Spesialis Ginjal & Hipertensi',
    this.avatarUrl = 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=300',
  });

  @override
  State<KonsultasiChatScreen> createState() => _KonsultasiChatScreenState();
}

class _KonsultasiChatScreenState extends State<KonsultasiChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  static const _darkGreen = Color(0xFF065A37);
  static const _patientBubbleGreen = Color(0xFF065A37);

  final KonsultasiApiService _apiService = KonsultasiApiService();
  final FirebaseRealtimeService _firebaseService = FirebaseRealtimeService();
  final JitsiVideoService _jitsiService = JitsiVideoService();
  final RingtonePlayer _ringtonePlayer = RingtonePlayer();

  UserModel? _currentUser;
  late String _activeConsultationId;
  late String _doctorName;
  late String _specialty;
  late String _avatarUrl;
  bool _isLoadingMessages = true;

  StreamSubscription? _msgSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _callSub;
  Timer? _typingDebounce;

  bool _isDoctorTyping = false;
  bool _isIncomingCallModalShowing = false;
  DateTime? _callStartTime;

  late List<Map<String, dynamic>> _messages;

  @override
  void initState() {
    super.initState();
    _activeConsultationId = widget.consultationId.trim().isNotEmpty
        ? widget.consultationId.trim()
        : '2940f5ab-2a29-4860-983e-a0e7824c464e';

    _doctorName = widget.doctorName;
    _specialty = widget.specialty;
    _avatarUrl = widget.avatarUrl;
    if (_doctorName.toLowerCase().contains('realtime')) {
      _doctorName = 'dr. Budi Santoso, Sp.PD';
      _specialty = 'Dokter Spesialis Penyakit Dalam';
    }

    _messages = [];

    _initSessionAndListeners();
  }

  Future<void> _initSessionAndListeners() async {
    _currentUser = await StorageService().getUser();

    // 1. Langsung pasang realtime stream listener ke Firebase RTDB seketika tanpa menunggu REST API
    _setupRealtimeListeners();

    // 2. Ambil pesan dari Firebase RTDB secara paralel (sangat cepat, <100ms)
    _loadMessagesFromFirebase();

    // 3. Sinkronkan dari backend REST API di background untuk riwayat & info dokter terbaru
    _loadMessagesFromBackend();

    // 4. Auto-detect jika consultationId masih default atau kosong
    if (_activeConsultationId == '1' || _activeConsultationId.isEmpty || _activeConsultationId == 'demo') {
      _autoDetectActiveConsultation();
    }
  }

  Future<void> _autoDetectActiveConsultation() async {
    try {
      final riwayatRes = await _apiService.getRiwayatPasien();
      if (riwayatRes.success && riwayatRes.data != null && riwayatRes.data!.isNotEmpty && mounted) {
        dynamic chosen;
        for (var item in riwayatRes.data!) {
          if (item is Map) {
            final status = (item['status'] ?? item['status_konsultasi'] ?? '').toString().toLowerCase();
            final statusBayar = (item['status_pembayaran'] ?? item['status_bayar'] ?? '').toString().toLowerCase();
            if ((status == 'berlangsung' || status == 'aktif') && statusBayar == 'lunas') {
              chosen = item;
              break;
            }
          }
        }
        chosen ??= riwayatRes.data!.first;

        if (chosen is Map) {
          final detectedId = (chosen['id'] ?? chosen['id_konsultasi'] ?? chosen['konsultasi_id'])?.toString();
          if (detectedId != null && detectedId.isNotEmpty && detectedId != _activeConsultationId) {
            _activeConsultationId = detectedId;
            debugPrint('🔄 Auto-switched to active consultation ID: $_activeConsultationId');

            final doc = chosen['dokter'];
            if (doc is Map) {
              String docNama = (doc['nama'] ?? doc['name'] ?? '').toString();
              String docSpec = (doc['spesialisasi'] ?? doc['specialty'] ?? '').toString();
              String docAvatar = (doc['foto_profile'] ?? '').toString();
              if (docNama.toLowerCase().contains('realtime')) {
                docNama = 'dr. Budi Santoso, Sp.PD';
                docSpec = 'Dokter Spesialis Penyakit Dalam';
              }
              if (docNama.isNotEmpty) _doctorName = docNama;
              if (docSpec.isNotEmpty) _specialty = docSpec;
              if (docAvatar.isNotEmpty) _avatarUrl = docAvatar;
            }

            if (mounted) setState(() {});
            _setupRealtimeListeners();
            _loadMessagesFromFirebase();
            _loadMessagesFromBackend();
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Gagal auto-detect ID riwayat: $e');
    }
  }

  void _switchConsultationId(String newId) {
    if (newId.isEmpty || newId == _activeConsultationId) return;
    _msgSub?.cancel();
    _typingSub?.cancel();
    _callSub?.cancel();

    setState(() {
      _activeConsultationId = newId;
      _messages = [];
      _isLoadingMessages = true;
    });

    _setupRealtimeListeners();
    _loadMessagesFromFirebase();
    _loadMessagesFromBackend();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tersambung ke Konsultasi #$_activeConsultationId'),
        backgroundColor: _darkGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showChangeConsultationIdDialog() {
    final ctrl = TextEditingController(text: _activeConsultationId);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti ID Konsultasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan ID Konsultasi aktif untuk pengujian (misal ID dari Postman atau Server):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'ID Konsultasi (UUID)',
                hintText: 'Contoh: 2940f5ab-2a29-4860-983e-a0e7824c464e',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newId = ctrl.text.trim();
              Navigator.pop(ctx);
              _switchConsultationId(newId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _darkGreen),
            child: const Text('Terapkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _setupRealtimeListeners() {
    // 1. Mendengarkan pesan realtime dari Firebase (<100ms)
    _msgSub = _firebaseService.listenMessages(_activeConsultationId).listen((ChatMessage msg) {
      if (!mounted) return;
      final isMe = (msg.senderRole.toLowerCase() == 'pasien') ||
          (_currentUser != null && msg.idSender.isNotEmpty && msg.idSender == _currentUser!.id.toString());
      final senderKey = isMe ? 'patient' : 'doctor';

      final exists = _messages.any((m) =>
          (m['id'] != null && msg.id.isNotEmpty && m['id'].toString() == msg.id) ||
          (m['text'] == msg.pesan && m['sender'] == senderKey));

      if (!exists) {
        final timeStr = msg.createdAt.contains('T')
            ? msg.createdAt.split('T').last.substring(0, 5)
            : (msg.createdAt.contains(' ')
                ? msg.createdAt.split(' ').last.substring(0, 5).replaceAll(':', '.')
                : (msg.createdAt.isNotEmpty ? msg.createdAt : '12.00'));

        setState(() {
          _messages.add({
            'id': msg.id,
            'sender': senderKey,
            'text': msg.pesan,
            'time': timeStr,
          });
        });
        _scrollToBottom();
      }
    });

    // 2. Mendengarkan status dokter sedang mengetik
    _typingSub = _firebaseService.listenTyping(_activeConsultationId, 'dokter').listen((isTyping) {
      if (!mounted) return;
      setState(() {
        _isDoctorTyping = isTyping;
      });
    });

    // 3. Mendengarkan Call Signaling dari Firebase RTDB
    _callSub = _firebaseService.listenCallSignaling(_activeConsultationId).listen((signal) {
      if (!mounted || signal == null) return;

      final status = signal.status.toLowerCase();
      final callerRole = signal.callerRole.toLowerCase();

      if (status == 'ringing' && callerRole != 'pasien' && !_isIncomingCallModalShowing) {
        _showIncomingCallModal(signal);
      } else if (status == 'ended' || status == 'rejected') {
        _ringtonePlayer.stop();
        if (_isIncomingCallModalShowing && Navigator.canPop(context)) {
          _isIncomingCallModalShowing = false;
          Navigator.pop(context);
        }
      }
    });
  }

  Future<void> _loadMessagesFromFirebase() async {
    try {
      final fbMessages = await _firebaseService.fetchMessagesDirectly(_activeConsultationId);
      if (mounted && fbMessages.isNotEmpty) {
        final List<Map<String, dynamic>> loaded = [];
        for (var fbMsg in fbMessages) {
          final isMe = (fbMsg.senderRole.toLowerCase() == 'pasien') ||
              (_currentUser != null && fbMsg.idSender.isNotEmpty && fbMsg.idSender == _currentUser!.id.toString());
          final senderKey = isMe ? 'patient' : 'doctor';
          final timeStr = fbMsg.createdAt.contains('T')
              ? fbMsg.createdAt.split('T').last.substring(0, 5)
              : (fbMsg.createdAt.contains(' ')
                  ? fbMsg.createdAt.split(' ').last.substring(0, 5).replaceAll(':', '.')
                  : (fbMsg.createdAt.isNotEmpty ? fbMsg.createdAt : '12.00'));

          loaded.add({
            'id': fbMsg.id,
            'sender': senderKey,
            'text': fbMsg.pesan,
            'time': timeStr,
          });
        }
        setState(() {
          _messages = loaded;
          _isLoadingMessages = false;
        });
        _scrollToBottom();
      } else if (mounted) {
        setState(() {
          _isLoadingMessages = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error _loadMessagesFromFirebase: $e');
      if (mounted) setState(() => _isLoadingMessages = false);
    }
  }

  Future<void> _loadMessagesFromBackend() async {
    try {
      final res = await _apiService.getConsultationChatDetail(_activeConsultationId);
      if (res.success && res.data != null && mounted) {
        // 1. Sesuaikan info dokter jika tersedia di respon konsultasi
        final konsultasi = res.data!['konsultasi'];
        if (konsultasi is Map && konsultasi['dokter'] is Map) {
          final doc = konsultasi['dokter'] as Map;
          String docNama = (doc['nama'] ?? doc['name'] ?? '').toString();
          String docSpec = (doc['spesialisasi'] ?? doc['specialty'] ?? '').toString();
          String docAvatar = (doc['foto_profile'] ?? '').toString();

          if (docNama.toLowerCase().contains('realtime')) {
            docNama = 'dr. Budi Santoso, Sp.PD';
            docSpec = 'Dokter Spesialis Penyakit Dalam';
          }

          if (docNama.isNotEmpty || docSpec.isNotEmpty || docAvatar.isNotEmpty) {
            setState(() {
              if (docNama.isNotEmpty) _doctorName = docNama;
              if (docSpec.isNotEmpty) _specialty = docSpec;
              if (docAvatar.isNotEmpty) _avatarUrl = docAvatar;
            });
          }
        }

        // 2. Gabungkan pesan baru dari database jika belum ada di list
        final rawMsgs = res.data!['messages'];
        if (rawMsgs is List && rawMsgs.isNotEmpty) {
          bool hasNew = false;
          for (var item in rawMsgs) {
            if (item is Map) {
              final senderRole = (item['sender_role'] ?? item['role'] ?? '').toString().toLowerCase();
              final senderId = (item['id_sender'] ?? item['sender_id'] ?? '').toString();
              final myId = _currentUser?.id?.toString() ?? '';
              final isMe = (senderRole == 'pasien') ||
                  (myId.isNotEmpty && senderId.isNotEmpty && senderId == myId);
              final senderKey = isMe ? 'patient' : 'doctor';
              final text = (item['pesan'] ?? item['message'] ?? item['text'] ?? '').toString();
              final time = item['created_at'] != null
                  ? item['created_at'].toString().split('T').last.substring(0, 5)
                  : '12.00';
              final id = (item['id'] ?? item['id_pesan'] ?? '').toString();

              final exists = _messages.any((m) =>
                  (id.isNotEmpty && m['id'] == id) ||
                  (m['text'] == text && m['sender'] == senderKey));

              if (!exists) {
                _messages.add({
                  'id': id,
                  'sender': senderKey,
                  'text': text,
                  'time': time,
                });
                hasNew = true;
              }
            }
          }
          if (hasNew && mounted) {
            setState(() {
              _isLoadingMessages = false;
            });
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error _loadMessagesFromBackend: $e');
    }
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _typingSub?.cancel();
    _callSub?.cancel();
    _typingDebounce?.cancel();
    _ringtonePlayer.stop();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    _apiService.sendTypingStatus(_activeConsultationId, true);
    _firebaseService.updateTypingStatus(_activeConsultationId, 'pasien', true);

    if (_typingDebounce?.isActive ?? false) _typingDebounce!.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      _apiService.sendTypingStatus(_activeConsultationId, false);
      _firebaseService.updateTypingStatus(_activeConsultationId, 'pasien', false);
    });
  }

  void _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    _typingDebounce?.cancel();
    _apiService.sendTypingStatus(_activeConsultationId, false);
    _firebaseService.updateTypingStatus(_activeConsultationId, 'pasien', false);

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';
    final formattedCreatedAt = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final tempMsgId = 'msg_${DateTime.now().millisecondsSinceEpoch}';

    // Optimistic UI update
    setState(() {
      _messages.add({
        'id': tempMsgId,
        'sender': 'patient',
        'text': text,
        'time': timeStr,
      });
    });

    _scrollToBottom();

    final myId = _currentUser?.id?.toString() ?? '1';
    final myName = _currentUser?.nama.isNotEmpty == true ? _currentUser!.nama : 'Pasien';

    // 1. Kirim pesan ke Firebase RTDB (<100ms sync)
    final chatMsg = ChatMessage(
      id: tempMsgId,
      idSender: myId,
      senderName: myName,
      senderRole: 'pasien',
      pesan: text,
      tipe: 'text',
      createdAt: formattedCreatedAt,
    );
    await _firebaseService.pushMessage(_activeConsultationId, chatMsg);

    // 2. Kirim pesan ke API backend Laravel (audit log, validasi, dan persistensi DB relasional)
    try {
      final res = await _apiService.sendMessage(_activeConsultationId, pesan: text);
      if (res.success && res.data != null) {
        final serverId = res.data!['id'] ?? res.data!['id_pesan'];
        if (serverId != null && mounted) {
          final idx = _messages.indexWhere((m) => m['id'] == tempMsgId);
          if (idx != -1) {
            _messages[idx]['id'] = serverId.toString();
          }
        }
      } else if (!res.success) {
        debugPrint('⚠️ Respon API sendMessage: ${res.message}');
      }
    } catch (e) {
      debugPrint('⚠️ Gagal simpan pesan ke REST API: $e');
    }
  }

  Future<void> _startOutgoingCall() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menghubungkan panggilan video ke dokter...'),
        duration: Duration(seconds: 2),
      ),
    );

    String roomId = 'giat-consult-$_activeConsultationId';
    try {
      final res = await _apiService.startVideoCall(_activeConsultationId);
      if (res.data != null && res.data!['room_id'] != null) {
        roomId = res.data!['room_id'].toString();
      }
    } catch (_) {}

    await _firebaseService.updateCallSignal(
      _activeConsultationId,
      CallSignalModel(
        status: 'ringing',
        callerId: _currentUser?.id?.toString() ?? '1',
        callerName: _currentUser?.nama ?? 'Pasien GIAT',
        callerRole: 'pasien',
        roomId: roomId,
      ),
    );

    _callStartTime = DateTime.now();
    try {
      await _jitsiService.joinRoom(
        roomId: roomId,
        userName: _currentUser?.nama ?? 'Pasien GIAT',
        userEmail: _currentUser?.email ?? 'pasien@giat.id',
        onTerminated: _handleCallEnded,
      );
    } catch (e) {
      debugPrint('⚠️ Jitsi error, launching fallback video screen: $e');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => KonsultasiVideoCallScreen(
              doctorName: _doctorName,
              specialty: _specialty,
              avatarUrl: _avatarUrl,
              consultationId: _activeConsultationId,
            ),
          ),
        );
      }
    }
  }

  void _showIncomingCallModal(CallSignalModel signal) {
    _isIncomingCallModalShowing = true;
    _ringtonePlayer.playRingtone();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => IncomingCallDialog(
        callerName: signal.callerName.isNotEmpty ? signal.callerName : widget.doctorName,
        callerRole: widget.specialty,
        callerAvatar: widget.avatarUrl,
        onReject: () async {
          _ringtonePlayer.stop();
          _isIncomingCallModalShowing = false;
          Navigator.pop(ctx);
          await _apiService.respondCallSignal(_activeConsultationId, 'reject');
          await _firebaseService.updateCallSignal(
            _activeConsultationId,
            CallSignalModel(
              status: 'rejected',
              callerId: _currentUser?.id?.toString() ?? '',
              callerName: _currentUser?.nama ?? 'Pasien',
              callerRole: 'pasien',
              roomId: signal.roomId,
            ),
          );
        },
        onAccept: () async {
          _ringtonePlayer.stop();
          _isIncomingCallModalShowing = false;
          Navigator.pop(ctx);
          await _apiService.respondCallSignal(_activeConsultationId, 'accept');

          _callStartTime = DateTime.now();
          try {
            await _jitsiService.joinRoom(
              roomId: signal.roomId.isNotEmpty ? signal.roomId : 'giat-consult-$_activeConsultationId',
              userName: _currentUser?.nama ?? 'Pasien GIAT',
              userEmail: _currentUser?.email ?? 'pasien@giat.id',
              onTerminated: _handleCallEnded,
            );
          } catch (e) {
            debugPrint('⚠️ Fallback to local call screen: $e');
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => KonsultasiVideoCallScreen(
                    doctorName: _doctorName,
                    specialty: _specialty,
                    avatarUrl: _avatarUrl,
                    consultationId: _activeConsultationId,
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _handleCallEnded() {
    int durationMinutes = 1;
    if (_callStartTime != null) {
      durationMinutes = DateTime.now().difference(_callStartTime!).inMinutes;
      if (durationMinutes < 1) durationMinutes = 1;
    }
    _apiService.endVideoCall(_activeConsultationId, durasiMenit: durationMinutes);
    _firebaseService.clearCallSignal(_activeConsultationId);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      body: Stack(
        children: [
          // ── Background Topography ──
          Positioned.fill(
            child: CustomPaint(
              painter: _ChatTopographyPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Custom Header / App Bar ──
                _buildHeaderBar(),

                // ── Message List ──
                Expanded(
                  child: ListView(
                    controller: _scrollCtrl,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      // "Hari Ini" Date Badge
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF1E293B), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'Hari Ini',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),

                      if (_messages.isEmpty && _isLoadingMessages)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.2, color: _darkGreen),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Menghubungkan ke ruang chat realtime...',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (_messages.isEmpty && !_isLoadingMessages)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE8F5E9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.mark_chat_unread_outlined, color: _darkGreen, size: 28),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Sesi konsultasi aktif dengan $_doctorName',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Mulai percakapan dengan mengirimkan pesan atau keluhan Anda di bawah.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Messages
                      ..._messages.map((msg) {
                        final isDoctor = msg['sender'] == 'doctor';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: isDoctor
                              ? _buildDoctorMessageBubble(msg)
                              : _buildPatientMessageBubble(msg),
                        );
                      }),
                    ],
                  ),
                ),

                // Indikator Dokter Sedang Mengetik
                if (_isDoctorTyping)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TypingIndicatorWidget(partnerName: _doctorName),
                  ),

                // ── Bottom Chat Input Bar ──
                _buildInputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CUSTOM APP BAR / HEADER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button Pill
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _darkGreen, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_rounded, size: 16, color: _darkGreen),
                  const SizedBox(width: 4),
                  Text(
                    'Kembali',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _darkGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Doctor Avatar + Details
          Expanded(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _avatarUrl.isNotEmpty
                      ? Image.network(
                          _avatarUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 44,
                            height: 44,
                            color: const Color(0xFFDCFCE7),
                            child: const Icon(Icons.person_rounded, size: 24, color: _darkGreen),
                          ),
                        )
                      : Container(
                          width: 44,
                          height: 44,
                          color: const Color(0xFFDCFCE7),
                          child: const Icon(Icons.person_rounded, size: 24, color: _darkGreen),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _doctorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        _specialty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Online Sekarang',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: _showChangeConsultationIdDialog,
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '#$_activeConsultationId',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _darkGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.edit_rounded, size: 9, color: _darkGreen),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Video Call Action Button
          GestureDetector(
            onTap: _startOutgoingCall,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.videocam_outlined,
                  size: 24,
                  color: _darkGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DOCTOR MESSAGE BUBBLE (Left Aligned)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDoctorMessageBubble(Map<String, dynamic> msg) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mini Doctor Avatar
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            widget.avatarUrl,
            width: 34,
            height: 34,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 34,
              height: 34,
              color: const Color(0xFFDCFCE7),
              child: const Icon(Icons.person_rounded, size: 20, color: _darkGreen),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Bubble
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: const Color(0xFF86EFAC), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg['text'],
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0F172A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Spacer(),
                    Text(
                      msg['time'] ?? '12.00',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF0284C7)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PATIENT MESSAGE BUBBLE (Right Aligned)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildPatientMessageBubble(Map<String, dynamic> msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 290),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _patientBubbleGreen,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: _darkGreen.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg['text'],
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Spacer(),
                Text(
                  msg['time'] ?? '12.00',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF67E8F9)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BOTTOM INPUT BAR
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attachment "+" Button
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pilih lampiran dokumen/resep...')),
              );
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 24,
                color: Color(0xFF475569),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Message Input Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      onChanged: _onTextChanged,
                      onSubmitted: (_) => _sendMessage(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),

                  // Emoji Icon
                  IconButton(
                    icon: const Icon(Icons.sentiment_satisfied_alt_rounded, size: 22, color: Color(0xFF64748B)),
                    onPressed: () {},
                  ),

                  // Mic Icon
                  IconButton(
                    icon: const Icon(Icons.mic_none_rounded, size: 22, color: Color(0xFF64748B)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Perekaman suara dimulai...')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Send Button
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _darkGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _darkGreen.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT TOPOGRAPHY BACKGROUND PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _ChatTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    GiatBackgroundPainter.paintBackground(
      canvas,
      size,
      showGradient: false,
      showLines: true,
    );
    }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
