import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/app_brand_title.dart';
import '../../../widgets/giat_background.dart';
import '../../../widgets/giat_header_style.dart';

/// Painter latar belakang topografi khas GIAT untuk seluruh halaman Admin.
class AdminTopographyPainter extends CustomPainter {
  const AdminTopographyPainter();

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

/// Painter gelembung dekoratif halus di sisi kiri kartu (seperti pada kartu Reminder Pasien).
class AdminCardBubblePainter extends CustomPainter {
  const AdminCardBubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2ECC71).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 36, paint);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.7), 28, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Header halaman turunan Admin bergaya halaman Reminder Pasien:
/// Tidak menggunakan background hijau melengkung maupun bubble chat,
/// melainkan tombol pill "Kembali" di kiri atas dan badge pill hijau judul halaman di tengah.
class AdminSubpageHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  static const _primaryGreen = Color(0xFF006D37);
  static const _textColor = Color(0xFF091D2E);

  const AdminSubpageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Baris Atas: Tombol Pill "Kembali" di kiri (+ aksi opsional di kanan)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onBack ??
                    () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _primaryGreen, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_back_rounded,
                        size: 14,
                        color: _textColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kembali',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ?trailing,
            ],
          ),

          const SizedBox(height: 12),

          // 2. Di Bawahnya: Pill Badge Judul Halaman di Tengah
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: _primaryGreen,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header hijau melengkung standar GIAT dengan baris atas (Brand / Tombol Kembali + Pill Aksi)
/// dan jarak vertikal yang lega menuju bubble sapaan/informasi.
class AdminCurvedHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showBackButton;
  final String? pageTitle;
  final Widget? trailingAction;
  final Widget? bottomChild;

  const AdminCurvedHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBackButton = false,
    this.pageTitle,
    this.trailingAction,
    this.bottomChild,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: GiatHeaderStyle.headerDecoration,
      child: Stack(
        children: [
          const GiatHeaderCurvesOverlay(),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris Atas: Brand / Tombol Back di kiri, Pill Notifikasi & Profil di kanan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (showBackButton)
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => Navigator.of(context).maybePop(),
                                child: const Padding(
                                  padding: EdgeInsets.all(9),
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: pageTitle != null
                                  ? Text(
                                      pageTitle!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    )
                                  : const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: AppBrandTitle(),
                                    ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: AppBrandTitle(),
                        ),
                      ),
                    if (trailingAction != null) ...[
                      const SizedBox(width: 12),
                      trailingAction!,
                    ],
                  ],
                ),

                // Jarak vertikal yang lega agar kapsul lonceng/profil tidak mepet dengan bubble chat
                const SizedBox(height: 18),

                // Bubble Chat Informasi
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: GiatHeaderStyle.chatBubbleDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: GiatHeaderStyle.chatBubbleGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: GiatHeaderStyle.chatBubbleTextSecondary,
                            height: 1.38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (bottomChild != null) ...[
                  const SizedBox(height: 12),
                  bottomChild!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
