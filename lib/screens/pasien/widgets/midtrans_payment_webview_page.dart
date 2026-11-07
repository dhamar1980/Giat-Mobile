import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../constants/api_constants.dart';
import '../../../widgets/giat_background.dart';

/// Hasil kembalian dari [MidtransPaymentWebViewPage]
class MidtransPaymentResult {
  final bool isPaid;
  final String statusPembayaran;
  final String? lastUrl;
  final Map<String, dynamic>? statusData;

  const MidtransPaymentResult({
    required this.isPaid,
    this.statusPembayaran = 'menunggu_pembayaran',
    this.lastUrl,
    this.statusData,
  });
}

/// Definisi opsi metode pembayaran Midtrans Snap yang dipecah dari awal
class MidtransChannelOption {
  final String id;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final Color iconBgColor;
  final Color iconColor;
  final IconData icon;
  final List<String> brandChips;
  final String snapHashRoute;

  const MidtransChannelOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeBgColor,
    required this.badgeTextColor,
    required this.iconBgColor,
    required this.iconColor,
    required this.icon,
    this.brandChips = const [],
    required this.snapHashRoute,
  });

  static const List<MidtransChannelOption> defaultChannels = [
    MidtransChannelOption(
      id: 'gopay',
      title: 'GoPay / GoPay Later',
      subtitle: 'Bayar instan via aplikasi Gojek, GoPay, atau GoPay Later',
      badgeText: 'Direkomendasikan',
      badgeBgColor: Color(0xFFDCFCE7),
      badgeTextColor: Color(0xFF065A37),
      iconBgColor: Color(0xFFE0F2FE),
      iconColor: Color(0xFF0284C7),
      icon: Icons.account_balance_wallet_rounded,
      brandChips: ['GoPay', 'GoPay Later', 'QRIS GoPay'],
      snapHashRoute: '#/gopay-qris',
    ),
    MidtransChannelOption(
      id: 'virtual_account',
      title: 'Virtual Account (Transfer Bank)',
      subtitle: 'Verifikasi otomatis tanpa unggah bukti transfer',
      badgeText: '24 Jam',
      badgeBgColor: Color(0xFFE0F2FE),
      badgeTextColor: Color(0xFF0369A1),
      iconBgColor: Color(0xFFEEF2FF),
      iconColor: Color(0xFF1D4ED8),
      icon: Icons.account_balance_rounded,
      brandChips: ['BCA', 'Mandiri', 'BNI', 'BRI', 'Permata'],
      snapHashRoute: '#/bank-transfer',
    ),
    MidtransChannelOption(
      id: 'credit_card',
      title: 'Card Payment (Kartu Kredit / Debit)',
      subtitle: 'Pembayaran aman dengan 3D Secure semua bank',
      badgeText: 'Instan',
      badgeBgColor: Color(0xFFF1F5F9),
      badgeTextColor: Color(0xFF334155),
      iconBgColor: Color(0xFFFEF3C7),
      iconColor: Color(0xFFB45309),
      icon: Icons.credit_card_rounded,
      brandChips: ['VISA', 'Mastercard', 'JCB', 'Amex'],
      snapHashRoute: '#/credit-card',
    ),
    MidtransChannelOption(
      id: 'shopeepay',
      title: 'ShopeePay / SPayLater',
      subtitle: 'Bayar praktis dengan saldo ShopeePay atau cicilan SPayLater',
      badgeText: 'E-Wallet',
      badgeBgColor: Color(0xFFFFEDD5),
      badgeTextColor: Color(0xFFC2410C),
      iconBgColor: Color(0xFFFFEDD5),
      iconColor: Color(0xFFEA580C),
      icon: Icons.shopping_bag_rounded,
      brandChips: ['ShopeePay', 'SPayLater'],
      snapHashRoute: '#/shopeepay-qris',
    ),
    MidtransChannelOption(
      id: 'qris',
      title: 'QRIS (Semua E-Wallet & m-Banking)',
      subtitle: 'Scan QR dari BCA Mobile, Livin\', BRImo, DANA, OVO, LinkAja',
      badgeText: 'Semua Bank',
      badgeBgColor: Color(0xFFECFDF5),
      badgeTextColor: Color(0xFF047857),
      iconBgColor: Color(0xFF044E2F),
      iconColor: Colors.white,
      icon: Icons.qr_code_2_rounded,
      brandChips: ['QRIS Nasional', 'DANA', 'OVO', 'm-Banking'],
      snapHashRoute: '#/other-qris',
    ),
  ];

  static const List<Map<String, dynamic>> vaBanks = [
    {
      'id': 'bca_va',
      'name': 'BCA',
      'fullName': 'BCA Virtual Account',
      'color': Color(0xFF005BAA),
      'hash': '#/bank-transfer/bca-va',
      'keyword': 'BCA',
    },
    {
      'id': 'echannel',
      'name': 'Mandiri',
      'fullName': 'Mandiri Bill Payment',
      'color': Color(0xFF003D79),
      'hash': '#/bank-transfer/mandiri-bill',
      'keyword': 'Mandiri',
    },
    {
      'id': 'bni_va',
      'name': 'BNI',
      'fullName': 'BNI Virtual Account',
      'color': Color(0xFFF15A23),
      'hash': '#/bank-transfer/bni-va',
      'keyword': 'BNI',
    },
    {
      'id': 'bri_va',
      'name': 'BRI',
      'fullName': 'BRI Virtual Account',
      'color': Color(0xFF00529C),
      'hash': '#/bank-transfer/bri-va',
      'keyword': 'BRI',
    },
    {
      'id': 'permata_va',
      'name': 'Permata',
      'fullName': 'Permata Virtual Account',
      'color': Color(0xFF00A651),
      'hash': '#/bank-transfer/permata-va',
      'keyword': 'Permata',
    },
    {
      'id': 'other_va',
      'name': 'Bank Lain',
      'fullName': 'ATM Bersama / Jaringan Prima',
      'color': Color(0xFF475569),
      'hash': '#/bank-transfer/other-va',
      'keyword': 'Other',
    },
  ];

  /// Menghasilkan label metode pembayaran yang rapi untuk UI
  static String getReadableMethodLabel(String methodId, {String? vaBankId}) {
    if (methodId == 'virtual_account') {
      final bank = vaBanks.firstWhere(
        (b) => b['id'] == vaBankId,
        orElse: () => vaBanks.first,
      );
      return bank['fullName'] as String;
    }
    for (final c in defaultChannels) {
      if (c.id == methodId) return c.title;
    }
    return 'Midtrans Snap';
  }

  /// Menghasilkan kode enabled_payments Midtrans sesuai pilihan pasien
  static String getEffectiveMidtransCode(String methodId, {String? vaBankId}) {
    if (methodId == 'virtual_account') {
      return vaBankId ?? 'bca_va';
    }
    if (methodId == 'qris') {
      return 'other_qris';
    }
    return methodId;
  }
}

/// Widget Reusable Pemilih Metode Pembayaran Midtrans GIAT (Konsultasi & Obat)
class MidtransPaymentMethodSelector extends StatelessWidget {
  final String selectedMethodId;
  final String selectedVaBankId;
  final ValueChanged<String> onMethodChanged;
  final ValueChanged<String> onVaBankChanged;

  const MidtransPaymentMethodSelector({
    super.key,
    required this.selectedMethodId,
    required this.selectedVaBankId,
    required this.onMethodChanged,
    required this.onVaBankChanged,
  });

  static const Color _darkGreen = Color(0xFF044E2F);
  static const Color _cardBorderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: MidtransChannelOption.defaultChannels.map((channel) {
        final isSelected = selectedMethodId == channel.id;
        final isVaChannel = channel.id == 'virtual_account';

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => onMethodChanged(channel.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF3FAF6) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? _darkGreen : _cardBorderColor,
                  width: isSelected ? 1.6 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isSelected ? 0.05 : 0.025),
                    blurRadius: isSelected ? 10 : 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _buildRadioIndicator(isSelected),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: channel.iconBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          channel.icon,
                          color: channel.iconColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    channel.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.8,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: channel.badgeBgColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    channel.badgeText,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: channel.badgeTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              channel.subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: const Color(0xFF64748B),
                                height: 1.35,
                              ),
                            ),
                            if (channel.brandChips.isNotEmpty &&
                                !(isVaChannel && isSelected)) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: channel.brandChips.map((chip) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Text(
                                      chip,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF334155),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Sub-pilihan Bank Virtual Account ketika Virtual Account dipilih
                  if (isVaChannel && isSelected) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFD1FAE5)),
                    const SizedBox(height: 10),
                    Text(
                      'Pilih Bank Tujuan Virtual Account:',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _darkGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: MidtransChannelOption.vaBanks.map((bank) {
                        final bankId = bank['id'] as String;
                        final bankName = bank['name'] as String;
                        final bankColor = bank['color'] as Color;
                        final isBankSelected = selectedVaBankId == bankId;

                        return GestureDetector(
                          onTap: () => onVaBankChanged(bankId),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isBankSelected
                                  ? _darkGreen
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isBankSelected
                                    ? _darkGreen
                                    : const Color(0xFFCBD5E1),
                                width: isBankSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isBankSelected
                                        ? Colors.white
                                        : bankColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  bankName,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isBankSelected
                                        ? Colors.white
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRadioIndicator(bool isSelected) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: isSelected ? _darkGreen : const Color(0xFF94A3B8),
          width: isSelected ? 6 : 1.5,
        ),
      ),
    );
  }
}

/// Halaman reusable WebView untuk pembayaran Midtrans Snap dengan desain konsisten GIAT
class MidtransPaymentWebViewPage extends StatefulWidget {
  final String? redirectUrl;
  final String? snapToken;
  final String title;
  final String? subtitle;
  final String? orderId;
  final String? amountFormatted;

  /// Metode pembayaran yang dipilih pasien dari awal (misal: 'gopay', 'virtual_account', 'credit_card', 'shopeepay', 'qris')
  final String? preferredMethodId;

  /// Bank VA spesifik jika memilih 'virtual_account' (misal: 'bca_va', 'echannel', 'bni_va', 'bri_va', 'permata_va')
  final String? preferredVaBankId;

  /// Callback opsional untuk mengecek status pembayaran langsung ke Backend
  final Future<Map<String, dynamic>?> Function()? onCheckStatus;

  /// Callback opsional untuk me-refresh Snap Token baru (`force_new: true`).
  final Future<String?> Function()? onRefreshSnapUrl;

  const MidtransPaymentWebViewPage({
    super.key,
    this.redirectUrl,
    this.snapToken,
    this.title = 'Pembayaran Midtrans',
    this.subtitle,
    this.orderId,
    this.amountFormatted,
    this.preferredMethodId,
    this.preferredVaBankId,
    this.onCheckStatus,
    this.onRefreshSnapUrl,
  });

  @override
  State<MidtransPaymentWebViewPage> createState() =>
      _MidtransPaymentWebViewPageState();

  /// Memeriksa apakah nilai status_pembayaran dari backend sudah lunas
  static bool isStatusLunas(Map<String, dynamic>? data) {
    if (data == null) return false;
    final statusBayar = (data['status_pembayaran'] ??
            data['status_bayar'] ??
            data['transaction_status'] ??
            '')
        .toString()
        .toLowerCase()
        .trim();
    return statusBayar == 'lunas' ||
        statusBayar == 'settlement' ||
        statusBayar == 'capture' ||
        statusBayar == 'paid' ||
        statusBayar == 'berhasil' ||
        statusBayar == 'success';
  }
}

class _MidtransPaymentWebViewPageState
    extends State<MidtransPaymentWebViewPage> {
  static const Color _darkGreen = Color(0xFF044E2F);
  static const Color _primaryGreen = Color(0xFF065A37);
  static const Color _bgColor = Color(0xFFF7FAF8);
  static const Color _cardBorderColor = Color(0xFFE2E8F0);

  late final WebViewController _controller;
  late String _activeUrl;
  int _loadingProgress = 0;
  bool _isPageLoading = true;
  bool _isCheckingStatus = false;
  bool _hasPopped = false;
  bool _hasAutoSelectedChannel = false;
  String? _errorMessage;
  String _lastDetectedUrl = '';

  @override
  void initState() {
    super.initState();
    final baseResolved = ApiConstants.resolveMidtransRedirectUrl(
          redirectUrl: widget.redirectUrl,
          snapToken: widget.snapToken,
        ) ??
        '';
    _activeUrl = _appendChannelHashIfNeeded(baseResolved);
    _lastDetectedUrl = _activeUrl;
    _initWebView();
  }

  /// Menambahkan fragment hash Midtrans Snap v4 sesuai metode pembayaran yang dipilih pasien
  String _appendChannelHashIfNeeded(String baseUrl) {
    if (baseUrl.isEmpty || baseUrl.contains('#/')) return baseUrl;
    final method = widget.preferredMethodId;
    if (method == null || method.isEmpty) return baseUrl;

    if (method == 'virtual_account') {
      final bank = MidtransChannelOption.vaBanks.firstWhere(
        (b) => b['id'] == widget.preferredVaBankId,
        orElse: () => MidtransChannelOption.vaBanks.first,
      );
      return '$baseUrl${bank['hash']}';
    }

    for (final c in MidtransChannelOption.defaultChannels) {
      if (c.id == method) {
        return '$baseUrl${c.snapHashRoute}';
      }
    }
    return baseUrl;
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (!mounted) return;
            setState(() {
              _loadingProgress = progress;
              if (progress >= 100) {
                _isPageLoading = false;
              }
            });
          },
          onPageStarted: (String url) {
            if (!mounted) return;
            setState(() {
              _isPageLoading = true;
              _errorMessage = null;
              _lastDetectedUrl = url;
            });
            _inspectUrlForCompletion(url);
          },
          onPageFinished: (String url) {
            if (!mounted) return;
            setState(() {
              _isPageLoading = false;
              _lastDetectedUrl = url;
            });
            _inspectUrlForCompletion(url);
            _injectCleanMidtransDomUi();
            _tryAutoSelectPaymentMethodInDom();
          },
          onUrlChange: (UrlChange change) {
            final url = change.url;
            if (url != null && url.isNotEmpty) {
              _lastDetectedUrl = url;
              _inspectUrlForCompletion(url);
              _injectCleanMidtransDomUi();
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (error.isForMainFrame == false) return;
            if (!mounted) return;
            setState(() {
              _isPageLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            _lastDetectedUrl = url;

            if (_isMidtransSuccessUrl(url)) {
              _inspectUrlForCompletion(url);
              return NavigationDecision.navigate;
            }

            final uri = Uri.tryParse(url);
            if (uri != null &&
                uri.scheme.isNotEmpty &&
                uri.scheme != 'http' &&
                uri.scheme != 'https' &&
                uri.scheme != 'about' &&
                uri.scheme != 'data' &&
                uri.scheme != 'javascript') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Silakan selesaikan pembayaran di halaman ini, lalu tekan tombol "Saya Sudah Bayar • Cek Status".',
                    style: GoogleFonts.inter(fontSize: 12.5),
                  ),
                  backgroundColor: _primaryGreen,
                ),
              );
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    if (_activeUrl.isNotEmpty) {
      _controller.loadRequest(Uri.parse(_activeUrl));
    } else {
      _isPageLoading = false;
      _errorMessage = 'URL Pembayaran Midtrans Snap tidak ditemukan.';
    }
  }

  /// Menyembunyikan elemen Order ID (#KONS-... / #ORD-...) serta tombol duplikat
  /// "Check status" bawaan di dalam DOM Midtrans Snap agar tampilan bersih dan
  /// tidak bertabrakan dengan tombol Cek Status Pembayaran GIAT di bagian bawah.
  Future<void> _injectCleanMidtransDomUi() async {
    const cleanDomJs = '''
      (function() {
        try {
          if (!document.getElementById('giat-midtrans-clean-style')) {
            var style = document.createElement('style');
            style.id = 'giat-midtrans-clean-style';
            style.innerHTML = '.order-id-optional, .merchant-OrderId, [class*="order-id"] { display: none !important; }';
            document.head.appendChild(style);
          }

          function cleanSnapElements() {
            // 1. Sembunyikan teks "Order ID #KONS-..." / "Order ID #ORD-..."
            var textNodes = document.querySelectorAll('div, span, p');
            for (var i = 0; i < textNodes.length; i++) {
              var el = textNodes[i];
              if (el.children.length <= 2) {
                var txt = (el.innerText || el.textContent || '').trim();
                var lower = txt.toLowerCase();
                if (txt.length > 0 && txt.length < 55 && (
                    lower.indexOf('order id #') === 0 ||
                    lower.indexOf('order id') === 0 ||
                    lower.indexOf('id pesanan') === 0 ||
                    /^#(kons|ord)-/i.test(txt)
                )) {
                  el.style.setProperty('display', 'none', 'important');
                }
              }
            }

            // 2. Sembunyikan tombol "Check status" / "Cek status" bawaan Midtrans
            //    agar tidak double dengan tombol hijau GIAT di bagian bawah.
            var buttons = document.querySelectorAll('button, a[role="button"], .btn, div.card-pay-button-part button');
            for (var j = 0; j < buttons.length; j++) {
              var btn = buttons[j];
              var bTxt = (btn.innerText || btn.textContent || '').trim().toLowerCase();
              if (bTxt === 'check status' ||
                  bTxt === 'cek status' ||
                  bTxt === 'back to merchant' ||
                  bTxt === 'kembali ke merchant') {
                btn.style.setProperty('display', 'none', 'important');
                var parentPart = btn.closest('.card-pay-button-part, .pay-button-main');
                if (parentPart) {
                  parentPart.style.setProperty('display', 'none', 'important');
                }
              }
            }
          }

          cleanSnapElements();
          setTimeout(cleanSnapElements, 300);
          setTimeout(cleanSnapElements, 800);
          setTimeout(cleanSnapElements, 1600);

          if (!window.__giatSnapObserverAttached) {
            window.__giatSnapObserverAttached = true;
            var observer = new MutationObserver(function() {
              cleanSnapElements();
            });
            observer.observe(document.body || document.documentElement, {
              childList: true,
              subtree: true
            });
          }
        } catch (e) {}
      })();
    ''';

    try {
      await _controller.runJavaScript(cleanDomJs);
    } catch (_) {}
  }

  /// Otomatis memilih/membuka metode pembayaran pada halaman Midtrans Snap v4
  /// agar pasien tidak perlu memilih metode pembayaran dua kali.
  Future<void> _tryAutoSelectPaymentMethodInDom() async {
    if (_hasAutoSelectedChannel) return;
    final method = widget.preferredMethodId;
    if (method == null || method.isEmpty) return;
    _hasAutoSelectedChannel = true;

    String primaryText = '';
    String secondaryBankText = '';

    if (method == 'gopay') {
      primaryText = 'GoPay';
    } else if (method == 'virtual_account') {
      primaryText = 'Virtual account';
      final bank = MidtransChannelOption.vaBanks.firstWhere(
        (b) => b['id'] == widget.preferredVaBankId,
        orElse: () => MidtransChannelOption.vaBanks.first,
      );
      secondaryBankText = (bank['keyword'] ?? 'BCA').toString();
    } else if (method == 'credit_card') {
      primaryText = 'Card Payment';
    } else if (method == 'shopeepay') {
      primaryText = 'ShopeePay';
    } else if (method == 'qris') {
      primaryText = 'QRIS';
    }

    if (primaryText.isEmpty) return;

    final jsScript = '''
      (function() {
        try {
          function clickByText(keyword) {
            var els = document.querySelectorAll('a, button, div[role="button"], li, span, div.list-title, div.payment-list-item');
            for (var i = 0; i < els.length; i++) {
              var txt = (els[i].innerText || els[i].textContent || '').trim();
              if (txt && txt.toLowerCase().indexOf(keyword.toLowerCase()) !== -1 && txt.length < 60) {
                var target = els[i].closest('a, button, div[role="button"], li') || els[i];
                target.click();
                return true;
              }
            }
            return false;
          }
          setTimeout(function() {
            clickByText('$primaryText');
            if ('$secondaryBankText' !== '') {
              setTimeout(function() {
                clickByText('$secondaryBankText');
                var imgs = document.querySelectorAll('img[alt*="$secondaryBankText" i], a[href*="${secondaryBankText.toLowerCase()}" i]');
                if (imgs.length > 0) {
                  var bankTarget = imgs[0].closest('a, button, div[role="button"], li') || imgs[0];
                  bankTarget.click();
                }
              }, 450);
            }
          }, 500);
        } catch (e) {}
      })();
    ''';

    try {
      await _controller.runJavaScript(jsScript);
    } catch (_) {}
  }

  bool _isMidtransSuccessUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('status_code=200') ||
        lower.contains('transaction_status=settlement') ||
        lower.contains('transaction_status=capture') ||
        lower.contains('transaction_status=success') ||
        (lower.contains('/finish') &&
            !lower.contains('/unfinish') &&
            !lower.contains('/error'));
  }

  Future<void> _inspectUrlForCompletion(String url) async {
    if (_hasPopped || _isCheckingStatus) return;
    if (_isMidtransSuccessUrl(url)) {
      await _verifyPaymentStatus(autoTriggered: true, detectedUrl: url);
    }
  }

  Future<void> _verifyPaymentStatus({
    bool autoTriggered = false,
    String? detectedUrl,
  }) async {
    if (_isCheckingStatus || _hasPopped) return;

    if (widget.onCheckStatus == null) {
      if (autoTriggered ||
          _isMidtransSuccessUrl(detectedUrl ?? _lastDetectedUrl)) {
        _safePop(
          MidtransPaymentResult(
            isPaid: true,
            statusPembayaran: 'lunas',
            lastUrl: detectedUrl ?? _lastDetectedUrl,
          ),
        );
      } else {
        _safePop(
          MidtransPaymentResult(
            isPaid: false,
            statusPembayaran: 'menunggu_pembayaran',
            lastUrl: _lastDetectedUrl,
          ),
        );
      }
      return;
    }

    setState(() => _isCheckingStatus = true);
    try {
      final data = await widget.onCheckStatus!();
      if (!mounted) return;

      final paid = MidtransPaymentWebViewPage.isStatusLunas(data);
      final statusStr = (data?['status_pembayaran'] ??
              data?['status_bayar'] ??
              (paid ? 'lunas' : 'menunggu_pembayaran'))
          .toString();

      if (paid) {
        _safePop(
          MidtransPaymentResult(
            isPaid: true,
            statusPembayaran: statusStr,
            lastUrl: detectedUrl ?? _lastDetectedUrl,
            statusData: data,
          ),
        );
        return;
      }

      if (autoTriggered) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted || _hasPopped) return;
        final retryData = await widget.onCheckStatus!();
        if (!mounted) return;
        if (MidtransPaymentWebViewPage.isStatusLunas(retryData)) {
          _safePop(
            MidtransPaymentResult(
              isPaid: true,
              statusPembayaran: 'lunas',
              lastUrl: detectedUrl ?? _lastDetectedUrl,
              statusData: retryData,
            ),
          );
          return;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status saat ini: ${statusStr.replaceAll('_', ' ').toUpperCase()}. Silakan selesaikan pembayaran di Midtrans terlebih dahulu.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFFD97706),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengecek status pembayaran: $e',
            style: GoogleFonts.inter(fontSize: 12.5),
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  Future<void> _handleRefreshToken() async {
    _hasAutoSelectedChannel = false;
    if (widget.onRefreshSnapUrl == null) {
      if (_activeUrl.isNotEmpty) {
        setState(() {
          _isPageLoading = true;
          _errorMessage = null;
        });
        await _controller.reload();
      }
      return;
    }

    setState(() {
      _isPageLoading = true;
      _errorMessage = null;
    });
    try {
      final newUrl = await widget.onRefreshSnapUrl!();
      if (!mounted) return;
      if (newUrl != null && newUrl.trim().isNotEmpty) {
        _activeUrl = _appendChannelHashIfNeeded(newUrl.trim());
        await _controller.loadRequest(Uri.parse(_activeUrl));
      } else {
        await _controller.reload();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPageLoading = false;
        _errorMessage = 'Gagal memuat ulang token Midtrans: $e';
      });
    }
  }

  void _safePop(MidtransPaymentResult result) {
    if (_hasPopped || !mounted) return;
    _hasPopped = true;
    Navigator.of(context).pop(result);
  }

  Future<void> _handleBackPressed() async {
    if (_hasPopped) return;
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    if (widget.onCheckStatus != null && !_isCheckingStatus) {
      setState(() => _isCheckingStatus = true);
      try {
        final data = await widget.onCheckStatus!();
        if (!mounted) return;
        final paid = MidtransPaymentWebViewPage.isStatusLunas(data);
        _safePop(
          MidtransPaymentResult(
            isPaid: paid,
            statusPembayaran: (data?['status_pembayaran'] ??
                    (paid ? 'lunas' : 'menunggu_pembayaran'))
                .toString(),
            lastUrl: _lastDetectedUrl,
            statusData: data,
          ),
        );
        return;
      } catch (_) {
      } finally {
        if (mounted) setState(() => _isCheckingStatus = false);
      }
    }

    _safePop(
      MidtransPaymentResult(
        isPaid: _isMidtransSuccessUrl(_lastDetectedUrl),
        statusPembayaran: _isMidtransSuccessUrl(_lastDetectedUrl)
            ? 'lunas'
            : 'menunggu_pembayaran',
        lastUrl: _lastDetectedUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chosenChannelLabel = widget.preferredMethodId != null
        ? MidtransChannelOption.getReadableMethodLabel(
            widget.preferredMethodId!,
            vaBankId: widget.preferredVaBankId,
          )
        : 'Midtrans Snap';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBackPressed();
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Stack(
          children: [
            // Background Topography GIAT yang konsisten
            Positioned.fill(
              child: CustomPaint(
                painter: _MidtransWebViewTopographyPainter(),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // ── 1. Top Navigation Bar bergaya GIAT (<- Kembali, Title Pill, Refresh) ──
                  _buildGiatTopBar(),

                  // ── 2. Ringkasan Transaksi & Metode Terpilih Card ──
                  _buildCompactOrderBanner(chosenChannelLabel),

                  // ── 3. WebView Container dengan Sudut Melengkung ──
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        border: Border.all(color: _cardBorderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Column(
                          children: [
                            if (_isPageLoading)
                              LinearProgressIndicator(
                                value: _loadingProgress > 0 &&
                                        _loadingProgress < 100
                                    ? _loadingProgress / 100.0
                                    : null,
                                backgroundColor: const Color(0xFFE2E8F0),
                                color: _primaryGreen,
                                minHeight: 3,
                              ),
                            Expanded(
                              child: _errorMessage != null
                                  ? _buildErrorView()
                                  : Stack(
                                      children: [
                                        WebViewWidget(controller: _controller),
                                        if (_isCheckingStatus)
                                          _buildCheckingOverlay(),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── 4. Sticky Bottom Action Bar Konsisten GIAT ──
                  _buildStickyBottomBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiatTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tombol <- Kembali bergaya GIAT
              GestureDetector(
                onTap: _handleBackPressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF0F172A),
                      width: 1.2,
                    ),
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
                      const Icon(
                        Icons.arrow_back_rounded,
                        size: 16,
                        color: Color(0xFF0F172A),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kembali',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tombol Muat Ulang di kanan atas
              GestureDetector(
                onTap: _isCheckingStatus ? null : _handleRefreshToken,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _cardBorderColor, width: 1.2),
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
                      const Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: _primaryGreen,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Muat Ulang',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Title Pill Hijau GIAT di baris tersendiri (Center) agar konsisten
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: _darkGreen,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _darkGreen.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactOrderBanner(String chosenChannelLabel) {
    final rawSubtitle = widget.subtitle ?? 'Pembayaran Resmi GIAT via Midtrans';
    final cleanSubtitle = rawSubtitle
        .replaceAll(RegExp(r'\s*\((?:KONS|ORD)-[^)]+\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(?:KONS|ORD)-[A-Z0-9-]+\b', caseSensitive: false), '')
        .trim();

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: _primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chosenChannelLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cleanSubtitle.isNotEmpty
                      ? cleanSubtitle
                      : 'Pembayaran Resmi GIAT',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (widget.amountFormatted != null &&
              widget.amountFormatted!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total Bayar',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  widget.amountFormatted!,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: _darkGreen,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.25),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: _primaryGreen),
              const SizedBox(height: 14),
              Text(
                'Memverifikasi Pembayaran...',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sinkronisasi otomatis dengan server Midtrans GIAT',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickyBottomBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: _isCheckingStatus
              ? null
              : () => _verifyPaymentStatus(autoTriggered: false),
          style: ElevatedButton.styleFrom(
            backgroundColor: _darkGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _darkGreen.withValues(alpha: 0.75),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: _isCheckingStatus
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_outline_rounded, size: 20),
          label: Text(
            _isCheckingStatus
                ? 'Memeriksa Status Pembayaran...'
                : 'Saya Sudah Bayar • Cek Status Pembayaran',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Gagal memuat halaman pembayaran Midtrans.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _handleRefreshToken,
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Muat Ulang',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MidtransWebViewTopographyPainter extends CustomPainter {
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
