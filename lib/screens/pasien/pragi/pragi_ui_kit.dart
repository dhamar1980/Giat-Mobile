import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pragi_topography_background.dart';

/// Design tokens & reusable widgets untuk seluruh alur skrining AI PRAGI
/// (halaman pertanyaan & halaman hasil). File ini HANYA berisi tampilan.
class PragiUi {
  PragiUi._();

  static const Color green = Color(0xFF006B3A);
  static const Color greenDeep = Color(0xFF065A37);
  static const Color accent = Color(0xFF10B981);
  static const Color background = Color(0xFFF7F9FF);
  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color selectedBg = Color(0xFFDDEBFF);
  static const Color radioIdle = Color(0xFFDCE7FA);
  static const Color letterBg = Color(0xFFF1F2F9);
  static const Color ringTrack = Color(0xFFD6E4FF);

  static TextStyle text({
    double size = 13,
    FontWeight weight = FontWeight.w400,
    Color color = ink,
    double? height,
    FontStyle? fontStyle,
    double? letterSpacing,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
    );
  }

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  static BoxDecoration cardDecoration({
    Color color = Colors.white,
    double radius = 14,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: borderColor != null ? Border.all(color: borderColor) : null,
      boxShadow: softShadow,
    );
  }
}

/// Scaffold standar: background topografi + SafeArea.
class PragiScaffold extends StatelessWidget {
  final Widget child;
  const PragiScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PragiUi.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: PragiTopographyPainter()),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

/// Pill "← Kembali" + chip judul bagian di tengah.
class PragiHeader extends StatelessWidget {
  final String chipLabel;
  final VoidCallback onBack;

  const PragiHeader({super.key, required this.chipLabel, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: PragiUi.greenDeep, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 15, color: PragiUi.ink),
                  const SizedBox(width: 5),
                  Text(
                    'Kembali',
                    style: PragiUi.text(size: 12.5, weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(child: PragiChip(label: chipLabel)),
        ],
      ),
    );
  }
}

/// Chip hijau berpendar untuk judul bagian.
class PragiChip extends StatelessWidget {
  final String label;
  const PragiChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
      decoration: BoxDecoration(
        color: PragiUi.greenDeep,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: PragiUi.accent.withValues(alpha: 0.45),
            blurRadius: 8,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Text(
        label,
        style: PragiUi.text(
          size: 14,
          weight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Kartu putih umum.
class PragiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;
  final double radius;

  const PragiCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.borderColor,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: PragiUi.cardDecoration(
        color: color,
        radius: radius,
        borderColor: borderColor,
      ),
      child: child,
    );
  }
}

/// Kartu dengan cincin progres berisi persen (dipakai di pertanyaan & hasil).
class PragiRingCard extends StatelessWidget {
  final double progress; // 0..1
  final String centerLabel;
  final String centerValue;
  final String title;
  final String subtitle;
  final Color ringColor;
  final Color titleColor;

  const PragiRingCard({
    super.key,
    required this.progress,
    required this.centerLabel,
    required this.centerValue,
    required this.title,
    required this.subtitle,
    this.ringColor = PragiUi.green,
    this.titleColor = PragiUi.green,
  });

  @override
  Widget build(BuildContext context) {
    return PragiCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 7,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                  backgroundColor: PragiUi.ringTrack,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        centerLabel,
                        style: PragiUi.text(
                          size: 9.5,
                          color: PragiUi.muted,
                          weight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        centerValue,
                        style: PragiUi.text(
                          size: 14,
                          weight: FontWeight.w600,
                          color: PragiUi.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PragiUi.text(
                    size: 18,
                    weight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: PragiUi.text(
                    size: 11.5,
                    color: PragiUi.muted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bubble hijau dengan maskot PRAGI di kiri bawah.
class PragiBubble extends StatelessWidget {
  final String title;
  final String? hint;

  const PragiBubble({super.key, required this.title, this.hint});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: PragiUi.softShadow,
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/pragi.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFDCFCE7),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  size: 22,
                  color: PragiUi.green,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: PragiUi.green,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomRight: Radius.circular(14),
                bottomLeft: Radius.circular(3),
              ),
              boxShadow: [
                BoxShadow(
                  color: PragiUi.green.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PragiUi.text(
                    size: 14,
                    weight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
                if (hint != null && hint!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    hint!,
                    style: PragiUi.text(
                      size: 11.5,
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Judul bagian di tengah, mis. "Jawaban Anda".
class PragiSectionLabel extends StatelessWidget {
  final String label;
  const PragiSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: PragiUi.text(size: 14.5, weight: FontWeight.w600),
      ),
    );
  }
}

/// Kartu pilihan jawaban (A, B, C ...) dengan indikator radio di kanan.
class PragiOptionCard extends StatelessWidget {
  final String letter;
  final String title;
  final String? description;
  final bool selected;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final bool compact;

  const PragiOptionCard({
    super.key,
    required this.letter,
    required this.title,
    required this.selected,
    required this.onTap,
    this.description,
    this.leadingIcon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final double letterSize = compact ? 28 : 34;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 10 : 12,
        ),
        decoration: PragiUi.cardDecoration(
          color: selected ? PragiUi.selectedBg : Colors.white,
          radius: 10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: letterSize,
              height: letterSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? PragiUi.green : PragiUi.letterBg,
              ),
              child: Text(
                letter,
                style: PragiUi.text(
                  size: compact ? 11 : 12,
                  weight: FontWeight.w600,
                  color: selected ? Colors.white : PragiUi.muted,
                ),
              ),
            ),
            SizedBox(width: compact ? 8 : 12),
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 22, color: PragiUi.muted),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: PragiUi.text(
                      size: compact ? 12.5 : 13.5,
                      weight: description != null
                          ? FontWeight.w600
                          : FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      style: PragiUi.text(
                        size: 12,
                        color: PragiUi.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            selected
                ? const Icon(Icons.check_circle_rounded,
                    size: 22, color: PragiUi.green)
                : Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: PragiUi.radioIdle,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

/// Kartu info dengan ikon di kotak putih ("Mengapa data ini dibutuhkan?").
class PragiInfoCard extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;

  const PragiInfoCard({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return PragiCard(
      padding: const EdgeInsets.all(10),
      radius: 12,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: PragiUi.cardDecoration(radius: 12),
            child: Icon(icon, size: 22, color: PragiUi.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PragiUi.text(size: 12.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  textAlign: TextAlign.justify,
                  style: PragiUi.text(
                    size: 12,
                    color: const Color(0xFF334155),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol utama hijau lebar.
class PragiPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const PragiPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = PragiUi.green,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: color.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: PragiUi.text(
                  size: 15,
                  weight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 19),
          ],
        ),
      ),
    );
  }
}

/// Tombol sekunder berbingkai hijau.
class PragiOutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const PragiOutlineButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: PragiUi.text(
            size: 12.5,
            weight: FontWeight.w500,
            color: PragiUi.greenDeep,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: PragiUi.greenDeep,
          side: const BorderSide(color: PragiUi.greenDeep, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
