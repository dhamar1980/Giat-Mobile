import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RUANG VIDEO CALL PASIEN - DOKTER (Telemedicine Video Call Experience)
// ─────────────────────────────────────────────────────────────────────────────

class KonsultasiVideoCallScreen extends StatefulWidget {
  final String doctorName;
  final String specialty;
  final String avatarUrl;

  const KonsultasiVideoCallScreen({
    super.key,
    required this.doctorName,
    this.specialty = 'Dokter Spesialis',
    this.avatarUrl = '',
  });

  @override
  State<KonsultasiVideoCallScreen> createState() => _KonsultasiVideoCallScreenState();
}

class _KonsultasiVideoCallScreenState extends State<KonsultasiVideoCallScreen> {
  // Call controls state
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isFrontCamera = true;
  bool _isSpeakerOn = true;
  bool _isSwappedView = false; // Tap PiP to swap remote and local view

  // Live timer
  int _secondsElapsed = 252; // Start around 04:12 matching user screenshot
  Timer? _timer;


  static const _defaultDoctorPhoto =
      'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=800';
  static const _defaultPatientPhoto =
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=400';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _secondsElapsed++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get _doctorPhotoUrl {
    if (widget.avatarUrl.isNotEmpty && widget.avatarUrl.startsWith('http')) {
      return widget.avatarUrl;
    }
    return _defaultDoctorPhoto;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. MAIN FULL-SCREEN VIDEO FEED ──
          Positioned.fill(
            child: _isSwappedView ? _buildLocalCameraFeed(isFullScreen: true) : _buildRemoteDoctorVideoFeed(),
          ),

          // ── 2. TOP VIGNETTE & GRADIENT SHADOW ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 190,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // ── 3. BOTTOM VIGNETTE & GRADIENT SHADOW ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 240,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // ── 4. TOP OVERLAY HUD ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Back / Minimize Button
                      _buildFrostedButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        size: 42,
                        iconSize: 18,
                        onTap: () => _confirmEndCall(context),
                      ),
                      const SizedBox(width: 12),

                      // Doctor Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.doctorName,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Color(0xFF10B981),
                                  size: 16,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.specialty,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quality & Flip camera quick toggle
                      _buildFrostedButton(
                        icon: Icons.flip_camera_ios_rounded,
                        size: 42,
                        iconSize: 20,
                        onTap: _toggleFlipCamera,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Call Status Indicators: Live Timer + HD Badge
                  Row(
                    children: [
                      // Timer Pill with pulsing dot
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              _formatDuration(_secondsElapsed),
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // HD / Connection Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF047857).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.wifi_rounded,
                              size: 14,
                              color: Color(0xFF34D399),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'HD 1080p',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF34D399),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── 5. FLOATING PICTURE-IN-PICTURE (PiP) SELF CAMERA PREVIEW ──
          Positioned(
            right: 18,
            top: 135,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isSwappedView = !_isSwappedView;
                });
              },
              child: Hero(
                tag: 'pip_camera_preview',
                child: Container(
                  width: 114,
                  height: 168,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _isSwappedView
                            ? _buildRemoteDoctorVideoFeed(isThumbnail: true)
                            : _buildLocalCameraFeed(isFullScreen: false),

                        // Swap hint icon on PiP
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.sync_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // Label
                        Positioned(
                          bottom: 6,
                          left: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _isSwappedView ? 'Dokter' : 'Anda (Pasien)',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 6. FLOATING BOTTOM CONTROL BAR ──
          Positioned(
            left: 16,
            right: 16,
            bottom: 30,
            child: SafeArea(
              top: false,
              child: _buildModernControlBar(context),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // REMOTE DOCTOR VIDEO FEED (Full-screen Realistic Video Stream)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildRemoteDoctorVideoFeed({bool isThumbnail = false}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Live Camera Image Simulation
        Image.network(
          _doctorPhotoUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackDoctorRoom(isThumbnail: isThumbnail),
        ),

        // Live Camera Glare / Vignette Layer
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.1,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: isThumbnail ? 0.2 : 0.35),
              ],
            ),
          ),
        ),

        // Speaking Waveform Overlay (when not thumbnail)
        if (!isThumbnail)
          Positioned(
            bottom: 120,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.graphic_eq_rounded,
                    color: Color(0xFF10B981),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.doctorName} sedang berbicara',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Fallback if offline/network fails
  Widget _buildFallbackDoctorRoom({bool isThumbnail = false}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF065A37), Color(0xFF0F172A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isThumbnail ? 48 : 110,
              height: isThumbnail ? 48 : 110,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981), width: 2),
              ),
              child: Icon(
                Icons.medical_services_rounded,
                color: const Color(0xFF34D399),
                size: isThumbnail ? 26 : 56,
              ),
            ),
            if (!isThumbnail) ...[
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
                'Video Telekonsultasi Aktif',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF34D399),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // LOCAL CAMERA FEED (Self-view of Patient)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildLocalCameraFeed({required bool isFullScreen}) {
    if (_isVideoOff) {
      return Container(
        color: const Color(0xFF0F172A),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isFullScreen ? 80 : 44,
                height: isFullScreen ? 80 : 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.videocam_off_rounded,
                  color: Colors.white70,
                  size: isFullScreen ? 40 : 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kamera Anda Dimatikan',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: isFullScreen ? 14 : 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          _defaultPatientPhoto,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF334155)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: const Center(
              child: Icon(Icons.person_rounded, size: 48, color: Colors.white54),
            ),
          ),
        ),

        // Mute Badge on PiP
        if (_isMuted)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic_off_rounded,
                size: 13,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BOTTOM CONTROL BAR (Frosted Modern Floating Panel)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildModernControlBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 1. Mic Mute Toggle
              _buildControlButton(
                icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                label: _isMuted ? 'Mute' : 'Mic',
                isActive: !_isMuted,
                onTap: () {
                  setState(() => _isMuted = !_isMuted);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isMuted ? 'Mikrofon dinonaktifkan.' : 'Mikrofon aktif.'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),

              // 2. Video Camera Toggle
              _buildControlButton(
                icon: _isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                label: _isVideoOff ? 'Video Off' : 'Video',
                isActive: !_isVideoOff,
                onTap: () {
                  setState(() => _isVideoOff = !_isVideoOff);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isVideoOff ? 'Kamera video dimatikan.' : 'Kamera video diaktifkan.'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),

              // 3. Speaker Toggle
              _buildControlButton(
                icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                label: _isSpeakerOn ? 'Speaker' : 'Earphone',
                isActive: _isSpeakerOn,
                onTap: () {
                  setState(() => _isSpeakerOn = !_isSpeakerOn);
                },
              ),

              // 4. End Call Red Button
              GestureDetector(
                onTap: () => _confirmEndCall(context),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFDC2626),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.call_end_rounded,
                      color: Colors.white,
                      size: 28,
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

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.2),
                    width: 1.4,
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 22,
                    color: isActive ? Colors.white : Colors.white70,
                  ),
                ),
              ),
              if (badgeCount != null && badgeCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedButton({
    required IconData icon,
    required double size,
    required double iconSize,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }

  void _toggleFlipCamera() {
    setState(() => _isFrontCamera = !_isFrontCamera);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFrontCamera ? 'Beralih ke Kamera Depan' : 'Beralih ke Kamera Belakang'),
        duration: const Duration(seconds: 1),
      ),
    );
  }



  // ─────────────────────────────────────────────────────────────────────────────
  // END CALL CONFIRMATION
  // ─────────────────────────────────────────────────────────────────────────────
  void _confirmEndCall(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Akhiri Video Call?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        content: Text(
          'Sesi konsultasi video dengan ${widget.doctorName} akan selesai. Durasi panggilan: ${_formatDuration(_secondsElapsed)}.',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Lanjutkan Sesi', style: GoogleFonts.inter(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Video call berakhir. Durasi: ${_formatDuration(_secondsElapsed)}'),
                ),
              );
            },
            child: Text('Akhiri', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
