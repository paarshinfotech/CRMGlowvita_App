import 'package:flutter/material.dart';
import 'services/marketplace_models.dart';
import 'services/api_service.dart';

class CartItem {
  final MarketplaceProduct product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  int get total => product.salePrice * quantity;
}

class CartManager extends ChangeNotifier {
  List<CartItem> _items = [];
  bool _isLoading = false;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  int get subtotal => _items.fold(0, (sum, item) => sum + item.total);
  int get shippingFee => 0;
  int get totalAmount => subtotal + shippingFee;

  CartManager() {
    _fetchCartFromApi();
  }

  Future<void> _fetchCartFromApi() async {
    _isLoading = true;
    notifyListeners();

    try {
      final cart = await ApiService.getCart();
      if (cart != null) {
        // We need MarketplaceProduct objects for our UI.
        // For now, we'll fetch all products first to map them.
        final allMarketplaceProducts = await ApiService.getSupplierProducts();
        
        _items = cart.items.map((apiItem) {
          final product = allMarketplaceProducts.firstWhere(
            (p) => p.id == apiItem.productId,
            orElse: () => MarketplaceProduct(
              id: apiItem.productId,
              productName: apiItem.productName,
              salePrice: apiItem.price.toInt(),
              vendorId: apiItem.vendorId ?? '',
              supplierName: apiItem.supplierName ?? '',
              // Placeholder values for other fields
              description: '',
              category: '',
              categoryDescription: '',
              price: apiItem.price.toInt(),
              stock: 0,
              productImages: [],
              size: '',
              sizeMetric: '',
              keyIngredients: [],
              forBodyPart: '',
              bodyPartType: '',
              productForm: '',
              brand: '',
              isActive: true,
              status: 'Active',
              origin: '',
              supplierEmail: '',
              supplierCity: '',
              supplierState: '',
              supplierCountry: '',
            ),
          );
          return CartItem(product: product, quantity: apiItem.quantity);
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(MarketplaceProduct product, {int quantity = 1}) async {
    try {
      final itemData = {
        "productId": product.id,
        "productName": product.productName,
        "quantity": quantity,
        "price": product.salePrice,
        "vendorId": product.vendorId,
        "supplierName": product.supplierName,
        "minOrderValue": 1000 // Standard for this app
      };

      await ApiService.addToCart(itemData);
      
      final index = _items.indexWhere((item) => item.product.id == product.id);
      if (index >= 0) {
        _items[index].quantity += quantity;
      } else {
        _items.add(CartItem(product: product, quantity: quantity));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(String productId) async {
    // There's no specific remove API in the request, but we can update quantity to 0 if the backend supports it,
    // or just handle it locally if the backend expects us to manage the full list (though the API seems to be item-based).
    // Given the endpoint is 'api/crm/cart', and it takes one item, let's assume setting quantity 0 removes it.
    
    final item = _items.firstWhere((i) => i.product.id == productId);
    try {
      await ApiService.addToCart({
        "productId": productId,
        "productName": item.product.productName,
        "quantity": 0,
        "price": item.product.salePrice,
        "vendorId": item.product.vendorId,
        "supplierName": item.product.supplierName,
      });
      _items.removeWhere((item) => item.product.id == productId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing from cart: $e');
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final item = _items[index];
      try {
        await ApiService.addToCart({
          "productId": productId,
          "productName": item.product.productName,
          "quantity": quantity,
          "price": item.product.salePrice,
          "vendorId": item.product.vendorId,
          "supplierName": item.product.supplierName,
        });
        _items[index].quantity = quantity;
        notifyListeners();
      } catch (e) {
        debugPrint('Error updating quantity: $e');
      }
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
    // In a real app, you might want a clear cart API too.
  }

  Future<void> refreshCart() async {
    await _fetchCartFromApi();
  }
}

final cartManager = CartManager();
