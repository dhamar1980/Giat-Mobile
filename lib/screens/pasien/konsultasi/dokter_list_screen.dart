import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'konsultasi_chat_screen.dart';
import 'dokter_detail_screen.dart';
import 'jadwalkan_konsultasi_screen.dart';
import '../profile/profile_pasien_screen.dart';
import '../notifikasi/pasien_notifikasi_screen.dart';
import '../widgets/pasien_bottom_navbar.dart';
import '../../../widgets/giat_background.dart';
import '../../../widgets/app_brand_title.dart';
import '../../../widgets/giat_header_style.dart';
import '../../../services/konsultasi_api_service.dart';
import '../../../utils/time_utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
// KONSULTASI: DAFTAR DOKTER & KONSULTASI SAYA (Sesuai Desain Figma)
// ─────────────────────────────────────────────────────────────────────────────

class DokterListScreen extends StatefulWidget {
  final String userName;
  final bool isEmbedded;

  const DokterListScreen({
    super.key,
    this.userName = 'Pasien',
    this.isEmbedded = false,
  });

  @override
  State<DokterListScreen> createState() => _DokterListScreenState();
}

class _DokterListScreenState extends State<DokterListScreen> {
  String _selectedCategory = 'Konsultasi Saya';
  final TextEditingController _searchCtrl = TextEditingController();

  static const _darkGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF7F9FF);
  static const _cardBorderColor = Color(0xFFE2E8F0);

  final List<String> _categories = [
    'Konsultasi Saya',
    'Semua Dokter',
    'Dokter Umum',
    'Dokter Spesialis Penyakit Dalam',
    'Dokter Ginjal',
  ];

  List<Map<String, dynamic>> _apiDoctors = [];
  List<Map<String, dynamic>> _myConsultations = [];
  bool _isLoadingConsultations = false;
  String? _consultationErrorMessage;

  /// Helper untuk menormalisasi data dokter dari backend API maupun fallback
  static Map<String, dynamic> _normalizeDoctor(Map<String, dynamic> raw) {
    final id = (raw['id_dokter'] ?? raw['id'] ?? '').toString();
    final nama = (raw['nama'] ?? raw['name'] ?? 'Dokter GIAT').toString();
    final spesialisasi = (raw['spesialisasi'] ?? raw['specialty'] ?? 'Dokter Umum').toString();
    final foto = (raw['foto_profile'] ?? raw['foto_profil'] ?? raw['avatarUrl'] ?? '').toString();
    final tarif = raw['tarif_konsultasi'] ?? raw['biaya_konsultasi'] ?? raw['price'];
    final institusi = (raw['institusi'] ?? raw['instansi'] ?? raw['hospital'] ?? 'Klinik Layanan GIAT').toString();

    // Normalisasi kategori spesialisasi dokter
    final specLower = spesialisasi.toLowerCase();
    String category = 'Dokter Umum';
    if (specLower.contains('ginjal') || specLower.contains('kgh') || specLower.contains('nefro')) {
      category = 'Dokter Ginjal';
    } else if (specLower.contains('penyakit dalam') || specLower.contains('sp.pd') || specLower.contains('dalam')) {
      category = 'Dokter Spesialis Penyakit Dalam';
    } else {
      category = 'Dokter Umum';
    }

    // Format harga
    String formattedPrice = 'Rp 150.000';
    if (tarif != null) {
      if (tarif is num) {
        formattedPrice = 'Rp ${tarif.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
      } else {
        final s = tarif.toString();
        if (s.startsWith('Rp')) {
          formattedPrice = s;
        } else {
          final val = double.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), ''))?.toInt();
          if (val != null) {
            formattedPrice = 'Rp ${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
          }
        }
      }
    }

    final avatar = foto.isNotEmpty
        ? foto
        : 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=300';

    return {
      ...raw,
      'id': id,
      'id_dokter': id,
      'name': nama,
      'nama': nama,
      'specialty': spesialisasi,
      'spesialisasi': spesialisasi,
      'category': category,
      'avatarUrl': avatar,
      'foto_profile': avatar,
      'hospital': institusi,
      'institusi': institusi,
      'price': formattedPrice,
      'schedule': TimeUtils.replaceTimezoneSuffix(raw['schedule']?.toString() ?? 'Tersedia Hari Ini, 14:00 WIB'),
      'isOnline': raw['isOnline'] ?? true,
      'isVerified': raw['isVerified'] ?? true,
      'isOngoing': raw['isOngoing'] ?? false,
      'status': raw['status'] ?? 'Online Sekarang',
      'experience': raw['experience'] ?? '8 tahun',
      'rating': raw['rating'] != null ? double.tryParse(raw['rating'].toString()) ?? 4.9 : 4.9,
      'bio': raw['bio'] ?? '',
    };
  }

  /// Data dokter default dengan spesialisasi otentik masing-masing
  static final List<Map<String, dynamic>> _defaultDoctors = [
    // 1. Dokter Umum
    _normalizeDoctor({
      'id': 'anisa_putri',
      'id_dokter': 'anisa_putri',
      'name': 'dr. Anisa Putri',
      'nama': 'dr. Anisa Putri',
      'specialty': 'Dokter Umum',
      'spesialisasi': 'Dokter Umum',
      'hospital': 'Klinik Layanan GIAT',
      'price': 'Rp 75.000',
      'avatarUrl': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=300',
      'experience': '7 tahun',
      'rating': 4.9,
    }),
    _normalizeDoctor({
      'id': 'dedi_pratama',
      'id_dokter': 'dedi_pratama',
      'name': 'dr. Dedi Pratama',
      'nama': 'dr. Dedi Pratama',
      'specialty': 'Dokter Umum',
      'spesialisasi': 'Dokter Umum',
      'hospital': 'Klinik Pratama Sehat Ginjal',
      'price': 'Rp 50.000',
      'avatarUrl': 'https://images.unsplash.com/photo-1582750433449-648ed127bb54?auto=format&fit=crop&q=80&w=300',
      'experience': '5 tahun',
      'rating': 4.8,
    }),
    // 2. Dokter Spesialis Penyakit Dalam
    _normalizeDoctor({
      'id': 'ce5355fd-3da3-4cd4-953a-bdb1729d75cd',
      'id_dokter': 'ce5355fd-3da3-4cd4-953a-bdb1729d75cd',
      'name': 'dr. Budi Santoso, Sp.PD',
      'nama': 'dr. Budi Santoso, Sp.PD',
      'specialty': 'Dokter Spesialis Penyakit Dalam',
      'spesialisasi': 'Dokter Spesialis Penyakit Dalam',
      'hospital': 'RS Santo Borromeus Bandung',
      'price': 'Rp 120.000',
      'avatarUrl': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?auto=format&fit=crop&q=80&w=300',
      'experience': '12 tahun',
      'rating': 4.9,
    }),
    _normalizeDoctor({
      'id': 'eka_rahmawati',
      'id_dokter': 'eka_rahmawati',
      'name': 'dr. Eka Rahmawati, Sp.PD',
      'nama': 'dr. Eka Rahmawati, Sp.PD',
      'specialty': 'Dokter Spesialis Penyakit Dalam',
      'spesialisasi': 'Dokter Spesialis Penyakit Dalam',
      'hospital': 'RS Hermina Pasteur Bandung',
      'price': 'Rp 130.000',
      'avatarUrl': 'https://images.unsplash.com/photo-1594824813629-87a70197d19a?auto=format&fit=crop&q=80&w=300',
      'experience': '8 tahun',
      'rating': 4.8,
    }),
    // 3. Dokter Ginjal
    _normalizeDoctor({
      'id': 'andi_wijaya',
      'id_dokter': 'andi_wijaya',
      'name': 'dr. Andi Wijaya, Sp.PD-KGH',
      'nama': 'dr. Andi Wijaya, Sp.PD-KGH',
      'specialty': 'Dokter Ginjal',
      'spesialisasi': 'Dokter Ginjal',
      'hospital': 'RSUP Dr. Hasan Sadikin Bandung',
      'price': 'Rp 150.000',
      'avatarUrl': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=300',
      'experience': '12 tahun',
      'rating': 4.9,
    }),
    _normalizeDoctor({
      'id': 'hendra_setiawan',
      'id_dokter': 'hendra_setiawan',
      'name': 'dr. Hendra Setiawan, Sp.PD-KGH',
      'nama': 'dr. Hendra Setiawan, Sp.PD-KGH',
      'specialty': 'Dokter Ginjal',
      'spesialisasi': 'Dokter Ginjal',
      'hospital': 'Pusat Nutrisi & Ginjal Sehat',
      'price': 'Rp 150.000',
      'avatarUrl': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?auto=format&fit=crop&w=300',
      'experience': '9 tahun',
      'rating': 4.9,
    }),
  ];

  @override
  void initState() {
    super.initState();
    _fetchLiveDoctors();
    _fetchKonsultasiSaya();
  }

  Future<void> _fetchKonsultasiSaya() async {
    setState(() {
      _isLoadingConsultations = true;
      _consultationErrorMessage = null;
    });
    try {
      final res = await KonsultasiApiService().getRiwayatPasien();
      if (res.success && res.data != null && mounted) {
        setState(() {
          _myConsultations = res.data!.map<Map<String, dynamic>>((item) {
            if (item is Map<String, dynamic>) return item;
            return Map<String, dynamic>.from(item as Map);
          }).toList();
        });
      } else if (!res.success && mounted) {
        setState(() {
          _consultationErrorMessage = res.message;
        });
        debugPrint('⚠️ Gagal getRiwayatPasien: ${res.message}');
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching konsultasi saya: $e');
      if (mounted) {
        setState(() {
          _consultationErrorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingConsultations = false);
    }
  }

  Future<void> _fetchLiveDoctors({String? search, String? spesialisasi}) async {
    try {
      final catRes = await KonsultasiApiService().getKategoriDokter();
      if (catRes.success && catRes.data != null && catRes.data!.isNotEmpty && mounted) {
        final List<String> cats = ['Konsultasi Saya', 'Semua Dokter'];
        for (var c in catRes.data!) {
          final name = c is Map ? (c['nama'] ?? c['name'] ?? c['kategori']) : c.toString();
          if (name != null && !cats.contains(name.toString())) {
            cats.add(name.toString());
          }
        }
        setState(() {
          _categories.clear();
          _categories.addAll(cats);
        });
      }
    } catch (_) {}

    try {
      final res = await KonsultasiApiService().getDokterList(
        search: search,
        spesialisasi: spesialisasi,
      );
      if (res.success && res.data != null && res.data!.isNotEmpty && mounted) {
        setState(() {
          _apiDoctors = res.data!.map<Map<String, dynamic>>((d) {
            final raw = d is Map<String, dynamic> ? d : Map<String, dynamic>.from(d as Map);
            return _normalizeDoctor(raw);
          }).toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // List dokter bersumber dari database API, atau fallback ke default list
    final List<Map<String, dynamic>> sourceList =
        _apiDoctors.isNotEmpty ? _apiDoctors : _defaultDoctors;

    List<Map<String, dynamic>> combinedList = [];
    if (_selectedCategory == 'Semua Dokter' || _selectedCategory == 'Konsultasi Saya') {
      combinedList = List<Map<String, dynamic>>.from(sourceList);
    } else {
      final selected = _selectedCategory.toLowerCase();
      combinedList = sourceList.where((doc) {
        final cat = (doc['category'] ?? '').toString().toLowerCase();
        final spec = (doc['specialty'] ?? doc['spesialisasi'] ?? '').toString().toLowerCase();

        if (selected.contains('ginjal')) {
          return cat.contains('ginjal') || spec.contains('ginjal') || spec.contains('kgh') || spec.contains('nefro');
        } else if (selected.contains('penyakit dalam')) {
          return cat.contains('penyakit dalam') || spec.contains('penyakit dalam') || spec.contains('sp.pd');
        } else if (selected.contains('umum')) {
          return cat.contains('umum') || spec.contains('umum');
        }
        return cat == selected || spec.contains(selected);
      }).toList();
    }

    final query = _searchCtrl.text.toLowerCase().trim();
    final filteredDoctors = combinedList.where((doc) {
      if (query.isEmpty) return true;
      final name = (doc['name'] ?? doc['nama'] ?? '').toString().toLowerCase();
      final spec = (doc['specialty'] ?? doc['spesialisasi'] ?? '').toString().toLowerCase();
      final hosp = (doc['hospital'] ?? doc['institusi'] ?? '').toString().toLowerCase();
      return name.contains(query) || spec.contains(query) || hosp.contains(query);
    }).toList();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top Header Section (Green Arc + Bubbles) (Fixed at top, does not scroll) ──
        _buildHeaderSection(),

        // ── Scrollable Body Content Below Header ──
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Search Bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSearchBar(),
                ),

                const SizedBox(height: 14),

                // ── Filter Chips ──
                _buildFilterChips(),

                const SizedBox(height: 20),

                // ── Content Switcher: Konsultasi Saya OR Doctor Search List ──
                if (_selectedCategory == 'Konsultasi Saya')
                  _buildKonsultasiSayaView()
                else
                  _buildDokterOnlineSection(filteredDoctors),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _KonsultasiTopographyPainter(),
            ),
          ),
          Positioned.fill(
            child: content,
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      bottomNavigationBar: _buildBottomNavigationBar(context),
      body: Stack(
        children: [
          // Background Topography
          Positioned.fill(
            child: CustomPaint(
              painter: _KonsultasiTopographyPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(child: content),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HEADER SECTION (Matches Figma Node)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      decoration: GiatHeaderStyle.headerDecoration,
      child: Stack(
        children: [
          const GiatHeaderCurvesOverlay(),

          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              widget.isEmbedded
                  ? (MediaQuery.of(context).padding.top + 86)
                  : (MediaQuery.of(context).padding.top + 8),
              20,
              20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isEmbedded) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const AppBrandTitle(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Stack(
                              children: [
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(5),
                                  icon: const Icon(
                                    Icons.notifications_none_rounded,
                                    size: 24,
                                    color: Color(0xFF1F2937),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const PasienNotifikasiScreen(),
                                      ),
                                    );
                                  },
                                ),
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    width: 8.5,
                                    height: 8.5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfilePasienScreen(userName: widget.userName),
                                  ),
                                );
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF044E2F),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_rounded, size: 22, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Single Chat Bubble
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 340),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: GiatHeaderStyle.chatBubbleDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Halo! Mulai konsultasi dokter spesialis GIAT 👋',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: GiatHeaderStyle.chatBubbleGreen,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rawat ginjal hari ini demi masa depan. Langkah kecilmu menjaga ginjal tetap sehat. ✨✨',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: GiatHeaderStyle.chatBubbleTextSecondary,
                            height: 1.35,
                          ),
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
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SEARCH BAR
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: 'Cari dokter...',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF64748B),
            size: 22,
          ),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FILTER CHIPS (Horizontal Scrollable with Figma Badge)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          final isKonsultasiSaya = cat == 'Konsultasi Saya';

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _darkGreen : const Color(0xFFEAF1F8),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _darkGreen.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cat,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                    if (isKonsultasiSaya) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '1',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // VIEW: KONSULTASI SAYA (KONSULTASI MENDATANG & RIWAYAT KONSULTASI)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildKonsultasiSayaView() {
    if (_isLoadingConsultations) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: _darkGreen),
        ),
      );
    }

    final upcomingRaw = _myConsultations.where((c) {
      final status = (c['status'] ?? c['status_konsultasi'] ?? '').toString().toLowerCase();
      final statusBayar = (c['status_pembayaran'] ?? c['status_bayar'] ?? '').toString().toLowerCase();

      // Tampilkan konsultasi yang berstatus lunas atau yang sudah aktif berlangsung
      final isLunas = statusBayar == 'lunas' ||
          statusBayar == 'paid' ||
          statusBayar == 'success' ||
          (statusBayar.isEmpty && (status == 'berlangsung' || status == 'aktif'));
      final isWaitingPayment = status == 'menunggu_pembayaran' || statusBayar == 'menunggu_pembayaran';
      final isNotFinished = status != 'selesai' && status != 'dibatalkan' && status != 'cancelled';

      return isLunas && !isWaitingPayment && isNotFinished;
    }).toList();

    // Urutkan upcoming: yang sedang 'berlangsung'/'aktif' diutamakan, lalu urutkan dari waktu terbaru
    upcomingRaw.sort((a, b) {
      final statusA = (a['status'] ?? a['status_konsultasi'] ?? '').toString().toLowerCase();
      final statusB = (b['status'] ?? b['status_konsultasi'] ?? '').toString().toLowerCase();

      final isOngoingA = statusA == 'berlangsung' || statusA == 'aktif';
      final isOngoingB = statusB == 'berlangsung' || statusB == 'aktif';

      if (isOngoingA && !isOngoingB) return -1;
      if (!isOngoingA && isOngoingB) return 1;

      final timeA = TimeUtils.toIndonesianTime(a['created_at'] ?? a['tanggal_konsultasi'] ?? a['tanggal'] ?? '');
      final timeB = TimeUtils.toIndonesianTime(b['created_at'] ?? b['tanggal_konsultasi'] ?? b['tanggal'] ?? '');

      final compTime = timeB.compareTo(timeA);
      if (compTime != 0) return compTime;

      final idA = (a['id'] ?? a['id_konsultasi'] ?? '').toString();
      final idB = (b['id'] ?? b['id_konsultasi'] ?? '').toString();
      return idB.compareTo(idA);
    });

    // Deduplikasi upcoming: 1 dokter hanya tampil 1 sesi konsultasi aktif (sesi terbaru/berlangsung)
    final List<Map<String, dynamic>> upcoming = [];
    final Set<String> seenUpcomingDoctors = {};

    for (final c in upcomingRaw) {
      final docKey = _getConsultationDoctorKey(c);
      if (!seenUpcomingDoctors.contains(docKey)) {
        seenUpcomingDoctors.add(docKey);
        upcoming.add(c);
      }
    }

    final riwayatRaw = _myConsultations.where((c) {
      final status = (c['status'] ?? c['status_konsultasi'] ?? '').toString().toLowerCase();
      return status == 'selesai' || status == 'dibatalkan' || status == 'cancelled';
    }).toList();

    // Deduplikasi riwayat berdasarkan ID konsultasi agar data unik
    final List<Map<String, dynamic>> riwayat = [];
    final Set<String> seenRiwayatIds = {};

    for (final c in riwayatRaw) {
      final id = (c['id'] ?? c['id_konsultasi'] ?? c['konsultasi_id'] ?? '').toString();
      if (id.isNotEmpty) {
        if (!seenRiwayatIds.contains(id)) {
          seenRiwayatIds.add(id);
          riwayat.add(c);
        }
      } else {
        riwayat.add(c);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Section: Konsultasi Mendatang ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Konsultasi Mendatang',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20, color: _darkGreen),
                tooltip: 'Segarkan data',
                onPressed: _fetchKonsultasiSaya,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (_consultationErrorMessage != null && _myConsultations.isEmpty)
          // ── KONDISI ERROR KONEKSI / TIMEOUT ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFED7AA), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    color: Color(0xFFEA580C),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Gagal Memuat Jadwal Konsultasi',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _consultationErrorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      'Coba Muat Ulang',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: _fetchKonsultasiSaya,
                  ),
                ),
              ],
            ),
          )
        else if (upcoming.isEmpty)
          // ── KONDISI 1: Belum Booking / Tidak Ada Jadwal (Figma Image 1) ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _cardBorderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _SubtleCardOverlayPainter()),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF5FC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.calendar_today_outlined,
                        color: Color(0xFF047857),
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak ada jadwal konsultasi mendatang.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pantau kesehatan ginjal Anda secara teratur dengan sesi medis terjadwal.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _darkGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedCategory = 'Semua Dokter';
                          });
                        },
                        child: Text(
                          'Cari Dokter Sekarang',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else if (upcoming.isNotEmpty)
          ...upcoming.map((c) => _buildConsultationItemCard(c, isOngoing: true))
        else
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cardBorderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF64748B)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tidak ada sesi konsultasi aktif saat ini.',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),

        // ── 2. Section: Riwayat Konsultasi ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Riwayat Konsultasi',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (riwayat.isNotEmpty)
          ...riwayat.map((c) => _buildConsultationItemCard(c, isOngoing: false))
        else
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cardBorderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, size: 20, color: Color(0xFF64748B)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Belum ada riwayat konsultasi selesai.',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _getConsultationDoctorKey(Map<String, dynamic> c) {
    final dokter = (c['dokter'] is Map) ? (c['dokter'] as Map) : <String, dynamic>{};
    String docName = (dokter['nama'] ?? c['nama_dokter'] ?? '').toString().trim();
    if (docName.toLowerCase().contains('realtime')) {
      docName = 'dr. Budi Santoso, Sp.PD';
    }
    if (docName.isNotEmpty) {
      return 'name_${docName.toLowerCase()}';
    }
    final rawDocId = dokter['id'] ?? c['id_dokter'] ?? c['dokter_id'];
    if (rawDocId != null && rawDocId.toString().isNotEmpty) {
      return 'id_${rawDocId.toString()}';
    }
    return (c['id'] ?? c['id_konsultasi'] ?? c['konsultasi_id'] ?? '').toString();
  }

  Widget _buildConsultationItemCard(Map<String, dynamic> c, {required bool isOngoing}) {
    final id = (c['id'] ?? c['id_konsultasi'] ?? c['konsultasi_id'] ?? '').toString();
    final dokter = (c['dokter'] is Map) ? (c['dokter'] as Map) : <String, dynamic>{};
    String doctorName = (dokter['nama'] ?? c['nama_dokter'] ?? 'Dr. Anisa Putri').toString();
    String specialty = (dokter['spesialisasi'] ?? c['spesialisasi'] ?? 'Spesialis Penyakit Dalam').toString();
    if (doctorName.toLowerCase().contains('realtime')) {
      doctorName = 'dr. Budi Santoso, Sp.PD';
      specialty = 'Dokter Spesialis Penyakit Dalam';
    }
    final avatarUrl = (dokter['foto_profile'] ?? c['foto_profile'] ?? '').toString();
    final rawTanggal = (c['tanggal_konsultasi'] ?? c['tanggal'] ?? c['created_at'] ?? '').toString();
    final tanggal = rawTanggal.isNotEmpty
        ? TimeUtils.formatDate(rawTanggal, useIndonesianMonth: true, withDayName: true)
        : 'Jadwal Aktif';

    String jam;
    if (c['jam_mulai'] != null && c['jam_mulai'].toString().isNotEmpty) {
      final rawJam = c['jam_mulai'].toString().trim();
      final parts = rawJam.split(':');
      if (parts.length >= 2) {
        final h = parts[0].padLeft(2, '0');
        final m = parts[1].padLeft(2, '0');
        jam = '$h:$m ${TimeUtils.getTimeZoneName()}';
      } else {
        jam = '$rawJam ${TimeUtils.getTimeZoneName()}';
      }
    } else if (c['created_at'] != null && c['created_at'].toString().isNotEmpty) {
      jam = TimeUtils.formatTimeWithZone(c['created_at']);
    } else {
      jam = 'Jadwal Medis';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _SubtleCardOverlayPainter()),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Info Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: avatarUrl.isNotEmpty
                          ? Image.network(
                              avatarUrl,
                              width: 58,
                              height: 58,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _buildAvatarPlaceholder(),
                            )
                          : _buildAvatarPlaceholder(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  doctorName,
                                  style: GoogleFonts.inter(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isOngoing ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isOngoing ? 'Aktif' : 'Selesai',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isOngoing ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            specialty,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Schedule Details Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F6FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF16A34A)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tanggal.isNotEmpty ? tanggal : 'Jadwal Aktif',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF16A34A)),
                          const SizedBox(width: 8),
                          Text(
                            jam,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Action Button: navigates with this exact consultation ID!
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOngoing ? _darkGreen : Colors.white,
                      foregroundColor: isOngoing ? Colors.white : _darkGreen,
                      side: isOngoing ? BorderSide.none : const BorderSide(color: _darkGreen, width: 1.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KonsultasiChatScreen(
                            doctorName: doctorName,
                            specialty: specialty,
                            avatarUrl: avatarUrl.isNotEmpty
                                ? avatarUrl
                                : 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=300',
                            consultationId: id,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isOngoing ? Icons.videocam_rounded : Icons.chat_outlined,
                          size: 19,
                          color: isOngoing ? Colors.white : _darkGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOngoing ? 'Masuk Konsultasi' : 'Lihat Riwayat Chat',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isOngoing ? Colors.white : _darkGreen,
                          ),
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
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 58,
      height: 58,
      color: const Color(0xFFDCFCE7),
      child: const Icon(Icons.person_rounded, size: 32, color: _darkGreen),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DAFTAR DOKTER: LIST DOKTER LANGSUNG MENYATU KE BAWAH (2 TOMBOL: LIHAT PROFILE & BUAT JANJI)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDokterOnlineSection(List<Map<String, dynamic>> doctors) {
    if (doctors.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorderColor),
        ),
        child: Center(
          child: Text(
            'Tidak ada dokter ditemukan untuk kategori ini.',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: doctors.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final doc = doctors[index];
          return _buildDokterOnlineCard(doc, isOngoing: doc['isOngoing'] == true);
        },
      ),
    );
  }

  Widget _buildDokterOnlineCard(Map<String, dynamic> doc, {bool isOngoing = false}) {
    final avatarUrl = (doc['avatarUrl'] ?? doc['foto_profile'] ?? doc['foto_profil'] ?? '').toString();
    final doctorName = (doc['name'] ?? doc['nama'] ?? 'Dokter GIAT').toString();
    final specialty = (doc['specialty'] ?? doc['spesialisasi'] ?? 'Dokter Umum').toString();
    final schedule = TimeUtils.replaceTimezoneSuffix((doc['schedule'] ?? 'Tersedia Hari Ini, 14:00 WIB').toString());
    final price = (doc['price'] ?? 'Rp 150.000').toString();
    final status = (doc['status'] ?? 'Online Sekarang').toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Overlay
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(
                painter: _SubtleCardOverlayPainter(),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: avatarUrl.isNotEmpty && (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://'))
                          ? Image.network(
                              avatarUrl,
                              width: 58,
                              height: 58,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _buildAvatarPlaceholder(),
                            )
                          : _buildAvatarPlaceholder(),
                    ),
                    const SizedBox(width: 14),

                    // Doctor Detail
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctorName,
                            style: GoogleFonts.inter(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            specialty,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isOngoing
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF16A34A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOngoing
                                    ? (doc['status'] ?? 'Sedang Berlangsung')
                                    : status,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isOngoing
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Schedule & Price container (Figma exact match)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        schedule,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Biaya: ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        price,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: _darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 2 Action Buttons: Lihat Profile & Buat Janji
                Row(
                  children: [
                    // Button 1: Lihat Profile (Outlined)
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _darkGreen, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: () async {
                            final booked = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DokterDetailScreen(
                                  doctor: doc,
                                  userName: widget.userName,
                                ),
                              ),
                            );
                            if (booked == true && mounted) {
                              setState(() {
                                _selectedCategory = 'Konsultasi Saya';
                              });
                              _fetchKonsultasiSaya();
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Lihat Profile',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: _darkGreen,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.person_outline_rounded,
                                size: 18,
                                color: _darkGreen,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Button 2: Buat Janji (Filled)
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _darkGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: () async {
                            final booked = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JadwalkanKonsultasiScreen(
                                  doctor: doc,
                                  userName: widget.userName,
                                ),
                              ),
                            );
                            if (booked == true && mounted) {
                              setState(() {
                                _selectedCategory = 'Konsultasi Saya';
                              });
                              _fetchKonsultasiSaya();
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Buat Janji',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.event_available_outlined,
                                size: 18,
                                color: Colors.white,
                              ),
                            ],
                          ),
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
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BOTTOM NAVIGATION BAR (matches app design with Konsultasi active)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBottomNavigationBar(BuildContext context) {
    return PasienBottomNavbar(
      currentIndex: 1,
      userName: widget.userName,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

class _KonsultasiTopographyPainter extends CustomPainter {
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


class _SubtleCardOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.cubicTo(
      size.width * 0.4,
      size.height * 0.1,
      size.width * 0.6,
      size.height * 0.8,
      size.width,
      size.height * 0.5,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
