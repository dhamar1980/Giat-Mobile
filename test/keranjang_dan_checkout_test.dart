import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/pasien/obat/pembelian_obat_screen.dart';
import 'package:giat/screens/pasien/obat/keranjang_screen.dart';
import 'package:giat/screens/pasien/obat/checkout_resep_screen.dart';
import 'package:giat/services/cart_service.dart';

void main() {
  setUp(() {
    CartService.instance.clearCart();
    CartService.instance.addItem(
      id: 'ketosteril',
      name: 'Ketosteril Tablet',
      category: 'Asam Amino Esensial',
      badgeText: 'Resep',
      badgeColor: const Color(0xFFDC2626),
      packageInfo: 'Box (100 Kaplet)',
      dosageInstruction: '3 kali sehari 1 kaplet',
      unitPrice: 125000,
      quantity: 1,
    );
    CartService.instance.addItem(
      id: 'candesartan',
      name: 'Candesartan 8mg',
      category: 'Antihipertensi',
      badgeText: 'Resep',
      badgeColor: const Color(0xFFDC2626),
      packageInfo: 'Strip (10 Tablet)',
      dosageInstruction: '1 kali sehari 1 tablet',
      unitPrice: 35000,
      quantity: 1,
    );
  });
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

  testWidgets('CheckoutResepScreen auto-selects nearest Jember Apotek and allows patient to freely switch Apotek', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: CheckoutResepScreen(userName: 'Siti Aisyah'),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Jember pharmacy list and automatic nearest badge
    expect(find.text('Apotek Mitra GIAT'), findsOneWidget);
    expect(find.text('Otomatis Terdekat • Jember'), findsOneWidget);
    expect(find.textContaining('Terdekat •'), findsWidgets);
    expect(find.text('Apotek K-24 Sumbersari Jember'), findsWidgets);
    expect(find.text('Apotek Kimia Farma Jember'), findsWidgets);
    expect(find.text('Apotek Sehat Ginjal Sentosa Jember'), findsWidgets);

    // Patient freely switches to Apotek Kimia Farma Jember
    final kfFinder = find.text('Apotek Kimia Farma Jember').first;
    await tester.ensureVisible(kfFinder);
    await tester.pumpAndSettle();
    await tester.tap(kfFinder);
    await tester.pumpAndSettle();

    expect(find.textContaining('apt. Farhan Ramadhan, S.Farm'), findsOneWidget);
  });
}
