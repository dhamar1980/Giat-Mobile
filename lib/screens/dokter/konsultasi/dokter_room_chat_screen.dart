import 'dart:async';
import 'package:giat/widgets/giat_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dokter_models.dart';
import '../resep/dokter_review_resep_sheet.dart';
import 'dokter_video_call_screen.dart';
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
// RUANG CHAT DOKTER-PASIEN (Realtime Chat & Video Call GIAT Telemedicine)
// ─────────────────────────────────────────────────────────────────────────────

class _ChatMessage {
  final String? id;
  final String sender; // 'doctor' | 'patient' | 'prescription'
  final String text;
  final String time;
  final List<DokterPrescriptionItem>? prescriptionItems;

  const _ChatMessage({
    this.id,
    required this.sender,
    required this.text,
    required this.time,
    this.prescriptionItems,
  });
}

class DokterRoomChatScreen extends StatefulWidget {
  final DokterPatient patient;
  final String? consultationId;

  const DokterRoomChatScreen({
    super.key,
    required this.patient,
    this.consultationId,
  });

  @override
  State<DokterRoomChatScreen> createState() => _DokterRoomChatScreenState();
}

class _DokterRoomChatScreenState extends State<DokterRoomChatScreen> {
  static const _darkGreen = Color(0xFF065A37);

  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final KonsultasiApiService _apiService = KonsultasiApiService();
  final FirebaseRealtimeService _firebaseService = FirebaseRealtimeService();
  final JitsiVideoService _jitsiService = JitsiVideoService();
  final RingtonePlayer _ringtonePlayer = RingtonePlayer();

  UserModel? _currentUser;
  StreamSubscription? _msgSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _callSub;
  Timer? _typingDebounce;

  bool _isPatientTyping = false;
  bool _isIncomingCallModalShowing = false;
  DateTime? _callStartTime;

  late String _activeConsultationId;
  String get _consultationId => _activeConsultationId;

  late List<_ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _activeConsultationId = widget.consultationId ?? widget.patient.id;
    _messages = [
      const _ChatMessage(
        sender: 'doctor',
        text: 'Halo, ada yang bisa saya bantu hari ini? 👋🏻',
        time: '12.00',
      ),
      const _ChatMessage(
        sender: 'patient',
        text: 'Halo Dok, saya ingin berkonsultasi mengenai hasil pemeriksaan ginjal saya.',
        time: '12.00',
      ),
    ];

    _initSessionAndListeners();
  }

  Future<void> _initSessionAndListeners() async {
    _currentUser = await StorageService().getUser();
    _setupRealtimeListeners();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final List<_ChatMessage> loaded = [];
      final Set<String> loadedIds = {};

      final res = await _apiService.getMessages(_consultationId);
      if (res.success && res.data != null && res.data!.isNotEmpty) {
        for (var item in res.data!) {
          if (item is Map) {
            final senderRole = (item['sender_role'] ?? item['role'] ?? '').toString().toLowerCase();
            final senderId = (item['id_sender'] ?? item['sender_id'] ?? '').toString();
            final myId = _currentUser?.id?.toString() ?? '';
            final id = (item['id'] ?? item['id_pesan'] ?? '').toString();

            final bool isDoctor = (senderRole == 'dokter') ||
                (myId.isNotEmpty && senderId.isNotEmpty && senderId == myId);
            final text = item['pesan'] ?? item['message'] ?? item['text'] ?? '';
            final time = item['created_at'] != null
                ? item['created_at'].toString().split('T').last.substring(0, 5)
                : '12.00';

            if (id.isNotEmpty) loadedIds.add(id);
            loaded.add(_ChatMessage(
              id: id,
              sender: isDoctor ? 'doctor' : 'patient',
              text: text.toString(),
              time: time,
            ));
          }
        }
      }

      final fbMessages = await _firebaseService.fetchMessagesDirectly(_consultationId);
      for (var fbMsg in fbMessages) {
        final isDoctor = (fbMsg.senderRole.toLowerCase() == 'dokter') ||
            (_currentUser != null && fbMsg.idSender.isNotEmpty && fbMsg.idSender == _currentUser!.id.toString());
        final senderKey = isDoctor ? 'doctor' : 'patient';

        final bool alreadyExists = (fbMsg.id.isNotEmpty && loadedIds.contains(fbMsg.id)) ||
            loaded.any((m) => m.text == fbMsg.pesan && m.sender == senderKey);

        if (!alreadyExists) {
          if (fbMsg.id.isNotEmpty) loadedIds.add(fbMsg.id);
          final timeStr = fbMsg.createdAt.contains('T')
              ? fbMsg.createdAt.split('T').last.substring(0, 5)
              : (fbMsg.createdAt.contains(' ')
                  ? fbMsg.createdAt.split(' ').last.substring(0, 5).replaceAll(':', '.')
                  : (fbMsg.createdAt.isNotEmpty ? fbMsg.createdAt : '12.00'));

          loaded.add(_ChatMessage(
            id: fbMsg.id,
            sender: senderKey,
            text: fbMsg.pesan,
            time: timeStr,
          ));
        }
      }

      if (mounted && loaded.isNotEmpty) {
        setState(() {
          _messages = loaded;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('⚠️ Error _loadMessages (Doctor): $e');
    }
  }

  void _setupRealtimeListeners() {
    // 1. Mendengarkan pesan realtime dari Firebase (<100ms)
    _msgSub = _firebaseService.listenMessages(_consultationId).listen((ChatMessage msg) {
      if (!mounted) return;
      final isDoctor = (msg.senderRole.toLowerCase() == 'dokter') ||
          (_currentUser != null && msg.idSender.isNotEmpty && msg.idSender == _currentUser!.id.toString());
      final senderKey = isDoctor ? 'doctor' : 'patient';

      final exists = _messages.any((m) =>
          (m.id != null && msg.id.isNotEmpty && m.id == msg.id) ||
          (m.text == msg.pesan && m.sender == senderKey));

      if (!exists) {
        final timeStr = msg.createdAt.contains('T')
            ? msg.createdAt.split('T').last.substring(0, 5)
            : (msg.createdAt.contains(' ')
                ? msg.createdAt.split(' ').last.substring(0, 5).replaceAll(':', '.')
                : (msg.createdAt.isNotEmpty ? msg.createdAt : '12.00'));

        setState(() {
          _messages.add(_ChatMessage(
            id: msg.id,
            sender: senderKey,
            text: msg.pesan,
            time: timeStr,
          ));
        });
        _scrollToBottom();
      }
    });

    // 2. Mendengarkan status pasien sedang mengetik
    _typingSub = _firebaseService.listenTyping(_consultationId, 'pasien').listen((isTyping) {
      if (!mounted) return;
      setState(() {
        _isPatientTyping = isTyping;
      });
    });

    // 3. Mendengarkan Call Signaling dari Firebase RTDB
    _callSub = _firebaseService.listenCallSignaling(_consultationId).listen((signal) {
      if (!mounted || signal == null) return;

      final status = signal.status.toLowerCase();
      final callerRole = signal.callerRole.toLowerCase();

      if (status == 'ringing' && callerRole != 'dokter' && !_isIncomingCallModalShowing) {
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

  @override
  void dispose() {
    _msgSub?.cancel();
    _typingSub?.cancel();
    _callSub?.cancel();
    _typingDebounce?.cancel();
    _ringtonePlayer.stop();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    _apiService.sendTypingStatus(_consultationId, true);
    _firebaseService.updateTypingStatus(_consultationId, 'dokter', true);

    if (_typingDebounce?.isActive ?? false) _typingDebounce!.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      _apiService.sendTypingStatus(_consultationId, false);
      _firebaseService.updateTypingStatus(_consultationId, 'dokter', false);
    });
  }

  void _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();

    _typingDebounce?.cancel();
    _apiService.sendTypingStatus(_consultationId, false);
    _firebaseService.updateTypingStatus(_consultationId, 'dokter', false);

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';
    final formattedCreatedAt = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final tempMsgId = 'msg_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _messages.add(_ChatMessage(
        id: tempMsgId,
        sender: 'doctor',
        text: text,
        time: timeStr,
      ));
    });
    _scrollToBottom();

    final myId = _currentUser?.id?.toString() ?? '1';
    final myName = _currentUser?.nama.isNotEmpty == true ? _currentUser!.nama : 'Dokter GIAT';

    // 1. Langsung push ke Firebase RTDB (<100ms sync)
    final chatMsg = ChatMessage(
      id: tempMsgId,
      idSender: myId,
      senderName: myName,
      senderRole: 'dokter',
      pesan: text,
      tipe: 'text',
      createdAt: formattedCreatedAt,
    );
    await _firebaseService.pushMessage(_consultationId, chatMsg);

    // 2. Kirim pesan ke API backend Laravel (audit log, validasi & persistensi DB relasional)
    try {
      final res = await _apiService.sendMessage(_consultationId, pesan: text);
      if (res.success && res.data != null) {
        final serverId = res.data!['id'] ?? res.data!['id_pesan'];
        if (serverId != null && mounted) {
          final idx = _messages.indexWhere((m) => m.id == tempMsgId);
          if (idx != -1) {
            _messages[idx] = _ChatMessage(
              id: serverId.toString(),
              sender: 'doctor',
              text: text,
              time: timeStr,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Gagal simpan pesan ke REST API: $e');
    }
  }

  Future<void> _startOutgoingCall() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menghubungi ${widget.patient.name} untuk video call...'),
        duration: const Duration(seconds: 2),
      ),
    );

    String roomId = 'giat-consult-$_consultationId';
    try {
      final res = await _apiService.startVideoCall(_consultationId);
      if (res.data != null && res.data!['room_id'] != null) {
        roomId = res.data!['room_id'].toString();
      }
    } catch (_) {}

    await _firebaseService.updateCallSignal(
      _consultationId,
      CallSignalModel(
        status: 'ringing',
        callerId: _currentUser?.id?.toString() ?? '1',
        callerName: _currentUser?.nama ?? 'Dokter GIAT',
        callerRole: 'dokter',
        roomId: roomId,
      ),
    );

    _callStartTime = DateTime.now();
    try {
      await _jitsiService.joinRoom(
        roomId: roomId,
        userName: _currentUser?.nama ?? 'Dokter GIAT',
        userEmail: _currentUser?.email ?? 'dokter@giat.id',
        onTerminated: _handleCallEnded,
      );
    } catch (e) {
      debugPrint('⚠️ Jitsi error, launching fallback video screen: $e');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DokterVideoCallScreen(
              patientName: widget.patient.name,
              specialty: 'Spesialis Ginjal & Hipertensi',
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
        callerName: signal.callerName.isNotEmpty ? signal.callerName : widget.patient.name,
        callerRole: 'Pasien GIAT',
        onReject: () async {
          _ringtonePlayer.stop();
          _isIncomingCallModalShowing = false;
          Navigator.pop(ctx);
          await _apiService.respondCallSignal(_consultationId, 'reject');
          await _firebaseService.updateCallSignal(
            _consultationId,
            CallSignalModel(
              status: 'rejected',
              callerId: _currentUser?.id?.toString() ?? '',
              callerName: _currentUser?.nama ?? 'Dokter',
              callerRole: 'dokter',
              roomId: signal.roomId,
            ),
          );
        },
        onAccept: () async {
          _ringtonePlayer.stop();
          _isIncomingCallModalShowing = false;
          Navigator.pop(ctx);
          await _apiService.respondCallSignal(_consultationId, 'accept');

          _callStartTime = DateTime.now();
          try {
            await _jitsiService.joinRoom(
              roomId: signal.roomId.isNotEmpty ? signal.roomId : 'giat-consult-$_consultationId',
              userName: _currentUser?.nama ?? 'Dokter GIAT',
              userEmail: _currentUser?.email ?? 'dokter@giat.id',
              onTerminated: _handleCallEnded,
            );
          } catch (e) {
            debugPrint('⚠️ Fallback to doctor call screen: $e');
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DokterVideoCallScreen(
                    patientName: widget.patient.name,
                    specialty: 'Spesialis Ginjal & Hipertensi',
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
    _apiService.endVideoCall(_consultationId, durasiMenit: durationMinutes);
    _firebaseService.clearCallSignal(_consultationId);
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

  void _openPrescriptionModal() async {
    final publishedItems = await Navigator.of(context).push<List<DokterPrescriptionItem>>(
      MaterialPageRoute(
        builder: (_) => DokterReviewResepScreen(
          patient: widget.patient,
        ),
      ),
    );

    if (publishedItems != null && publishedItems.isNotEmpty && mounted) {
      final now = TimeOfDay.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';

      setState(() {
        _messages.add(_ChatMessage(
          sender: 'prescription',
          text: 'Resep Obat Elektronik Diterbitkan',
          time: timeStr,
          prescriptionItems: publishedItems,
        ));
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      body: Stack(
        children: [
          // ── Background Topography (Identik dengan Room Chat Pasien) ──
          Positioned.fill(
            child: CustomPaint(
              painter: _ChatTopographyPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Custom Header / App Bar ──
                _buildHeaderBar(p),


                // ── Message List ──
                Expanded(
                  child: ListView(
                    controller: _scrollCtrl,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      // "Hari Ini" Date Badge (Sesuai Desain Room Chat Pasien)
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

                      // Messages
                      ..._messages.map((msg) {
                        if (msg.sender == 'prescription') {
                          return _buildPrescriptionMessageCard(msg);
                        }
                        final isDoctor = msg.sender == 'doctor';
                        return isDoctor
                            ? _buildDoctorMessageBubble(msg)
                            : _buildPatientMessageBubble(msg, p.initials);
                      }),
                    ],
                  ),
                ),

                // Indikator Pasien Sedang Mengetik
                if (_isPatientTyping)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TypingIndicatorWidget(partnerName: p.name),
                  ),

                // ── Bottom Chat Input Bar (Identik dengan Room Chat Pasien) ──
                _buildInputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CUSTOM APP BAR / HEADER (Identik dengan Desain Pasien, Hanya Video Call)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderBar(DokterPatient p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
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
          // Tombol Kembali Berbentuk Pill Hijau
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

          // Avatar Pasien & Detail
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      p.initials,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        color: _darkGreen,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${p.gender}, ${p.age} thn • Pasien',
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
                          Expanded(
                            child: Text(
                              'Online Sekarang',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: _showEditConsultationIdDialog,
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
                                    '#${_activeConsultationId.length > 8 ? '${_activeConsultationId.substring(0, 8)}...' : _activeConsultationId}',
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

          // Tombol Video Call (Hanya Video Call, Tanpa Telepon Suara)
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

  void _showEditConsultationIdDialog() {
    final ctrl = TextEditingController(text: _activeConsultationId);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.tune_rounded, color: _darkGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              'Ganti Consultation ID',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID sesi konsultasi saat ini:',
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              style: GoogleFonts.jetBrainsMono(fontSize: 12),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                hintText: 'Contoh UUID: 2940f5ab-...',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: _darkGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final newId = ctrl.text.trim();
              if (newId.isNotEmpty && newId != _activeConsultationId) {
                Navigator.pop(ctx);
                setState(() {
                  _activeConsultationId = newId;
                });
                _msgSub?.cancel();
                _typingSub?.cancel();
                _callSub?.cancel();
                _setupRealtimeListeners();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ID Konsultasi diganti ke: $_activeConsultationId'),
                    backgroundColor: _darkGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                Navigator.pop(ctx);
              }
            },
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
  }


  // ───────────────────────────────────────────────────────────────────────────
  // DOCTOR MESSAGE BUBBLE (Right Aligned - Hijau Tua Sesuai Pasien Chat Sisi Kanan)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDoctorMessageBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 290),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _darkGreen,
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
                msg.text,
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
                    msg.time,
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
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PATIENT MESSAGE BUBBLE (Left Aligned - Mint Lembut Sesuai Pasien Chat Sisi Kiri)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildPatientMessageBubble(_ChatMessage msg, String patientInitials) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Mini Patient Avatar Inisial
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF86EFAC), width: 1),
            ),
            child: Center(
              child: Text(
                patientInitials,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _darkGreen,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Bubble Mint
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
                    msg.text,
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
                        msg.time,
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
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // RESEP DIGITAL MESSAGE CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildPrescriptionMessageCard(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF10B981), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: _darkGreen, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resep Digital Diterbitkan',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Diberikan oleh Dr. Andi Pratama',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, color: Color(0xFFE2E8F0)),
              if (msg.prescriptionItems != null)
                ...msg.prescriptionItems!.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 16, color: _darkGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${item.medicineName} (${item.quantity}) - ${item.frequency}',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Terkirim ke Pasien di Menu Resep Dokter',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _darkGreen,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BOTTOM INPUT BAR (Identik dengan Room Chat Pasien)
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
          // Tombol Lampiran (+) untuk Resep Digital Dokter
          GestureDetector(
            onTap: _openPrescriptionModal,
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

          // Message Input Field Capsule
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
                      controller: _textCtrl,
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
