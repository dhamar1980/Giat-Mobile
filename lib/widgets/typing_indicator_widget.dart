import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget indikator lawan bicara sedang mengetik dengan 3 titik beranimasi
class TypingIndicatorWidget extends StatefulWidget {
  final String partnerName;
  final Color dotColor;

  const TypingIndicatorWidget({
    super.key,
    required this.partnerName,
    this.dotColor = const Color(0xFF065A37),
  });

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.partnerName} sedang mengetik',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _animCtrl,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final value = (_animCtrl.value - delay) % 1.0;
                  final scale = (value < 0.5) ? (1.0 + value * 0.8) : (1.4 - (value - 0.5) * 0.8);

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: widget.dotColor.withValues(alpha: (value < 0.5) ? 0.9 : 0.4),
                      shape: BoxShape.circle,
                    ),
                    transform: Matrix4.diagonal3Values(scale, scale, 1.0),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
