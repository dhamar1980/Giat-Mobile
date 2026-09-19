import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PENGINGAT & ALARM KESEHATAN GINJAL (REMINDER)
// ─────────────────────────────────────────────────────────────────────────────

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonGreen = Color(0xFF044E2F);

  final List<Map<String, dynamic>> _reminders = [
    {
      'id': '1',
      'type': 'obat',
      'title': 'Minum Obat Pagi',
      'subtitle': 'Candesartan 8mg & Asam Folat',
      'time': '08:00',
      'days': 'Setiap Hari',
      'isActive': true,
      'icon': Icons.medication_rounded,
    },
    {
      'id': '2',
      'type': 'air',
      'title': 'Asupan Air Siang',
      'subtitle': 'Target: 250 ml air putih hangat',
      'time': '12:30',
      'days': 'Setiap Hari',
      'isActive': true,
      'icon': Icons.water_drop_rounded,
    },
    {
      'id': '3',
      'type': 'kontrol',
      'title': 'Kontrol Dokter Ginjal',
      'subtitle': 'Dr. Andi Pratama • RS Medika',
      'time': '10:00',
      'days': 'Kamis, 24 Sept',
      'isActive': true,
      'icon': Icons.calendar_month_rounded,
    },
    {
      'id': '4',
      'type': 'obat',
      'title': 'Minum Obat Malam',
      'subtitle': 'Atorvastatin 10mg sebelum tidur',
      'time': '20:00',
      'days': 'Setiap Hari',
      'isActive': false,
      'icon': Icons.medication_rounded,
    },
  ];

  void _showAddReminderDialog() {
    final titleCtrl = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Tambah Pengingat Baru',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17, color: const Color(0xFF1E293B)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nama Pengingat', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
              const SizedBox(height: 6),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  hintText: 'Contoh: Cek Tensi, Minum Air...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              Text('Waktu Pengingat', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: selectedTime);
                  if (picked != null) {
                    setDialogState(() => selectedTime = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} WIB',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: _darkGreen),
                      ),
                      const Icon(Icons.access_time_rounded, color: _darkGreen),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey[600])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _buttonGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    _reminders.add({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'type': 'custom',
                      'title': titleCtrl.text.trim(),
                      'subtitle': 'Pengingat kustom mandiri',
                      'time': '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                      'days': 'Setiap Hari',
                      'isActive': true,
                      'icon': Icons.alarm_rounded,
                    });
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pengingat berhasil diaktifkan! ⏰')),
                  );
                }
              },
              child: Text('Simpan', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
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
        title: Text(
          'Pengingat Hari Ini',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _reminders.length,
        itemBuilder: (context, i) {
          final rem = _reminders[i];
          final isActive = rem['isActive'] == true;
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    rem['icon'] as IconData,
                    color: isActive ? _darkGreen : const Color(0xFF94A3B8),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            rem['time'],
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isActive ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              rem['days'],
                              style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        rem['title'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isActive ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                        ),
                      ),
                      Text(
                        rem['subtitle'],
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  activeColor: _darkGreen,
                  onChanged: (val) {
                    setState(() => rem['isActive'] = val);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _buttonGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm_rounded),
        label: Text('Tambah Alarm', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        onPressed: _showAddReminderDialog,
      ),
    );
  }
}
