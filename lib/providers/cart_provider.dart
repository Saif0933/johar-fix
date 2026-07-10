import 'package:flutter/material.dart';
import '../models/service_model.dart';

class CartProvider extends ChangeNotifier {
  final List<ServiceModel> _cart = [];

  List<ServiceModel> get cart => List.unmodifiable(_cart);

  // Get total count of items in cart
  int get itemCount => _cart.fold(0, (sum, item) => sum + item.qty);

  // Get subtotal price of items in cart
  double get cartTotal => _cart.fold(0.0, (sum, item) => sum + (item.basePrice * item.qty));

  // Convenience Fee (e.g. standard service charge, flat or percentage)
  double get serviceFee => itemCount > 0 ? 49.0 : 0.0;

  // Taxes (e.g., GST: 18%)
  double get gstAmount => (cartTotal + serviceFee) * 0.18;

  // Final Checkout Total (Subtotal + Fee + Tax)
  double get grandTotal => cartTotal + serviceFee + gstAmount;

  // Add a service item to the cart
  void addToCart(ServiceModel service) {
    final existsIdx = _cart.indexWhere((item) => item.id == service.id);
    if (existsIdx != -1) {
      // If already in cart, just increment quantity
      _cart[existsIdx].qty += 1;
    } else {
      // Create copy with qty = 1 and add
      _cart.add(service.copyWith(qty: 1));
    }
    notifyListeners();
  }

  // Remove a service item from the cart completely
  void removeFromCart(String id) {
    _cart.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  // Update item quantity
  void updateQty(String id, String action) {
    final existsIdx = _cart.indexWhere((item) => item.id == id);
    if (existsIdx != -1) {
      if (action == 'inc') {
        _cart[existsIdx].qty += 1;
      } else if (action == 'dec') {
        _cart[existsIdx].qty -= 1;
        if (_cart[existsIdx].qty <= 0) {
          _cart.removeAt(existsIdx);
        }
      }
      notifyListeners();
    }
  }

  // Clear all items in the cart
  void clearCart() {
    _cart.clear();
    notifyListeners();
  }
}
