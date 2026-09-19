import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PRAGI AI ASSISTANT CHAT SCREEN (Prajurit Ginjal)
// ─────────────────────────────────────────────────────────────────────────────

class PragiChatScreen extends StatefulWidget {
  const PragiChatScreen({super.key});

  @override
  State<PragiChatScreen> createState() => _PragiChatScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final String time;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class _PragiChatScreenState extends State<PragiChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isTyping = false;

  static const _darkGreen = Color(0xFF065A37);
  static const _bubbleGreen = Color(0xFF22C55E);
  static const _userBubbleGreen = Color(0xFF044E2F);

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: 'Halo! Saya PRAGI (Prajurit Ginjal) 🐾\nAsisten AI pintar pendamping kesehatan ginjal Anda. Ada yang ingin Anda tanyakan seputar ginjal, pola makan, atau obat hari ini?',
      isUser: false,
      time: '12:00',
    ),
  ];

  final List<String> _quickSuggestions = [
    '💧 Berapa asupan air yang aman?',
    '🥗 Makanan pantangan ginjal stadium 3',
    '💊 Jadwal obat saya hari ini',
    '🧪 Arti kadar kreatinin 1.8',
    '🏃 Olahraga yang aman untuk ginjal',
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userText = text.trim();
    _msgCtrl.clear();

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add(_ChatMessage(
        text: userText,
        isUser: true,
        time: timeStr,
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    // AI Response Simulation
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;

      String aiReply = _generatePragiResponse(userText);
      final respNow = DateTime.now();
      final respTimeStr = '${respNow.hour.toString().padLeft(2, '0')}:${respNow.minute.toString().padLeft(2, '0')}';

      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: aiReply,
          isUser: false,
          time: respTimeStr,
        ));
      });

      _scrollToBottom();
    });
  }

  String _generatePragiResponse(String query) {
    final q = query.toLowerCase();
    if (q.contains('air') || q.contains('minum') || q.contains('asupan')) {
      return '💧 Untuk pasien ginjal, asupan cairan umumnya disesuaikan dengan anjuran dokter (biasanya 1000-1500 ml/hari tergantung stadium dan ada tidaknya pembengkakan). Pastikan tidak minum berlebihan secara tiba-tiba ya!';
    } else if (q.contains('makanan') || q.contains('pantangan') || q.contains('diet') || q.contains('makan')) {
      return '🥗 Pada kesehatan ginjal, batasi makanan tinggi natrium/garam, hindari makanan olahan/kaleng, dan batasi asupan kalium/fosfor tinggi (seperti pisang berlebih atau jeroan). Utamakan makanan segar yang dimasak sendiri!';
    } else if (q.contains('obat') || q.contains('jadwal')) {
      return '💊 Anda memiliki pengingat obat hari ini pada pukul 08:00 WIB dan 20:00 WIB. Jangan lupa minum obat teratur dan catat di menu Obat ya!';
    } else if (q.contains('kreatinin') || q.contains('egfr') || q.contains('lab')) {
      return '🧪 Kadar kreatinin 1.8 menunjukkan adanya penurunan fungsi filtrasi ginjal. Segera konsultasikan hasil lab terbaru Anda dengan Dokter Spesialis Ginjal melalui menu Konsultasi.';
    } else {
      return '🐾 Pertanyaan yang bagus! Menjaga ginjal tetap sehat membutuhkan kontrol tensi teratur, pola makan rendah garam, dan minum air sesuai anjuran. Ada hal lain yang ingin PRAGI bantu?';
    }
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
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _darkGreen, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/pragi.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFDCFCE7),
                    child: const Icon(Icons.smart_toy_rounded, color: _darkGreen),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRAGI AI',
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
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
                      'Prajurit Ginjal • Aktif',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            tooltip: 'Bersihkan Sesi',
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(_ChatMessage(
                  text: 'Halo! Sesi obrolan baru telah dimulai. Ada yang ingin Anda tanyakan seputar ginjal?',
                  isUser: false,
                  time: '12:00',
                ));
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Message Stream
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, idx) {
                  final msg = _messages[idx];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            // Typing indicator
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _bubbleGreen),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PRAGI sedang mengetik...',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Quick Suggestions Carousel
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickSuggestions.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final chip = _quickSuggestions[i];
                  return ActionChip(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    label: Text(
                      chip,
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155), fontWeight: FontWeight.w500),
                    ),
                    onPressed: () => _sendMessage(chip.substring(2).trim()),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Bottom Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _sendMessage,
                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                        decoration: InputDecoration(
                          hintText: 'Tanyakan sesuatu pada PRAGI...',
                          hintStyle: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(_msgCtrl.text),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: _userBubbleGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: Image.asset('assets/images/pragi.png', fit: BoxFit.cover),
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 290),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isUser ? _userBubbleGreen : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
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
                      height: 1.4,
                      color: isUser ? Colors.white : const Color(0xFF1E293B),
                      fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      msg.time,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: isUser ? Colors.white70 : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
