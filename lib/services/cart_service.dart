import 'package:flutter/material.dart';

class CartItemData {
  final String id;
  final String name;
  final String category;
  final String badgeText;
  final Color badgeColor;
  final String packageInfo;
  final String dosageInstruction;
  final int unitPrice;
  int quantity;
  bool isSelected;
  final String? imagePath;

  CartItemData({
    required this.id,
    required this.name,
    required this.category,
    required this.badgeText,
    required this.badgeColor,
    required this.packageInfo,
    required this.dosageInstruction,
    required this.unitPrice,
    this.quantity = 1,
    this.isSelected = true,
    this.imagePath,
  });

  int get totalPrice => unitPrice * quantity;
}

/// Centralized Cart Service to manage real shopping cart items across catalog, detail, and checkout
class CartService extends ChangeNotifier {
  static final CartService instance = CartService._internal();
  factory CartService() => instance;
  CartService._internal();

  final List<CartItemData> _items = [];

  List<CartItemData> get items => List.unmodifiable(_items);

  int get totalCount => _items.fold(0, (sum, item) => sum + item.quantity);

  int get selectedCount => _items.where((i) => i.isSelected).length;

  int get subtotal => _items
      .where((i) => i.isSelected)
      .fold(0, (sum, i) => sum + i.totalPrice);

  void addItem({
    required String id,
    required String name,
    required String category,
    required String badgeText,
    required Color badgeColor,
    required String packageInfo,
    required String dosageInstruction,
    required int unitPrice,
    int quantity = 1,
    String? imagePath,
  }) {
    final existingIndex = _items.indexWhere((i) => i.id == id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItemData(
        id: id,
        name: name,
        category: category,
        badgeText: badgeText,
        badgeColor: badgeColor,
        packageInfo: packageInfo,
        dosageInstruction: dosageInstruction,
        unitPrice: unitPrice,
        quantity: quantity,
        isSelected: true,
        imagePath: imagePath,
      ));
    }
    notifyListeners();
  }

  void updateQuantity(String id, int quantity) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void toggleSelection(String id, bool isSelected) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      _items[index].isSelected = isSelected;
      notifyListeners();
    }
  }

  void toggleSelectAll(bool isSelected) {
    for (var item in _items) {
      item.isSelected = isSelected;
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  void clearSelected() {
    _items.removeWhere((i) => i.isSelected);
    notifyListeners();
  }
}

