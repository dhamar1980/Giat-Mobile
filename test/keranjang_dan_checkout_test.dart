import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/pasien/obat/pembelian_obat_screen.dart';
import 'package:giat/screens/pasien/obat/keranjang_screen.dart';
import 'package:giat/screens/pasien/obat/checkout_resep_screen.dart';

void main() {
  testWidgets('PembelianObatScreen cart actions navigate to KeranjangScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PembelianObatScreen(userName: 'Pasien Test'),
      ),
    );

    await tester.pump();

    // Verify cart icon and profile icon are rendered in Action Pill
    expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(find.text('Lihat Keranjang'), findsOneWidget);

    // Tap top bar shopping cart icon
    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    await tester.pumpAndSettle();

    // Verify KeranjangScreen is displayed
    expect(find.byType(KeranjangScreen), findsOneWidget);
    expect(find.text('Keranjang Belanja'), findsOneWidget);
  });

  testWidgets('KeranjangScreen displays items and navigates to CheckoutResepScreen upon clicking Lanjutkan ke Checkout', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: KeranjangScreen(userName: 'Pasien Test'),
      ),
    );

    await tester.pump();

    // Verify screen title and top action pill
    expect(find.text('Keranjang Belanja'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);

    // Verify default cart items
    expect(find.text('Ketosteril Tablet'), findsOneWidget);
    expect(find.text('Candesartan 8mg'), findsOneWidget);
    expect(find.text('Ringkasan Belanja'), findsOneWidget);
    expect(find.text('Lanjutkan ke Checkout'), findsOneWidget);

    // Tap Lanjutkan ke Checkout button
    await tester.tap(find.text('Lanjutkan ke Checkout'));
    await tester.pumpAndSettle();

    // Verify CheckoutResepScreen is opened
    expect(find.byType(CheckoutResepScreen), findsOneWidget);
    expect(find.text('Checkout'), findsOneWidget);
  });

  testWidgets('KeranjangScreen allows quantity stepper and item selection', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: KeranjangScreen(userName: 'Pasien Test'),
      ),
    );

    await tester.pump();

    // Increment quantity on first item
    final addButtons = find.byIcon(Icons.add);
    expect(addButtons, findsWidgets);
    await tester.tap(addButtons.first);
    await tester.pump();

    // Quantity should now show 2 for that item
    expect(find.text('2'), findsOneWidget);
  });
}
