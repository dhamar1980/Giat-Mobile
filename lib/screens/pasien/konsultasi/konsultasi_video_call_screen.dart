import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// KONSULTASI VIDEO CALL SCREEN (Sesuai Desain Figma)
// ─────────────────────────────────────────────────────────────────────────────

class KonsultasiVideoCallScreen extends StatefulWidget {
  final String doctorName;
  final String specialty;
  final String avatarUrl;

  const KonsultasiVideoCallScreen({
    super.key,
    this.doctorName = 'Dr. Budi Santoso',
    this.specialty = 'Spesialis Ginjal & Hipertensi',
    this.avatarUrl = 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=300',
  });

  @override
  State<KonsultasiVideoCallScreen> createState() => _KonsultasiVideoCallScreenState();
}

class _KonsultasiVideoCallScreenState extends State<KonsultasiVideoCallScreen> {
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isFrontCamera = true;

  static const _darkGreen = Color(0xFF065A37);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // ── 1. Main Doctor Video Feed (Background) ──
          Positioned.fill(
            child: _buildDoctorVideoBackground(),
          ),

          // Subtle gradient overlays for readability
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── 2. Top Header Bar (Back, Doctor Info, Chat Button) ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Back Button Pill
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _darkGreen, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back_rounded, size: 16, color: _darkGreen),
                          const SizedBox(width: 4),
                          Text(
                            'Kembali',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _darkGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Doctor Avatar + Name
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              widget.avatarUrl,
                              width: 38,
                              height: 38,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 38,
                                height: 38,
                                color: const Color(0xFFDCFCE7),
                                child: const Icon(Icons.person_rounded, size: 22, color: _darkGreen),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.doctorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  widget.specialty,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Switch to Chat Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 22,
                          color: _darkGreen,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 3. Floating Picture-in-Picture (Patient Camera) ──
          Positioned(
            right: 20,
            bottom: 120,
            child: _buildPatientPiP(),
          ),

          // ── 4. Bottom Controls Bar ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 34,
            child: _buildCallControls(),
          ),
        ],
      ),
    );
  }

  // Doctor Video Background
  Widget _buildDoctorVideoBackground() {
    return Container(
      color: const Color(0xFF1E293B),
      child: Image.network(
        'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=1200',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFF334155),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, size: 60, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Text(
                widget.doctorName,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Video Call Terhubung...',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Patient Front-Camera PiP
  Widget _buildPatientPiP() {
    return Container(
      width: 120,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _isVideoOff
            ? Container(
                color: const Color(0xFF0F172A),
                child: const Center(
                  child: Icon(Icons.videocam_off_rounded, size: 28, color: Colors.white54),
                ),
              )
            : Image.network(
                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=400',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFF334155),
                  child: const Center(
                    child: Icon(Icons.person_outline_rounded, size: 36, color: Colors.white70),
                  ),
                ),
              ),
      ),
    );
  }

  // Bottom 4 Control Buttons
  Widget _buildCallControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1. Mute Mic
        _buildCircleButton(
          icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          bgColor: _isMuted ? Colors.white : Colors.black.withValues(alpha: 0.45),
          iconColor: _isMuted ? const Color(0xFFDC2626) : Colors.white,
          onTap: () {
            setState(() {
              _isMuted = !_isMuted;
            });
          },
        ),
        const SizedBox(width: 16),

        // 2. Video Camera Toggle
        _buildCircleButton(
          icon: _isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
          bgColor: _isVideoOff ? Colors.white : Colors.black.withValues(alpha: 0.45),
          iconColor: _isVideoOff ? const Color(0xFFDC2626) : Colors.white,
          onTap: () {
            setState(() {
              _isVideoOff = !_isVideoOff;
            });
          },
        ),
        const SizedBox(width: 16),

        // 3. Switch Camera
        _buildCircleButton(
          icon: Icons.flip_camera_ios_rounded,
          bgColor: Colors.black.withValues(alpha: 0.45),
          iconColor: Colors.white,
          onTap: () {
            setState(() {
              _isFrontCamera = !_isFrontCamera;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isFrontCamera ? 'Kamera Depan Aktif' : 'Kamera Belakang Aktif'),
                duration: const Duration(milliseconds: 700),
              ),
            );
          },
        ),
        const SizedBox(width: 16),

        // 4. End Call (Red button)
        _buildCircleButton(
          icon: Icons.call_end_rounded,
          bgColor: const Color(0xFFE11D48),
          iconColor: Colors.white,
          size: 62,
          iconSize: 28,
          onTap: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
    double size = 52,
    double iconSize = 24,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: iconSize),
        ),
      ),
    );
  }
}
