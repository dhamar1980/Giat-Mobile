import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// INFORMASI PROFILE DOKTER (Figma Node: 1008-19748)
// ─────────────────────────────────────────────────────────────────────────────

class DokterInformasiProfileScreen extends StatefulWidget {
  final String doctorName;
  final String specialty;

  const DokterInformasiProfileScreen({
    super.key,
    this.doctorName = 'Dr. Andi Pratama',
    this.specialty = 'Spesialis Penyakit Dalam / Ginjal',
  });

  @override
  State<DokterInformasiProfileScreen> createState() => _DokterInformasiProfileScreenState();
}

class _DokterInformasiProfileScreenState extends State<DokterInformasiProfileScreen> {
  static const _bgColor = Color(0xFFF8FAF9);
  static const _border = Color(0xFFE2E8F0);
  static const _darkGreen = Color(0xFF065A37);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Profil Dokter',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur edit profil dokter siap digunakan.')),
              );
            },
            child: Text(
              'Edit',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _darkGreen,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar & Name Card ──
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF044E2F),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF044E2F).withOpacity(0.2),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.person_rounded, size: 44, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.doctorName,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.specialty,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Section 1: Informasi Pribadi ──
              _buildSectionTitle('Informasi Pribadi'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardBoxDecoration(),
                child: Column(
                  children: [
                    _buildInfoRow('Nama Lengkap', widget.doctorName),
                    const Divider(height: 20),
                    _buildInfoRow('Jenis Kelamin', 'Laki - laki'),
                    const Divider(height: 20),
                    _buildInfoRow('Email', 'andi.pratama@giat.id'),
                    const Divider(height: 20),
                    _buildInfoRow('Nomor Telepon', '+62 812-3456-7890'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Section 2: Informasi Profesional ──
              _buildSectionTitle('Informasi Profesional'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardBoxDecoration(),
                child: Column(
                  children: [
                    _buildInfoRow('Spesialisasi', 'Penyakit Dalam / Ginjal'),
                    const Divider(height: 20),
                    _buildInfoRow('No. STR', '1234567890123456'),
                    const Divider(height: 20),
                    _buildInfoRow('No. SIP', 'SIP/123/456/2023'),
                    const Divider(height: 20),
                    _buildInfoRow('Institusi', 'RS Medika Utama'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Section 3: Praktik ──
              _buildSectionTitle('Praktik'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardBoxDecoration(),
                child: Column(
                  children: [
                    _buildInfoRow('Alamat Praktik', 'Jl. Sehat No. 12, Jember'),
                    const Divider(height: 20),
                    _buildInfoRow('Jadwal Praktik', 'Senin - Jumat, 09:00 - 17:00'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
