import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dokter_models.dart';
import '../resep/dokter_review_resep_sheet.dart';
import 'dokter_video_call_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RUANG CHAT DOKTER-PASIEN (Figma Node: 1008-17368)
// ─────────────────────────────────────────────────────────────────────────────

class _ChatMessage {
  final String sender; // 'doctor' | 'patient' | 'prescription'
  final String text;
  final String time;
  final List<DokterPrescriptionItem>? prescriptionItems;

  const _ChatMessage({
    required this.sender,
    required this.text,
    required this.time,
    this.prescriptionItems,
  });
}

class DokterRoomChatScreen extends StatefulWidget {
  final DokterPatient patient;

  const DokterRoomChatScreen({
    super.key,
    required this.patient,
  });

  @override
  State<DokterRoomChatScreen> createState() => _DokterRoomChatScreenState();
}

class _DokterRoomChatScreenState extends State<DokterRoomChatScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _border = Color(0xFFE2E8F0);

  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  late List<_ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = [
      const _ChatMessage(
        sender: 'doctor',
        text: 'Halo, ada yang bisa saya bantu hari ini? 👋🏻',
        time: '12.00',
      ),
      _ChatMessage(
        sender: 'patient',
        text: 'Halo Dok, saya ingin berkonsultasi mengenai hasil pemeriksaan ginjal saya.',
        time: '12.00',
      ),
    ];
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(
        sender: 'doctor',
        text: text,
        time: '${TimeOfDay.now().hour.toString().padLeft(2, '0')}.${TimeOfDay.now().minute.toString().padLeft(2, '0')}',
      ));
      _textCtrl.clear();
    });
    _scrollToBottom();
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
      setState(() {
        _messages.add(_ChatMessage(
          sender: 'prescription',
          text: 'Resep Obat Elektronik Diterbitkan',
          time: '${TimeOfDay.now().hour.toString().padLeft(2, '0')}.${TimeOfDay.now().minute.toString().padLeft(2, '0')}',
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
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  p.initials,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _darkGreen, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Online Sekarang',
                          style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF10B981), fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: _darkGreen, size: 24),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DokterVideoCallScreen(
                    patientName: p.name,
                    specialty: 'Spesialis Ginjal & Hipertensi',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.call_rounded, color: _darkGreen, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Memulai panggilan audio dengan ${p.name}...')),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick topic chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickChip('Konsultasi Hasil Lab'),
                    const SizedBox(width: 8),
                    _buildQuickChip('Keluhan Gejala Baru'),
                  ],
                ),
              ),
            ),

            // Date separator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Hari Ini',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                  ),
                ),
              ),
            ),

            // Chat Message List
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  if (msg.sender == 'prescription') {
                    return _buildPrescriptionMessageCard(msg);
                  }
                  final isDoctor = msg.sender == 'doctor';
                  return _buildChatMessageItem(msg, isDoctor, p.initials);
                },
              ),
            ),

            // Bottom Input Bar with (+) Prescription Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  // Prescription / Plus button (Figma requirement)
                  GestureDetector(
                    onTap: _openPrescriptionModal,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: _darkGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.add_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Text input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _textCtrl,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Ketik pesan...',
                          hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send Button
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: _darkGreen, size: 22),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF475569)),
      ),
    );
  }

  Widget _buildChatMessageItem(_ChatMessage msg, bool isDoctor, String patientInitials) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isDoctor ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isDoctor) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  patientInitials,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDoctor ? _buttonDarkGreen : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isDoctor ? 16 : 4),
                  bottomRight: Radius.circular(isDoctor ? 4 : 16),
                ),
                border: isDoctor ? null : Border.all(color: _border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: isDoctor ? Colors.white : const Color(0xFF1E293B),
                      height: 1.35,
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
                          color: isDoctor ? Colors.white70 : const Color(0xFF94A3B8),
                        ),
                      ),
                      if (isDoctor) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF67E8F9)),
                      ],
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

  Widget _buildPrescriptionMessageCard(_ChatMessage msg) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF10B981), width: 1.5),
          boxShadow: [
            BoxShadow(color: const Color(0xFF10B981).withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: _darkGreen, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resep Digital Diterbitkan',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                      ),
                      Text(
                        'Diberikan oleh Dr. Andi Pratama',
                        style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
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
                            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
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
                  'Terkirim ke Rekam Medis & Pasien',
                  style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: _darkGreen),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
