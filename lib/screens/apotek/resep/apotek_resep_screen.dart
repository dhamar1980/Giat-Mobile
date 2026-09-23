import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/apotek_models.dart';
import '../notifikasi/apotek_notifikasi_screen.dart';
import 'apotek_detail_resep_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DAFTAR RESEP MASUK APOTEK (Revisi Sesuai Screenshot Desain GIAT)
// ─────────────────────────────────────────────────────────────────────────────

class ApotekResepScreen extends StatefulWidget {
  final int initialTabIndex;
  final Function(int targetTab)? onNavigateToOrderTab;
  final VoidCallback? onOpenProfile;
  final bool? isTopBarVisible;

  const ApotekResepScreen({
    super.key,
    this.initialTabIndex = 0,
    this.onNavigateToOrderTab,
    this.onOpenProfile,
    this.isTopBarVisible,
  });

  @override
  State<ApotekResepScreen> createState() => _ApotekResepScreenState();
}

class _ApotekResepScreenState extends State<ApotekResepScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _cardBorder = Color(0xFFE2E8F0);
  static const _innerBorder = Color(0xFFCBD5E1);

  bool _showAllHistory = false;
  bool _internalIsTopBarVisible = true;

  bool get _effectiveTopBarVisible => widget.isTopBarVisible ?? _internalIsTopBarVisible;

  List<ApotekRecipe> _getIncomingRecipes() {
    final all = ApotekMockData.recipes;
    if (_showAllHistory) return all;
    // Tampilkan resep masuk yang belum diverifikasi / belum diterima
    return all.where((r) => r.status == ApotekRecipeStatus.belumDiverifikasi).toList();
  }

  void _openDetail(ApotekRecipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApotekDetailResepScreen(
          recipe: recipe,
          onStatusChanged: () => setState(() {}),
          onNavigateToOrderTab: widget.onNavigateToOrderTab,
          onOpenProfile: widget.onOpenProfile,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _handleAcceptRecipe(ApotekRecipe recipe) {
    final newOrder = ApotekMockData.acceptRecipeAndCreateOrder(recipe);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Resep ${recipe.id} berhasil diterima! Masuk ke Pesanan Menunggu (${newOrder.id}).',
        ),
        backgroundColor: _darkGreen,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Buka Pesanan',
          textColor: const Color(0xFF86EFAC),
          onPressed: () {
            widget.onNavigateToOrderTab?.call(0);
          },
        ),
      ),
    );

    // Otomatis alihkan ke Pesanan Menunggu setelah klik Terima Resep
    widget.onNavigateToOrderTab?.call(0);
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final incomingList = _getIncomingRecipes();

    return Scaffold(
      backgroundColor: _bgColor,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            final pixels = notification.metrics.pixels;
            if (pixels > 20) {
              if (_internalIsTopBarVisible) setState(() => _internalIsTopBarVisible = false);
            } else if (pixels <= 5) {
              if (!_internalIsTopBarVisible) setState(() => _internalIsTopBarVisible = true);
            }
          }
          return false;
        },
        child: Stack(
          children: [
            // Background Topography Curves
            Positioned.fill(
              child: CustomPaint(
                painter: _ResepTopographyPainter(),
              ),
            ),

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Top Curved Green Header with Chat Bubbles (Screenshot 1) ──
                  _buildHeaderSection(topPadding),

                  const SizedBox(height: 18),

                  // ── 2. Content Section ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Title: "Daftar Resep Masuk" (Screenshot 1)
                        Text(
                          'Daftar Resep Masuk',
                          style: GoogleFonts.inter(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Recipe List
                        if (incomingList.isEmpty)
                          _buildEmptyState()
                        else
                          ...incomingList.map((recipe) => Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: _buildRecipeCard(recipe),
                              )),

                        const SizedBox(height: 36),
                      ],
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

  // ───────────────────────────────────────────────────────────────────────────
  // HEADER SECTION (Mockup Screenshot 1: Green Gradient + 2 Chat Bubbles + Pill)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderSection(double topPadding) {
    final unreadNotifs = ApotekMockData.notifications.where((n) => !n.isRead).length;

    return ClipPath(
      clipper: _ResepHeaderClipper(),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF22C55E),
              Color(0xFF16A34A),
              Color(0xFF065A37),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ResepHeaderCurvePainter(),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, topPadding + 60, 20, 42),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chat Bubble 1 (Left Aligned - White Bubble)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildChatBubble(
                      isLeft: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat datang kembali! Yuk, cek dan proses resep masuk kamu sekarang di menu Resep.',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF065A37),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Spacer(),
                              Icon(Icons.done_all_rounded, size: 16, color: Color(0xFF38BDF8)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Chat Bubble 2 (Right Aligned - White Bubble)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildChatBubble(
                      isLeft: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kelola dan proses resep yang masuk ✨✨',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF065A37),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Spacer(),
                              Icon(Icons.done_all_rounded, size: 16, color: Color(0xFF38BDF8)),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildChatBubble({
    required bool isLeft,
    required Widget child,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: isLeft ? 330 : 280,
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 14, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isLeft ? const Radius.circular(4) : const Radius.circular(16),
              bottomRight: isLeft ? const Radius.circular(16) : const Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
        // WhatsApp style speech bubble tail
        Positioned(
          bottom: 0,
          left: isLeft ? -7 : null,
          right: isLeft ? null : -7,
          child: CustomPaint(
            size: const Size(8, 12),
            painter: _ChatTailPainter(isLeft: isLeft),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // RECIPE CARD (Mockup Screenshot 1)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRecipeCard(ApotekRecipe r) {
    final isPending = r.status == ApotekRecipeStatus.belumDiverifikasi;

    return GestureDetector(
      onTap: () => _openDetail(r),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Clipboard Icon + ID & Patient/Doctor + Meta
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Soft mint container with clipboard prescription icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6EFF6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: _ClipboardPrescriptionIcon(
                      color: _darkGreen,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // ID, Patient • Doctor, 2 item obat • 10 menit lalu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.id,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${r.patientName} • ${r.doctorName}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${r.items.length} item obat • ${r.timeText}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Inner Bordered Box for Items & Total
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _innerBorder),
              ),
              child: Column(
                children: [
                  ...r.items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.medicineName,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.formAndPack,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Green Pill Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _darkGreen,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.qtyText,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (idx < r.items.length - 1)
                          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                      ],
                    );
                  }),

                  const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                  // Total Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        Text(
                          '${r.items.length} item obat',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Action Button: "Terima Resep"
            if (isPending)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonDarkGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _handleAcceptRecipe(r),
                  child: Text(
                    'Terima Resep',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _darkGreen,
                    side: const BorderSide(color: _darkGreen, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _openDetail(r),
                  child: Text(
                    'Lihat Detail Resep (Sudah Diterima)',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_outlined, size: 36, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),
          Text(
            'Tidak ada resep masuk baru',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Semua resep dokter telah diterima dan dipindahkan ke menu Pesanan Menunggu.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _buttonDarkGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              widget.onNavigateToOrderTab?.call(0);
            },
            child: Text(
              'Buka Menu Pesanan',
              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLIPPER & PAINTERS FOR RESEP SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _ClipboardPrescriptionIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _ClipboardPrescriptionIcon({
    this.size = 28,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Icon(
              Icons.assignment_outlined,
              size: size * 0.92,
              color: color,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Transform.rotate(
              angle: -0.785, // -45 deg
              child: Icon(
                Icons.medication_rounded,
                size: size * 0.48,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResepHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 35);
    path.cubicTo(
      size.width * 0.25,
      size.height + 18,
      size.width * 0.65,
      size.height - 45,
      size.width,
      size.height - 25,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ResepHeaderCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int i = 0; i < 4; i++) {
      final path = Path();
      final yOffset = size.height * (0.35 + (i * 0.18));
      path.moveTo(-20, yOffset);
      path.cubicTo(
        size.width * 0.3,
        yOffset - 30,
        size.width * 0.7,
        yOffset + 25,
        size.width + 20,
        yOffset - 20,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChatTailPainter extends CustomPainter {
  final bool isLeft;
  const _ChatTailPainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
    } else {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ResepTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 10; i++) {
      final path = Path();
      final yOffset = 40.0 + (i * 90);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.35,
        yOffset - 30,
        size.width * 0.65,
        yOffset + 40,
        size.width,
        yOffset - 10,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
