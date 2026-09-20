// ─────────────────────────────────────────────────────────────────────────────
// MODEL DATA TRANSAKSI & PESANAN OBAT GIAT
// ─────────────────────────────────────────────────────────────────────────────

class OrderCheckoutData {
  final String orderNumber;
  final String prescriptionNumber;
  final String itemCount;
  final int totalAmount;
  final String totalAmountFormatted;
  final String paymentMethod; // 'QRIS' or 'BCA Virtual Account'
  final String virtualAccountNumber;
  final String transactionTime;
  final String pickupMethod; // 'Antar ke Alamat' or 'Ambil di Apotek'
  final String recipientName;
  final String recipientPhone;
  final String recipientAddress;
  final String estimatedArrival;

  const OrderCheckoutData({
    this.orderNumber = 'ORD-20260901-001',
    this.prescriptionNumber = 'RX-2026-0901-08',
    this.itemCount = '2 Jenis Obat',
    this.totalAmount = 790000,
    this.totalAmountFormatted = 'Rp. 790.000,00',
    this.paymentMethod = 'QRIS',
    this.virtualAccountNumber = '8077 0812 3456 7890',
    this.transactionTime = '01 Sept 2026, 14:32 WIB',
    this.pickupMethod = 'Antar ke Alamat',
    this.recipientName = 'Budi Santoso',
    this.recipientPhone = '(+62 812-3456-7890)',
    this.recipientAddress = 'Jl. Kalimantan No. 37, Sumbersari, Jember, Jawa Timur 68121',
    this.estimatedArrival = 'Hari ini, 16:30 - 17:00 WIB',
  });

  OrderCheckoutData copyWith({
    String? orderNumber,
    String? prescriptionNumber,
    String? itemCount,
    int? totalAmount,
    String? totalAmountFormatted,
    String? paymentMethod,
    String? virtualAccountNumber,
    String? transactionTime,
    String? pickupMethod,
    String? recipientName,
    String? recipientPhone,
    String? recipientAddress,
    String? estimatedArrival,
  }) {
    return OrderCheckoutData(
      orderNumber: orderNumber ?? this.orderNumber,
      prescriptionNumber: prescriptionNumber ?? this.prescriptionNumber,
      itemCount: itemCount ?? this.itemCount,
      totalAmount: totalAmount ?? this.totalAmount,
      totalAmountFormatted: totalAmountFormatted ?? this.totalAmountFormatted,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      virtualAccountNumber: virtualAccountNumber ?? this.virtualAccountNumber,
      transactionTime: transactionTime ?? this.transactionTime,
      pickupMethod: pickupMethod ?? this.pickupMethod,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      recipientAddress: recipientAddress ?? this.recipientAddress,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
    );
  }
}
