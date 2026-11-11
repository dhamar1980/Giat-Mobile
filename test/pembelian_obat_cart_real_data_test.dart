import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/pasien/obat/keranjang_screen.dart';
import 'package:giat/screens/pasien/obat/pembelian_obat_screen.dart';
import 'package:giat/services/cart_service.dart';

void main() {
  setUp(() {
    CartService.instance.clearCart();
  });

  test('CartService correctly adds, increments, and removes real items', () {
    expect(CartService.instance.totalCount, 0);
    expect(CartService.instance.items.isEmpty, true);

    CartService.instance.addItem(
      id: 'calos-500',
      name: 'Calos 500mg',
      category: 'Pengikat Fosfat',
      badgeText: 'Bebas',
      badgeColor: const Color(0xFF065A37),
      packageInfo: 'Strip (10 Tablet)',
      dosageInstruction: '1 tablet dikunyah saat makan',
      unitPrice: 35000,
      quantity: 2,
    );

    expect(CartService.instance.totalCount, 2);
    expect(CartService.instance.items.length, 1);
    expect(CartService.instance.items.first.name, 'Calos 500mg');
    expect(CartService.instance.subtotal, 70000);

    // Increment
    CartService.instance.updateQuantity('calos-500', 3);
    expect(CartService.instance.totalCount, 3);
    expect(CartService.instance.subtotal, 105000);

    // Add another item
    CartService.instance.addItem(
      id: 'renalvit-tab',
      name: 'Renalvit Tab',
      category: 'Vitamin & Suplemen',
      badgeText: 'Bebas',
      badgeColor: const Color(0xFF065A37),
      packageInfo: 'Botol (30 Tablet)',
      dosageInstruction: '1 tablet sekali sehari setelah makan',
      unitPrice: 85000,
      quantity: 1,
    );

    expect(CartService.instance.totalCount, 4);
    expect(CartService.instance.items.length, 2);
    expect(CartService.instance.subtotal, 190000);

    // Remove one item
    CartService.instance.removeItem('calos-500');
    expect(CartService.instance.items.length, 1);
    expect(CartService.instance.items.first.name, 'Renalvit Tab');
    expect(CartService.instance.totalCount, 1);
  });

  testWidgets('KeranjangScreen displays real cart items and empty state correctly', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // When cart is empty
    CartService.instance.clearCart();
    await tester.pumpWidget(
      const MaterialApp(
        home: KeranjangScreen(userName: 'Siti Aisyah'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Keranjang Anda Kosong'), findsOneWidget);
    expect(find.text('Ketosteril Tablet'), findsNothing);
    expect(find.text('Candesartan 8mg'), findsNothing);

    // When items are added
    CartService.instance.addItem(
      id: 'renalvit',
      name: 'Renalvit Tab',
      category: 'Vitamin & Suplemen',
      badgeText: 'Bebas',
      badgeColor: const Color(0xFF065A37),
      packageInfo: 'Botol (30 Tablet)',
      dosageInstruction: '1 tablet sekali sehari',
      unitPrice: 85000,
      quantity: 1,
    );

    await tester.pumpAndSettle();

    expect(find.text('Keranjang Anda Kosong'), findsNothing);
    expect(find.text('Renalvit Tab'), findsOneWidget);
    expect(find.text('Rp. 85.000,00'), findsWidgets);
    expect(find.text('Ketosteril Tablet'), findsNothing);
  });
}

