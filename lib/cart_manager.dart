import 'package:flutter/material.dart';
import 'services/marketplace_models.dart';

class CartItem {
  final MarketplaceProduct product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  int get total => product.salePrice * quantity;
}

class CartManager extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  int get subtotal => _items.fold(0, (sum, item) => sum + item.total);

  int get shippingFee => 0; // Free shipping as per UI

  int get totalAmount => subtotal + shippingFee;

  void addToCart(MarketplaceProduct product, {int quantity = 1}) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

// Global instance (can also be provided via Provider in main.dart)
final cartManager = CartManager();
