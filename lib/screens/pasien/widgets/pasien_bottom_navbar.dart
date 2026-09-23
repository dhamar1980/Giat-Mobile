import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../master_layout.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PASIEN BOTTOM NAVBAR (Konsisten & Selalu Hadir di Semua Menu Pasien)
// ─────────────────────────────────────────────────────────────────────────────

class PasienBottomNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final String userName;

  static const _darkGreen = Color(0xFF065A37);

  const PasienBottomNavbar({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.userName = 'Pasien',
  });

  void _handleTap(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
      return;
    }

    if (index == currentIndex) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => MasterLayout(
          userName: userName,
          initialIndex: index,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.16),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, -3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                index: 0,
                icon: currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                label: 'Home',
              ),
              _buildNavItem(
                context: context,
                index: 1,
                icon: currentIndex == 1 ? Icons.medical_services_rounded : Icons.medical_services_outlined,
                label: 'Konsultasi',
              ),
              _buildPragiCenterButton(context),
              _buildNavItem(
                context: context,
                index: 3,
                icon: currentIndex == 3 ? Icons.show_chart_rounded : Icons.show_chart_outlined,
                label: 'Pantau',
              ),
              _buildNavItem(
                context: context,
                index: 4,
                icon: currentIndex == 4 ? Icons.medication_rounded : Icons.medication_outlined,
                label: 'Obat',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => _handleTap(context, index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 22 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                color: _darkGreen,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            if (!isSelected) const SizedBox(height: 3),
            Icon(
              icon,
              size: 24,
              color: isSelected ? _darkGreen : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _darkGreen : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPragiCenterButton(BuildContext context) {
    final isSelected = currentIndex == 2;
    return GestureDetector(
      onTap: () => _handleTap(context, 2),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 22 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: _darkGreen,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -14),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF22C55E) : Colors.white,
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.45),
                      blurRadius: 14,
                      spreadRadius: 2,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/pragi.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFDCFCE7),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: _darkGreen,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -10),
              child: Text(
                'PRAGI',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? _darkGreen : const Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
