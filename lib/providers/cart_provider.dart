import 'package:flutter/foundation.dart';

import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../utils/currency_helper.dart';

enum CartAddResult { added, reachedStockLimit, outOfStock, otherSeller }

/// Panier du client (en mémoire). Le panier ne contient que les produits d'UN
/// seul vendeur : la commande finale est ainsi envoyée à un seul vendeur.
class CartProvider with ChangeNotifier {
  final List<CartItemModel> _items = [];

  List<CartItemModel> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotalBIF =>
      _items.fold(0.0, (sum, item) => sum + item.subtotalBIF);

  String? get sellerId => _items.isEmpty ? null : _items.first.sellerId;
  String? get sellerName => _items.isEmpty ? null : _items.first.sellerName;

  /// `true` si [product] appartient à un autre vendeur que celui du panier.
  bool belongsToOtherSeller(ProductModel product) =>
      _items.isNotEmpty && _items.first.sellerId != product.sellerId;

  // ───────────────────────────── Ajout ─────────────────────────────
  CartAddResult addToCart(ProductModel product, {int quantity = 1}) {
    if (!product.isAvailable) return CartAddResult.outOfStock;
    if (belongsToOtherSeller(product)) return CartAddResult.otherSeller;

    final safeQuantity = quantity < 1 ? 1 : quantity;
    final index = _items.indexWhere((i) => i.productId == product.id);
    final unitPriceBIF = CurrencyHelper.toBIF(product.price, product.currency);
    var limited = false;

    if (index >= 0) {
      final existing = _items[index];
      var newQuantity = existing.quantity + safeQuantity;
      if (newQuantity > product.stock) {
        newQuantity = product.stock;
        limited = true;
      }
      _items[index] = existing.copyWith(
        quantity: newQuantity,
        maxStock: product.stock,
        unitPriceBIF: unitPriceBIF,
      );
    } else {
      var newQuantity = safeQuantity;
      if (newQuantity > product.stock) {
        newQuantity = product.stock;
        limited = true;
      }
      _items.add(CartItemModel(
        productId: product.id,
        productName: product.name,
        unitPriceBIF: unitPriceBIF,
        imageUrl: product.imageUrl,
        sellerId: product.sellerId,
        sellerName: product.sellerName,
        sellerWhatsapp: product.sellerWhatsapp,
        quantity: newQuantity,
        maxStock: product.stock,
      ));
    }

    notifyListeners();
    return limited ? CartAddResult.reachedStockLimit : CartAddResult.added;
  }

  // ───────────────────────────── Quantités ─────────────────────────────
  /// Retourne `false` si le stock maximum est déjà atteint.
  bool increaseQuantity(String productId) {
    final index = _items.indexWhere((i) => i.productId == productId);
    if (index < 0) return false;

    final item = _items[index];
    if (item.quantity >= item.maxStock) return false;

    _items[index] = item.copyWith(quantity: item.quantity + 1);
    notifyListeners();
    return true;
  }

  void decreaseQuantity(String productId) {
    final index = _items.indexWhere((i) => i.productId == productId);
    if (index < 0) return;

    final item = _items[index];
    if (item.quantity > 1) {
      _items[index] = item.copyWith(quantity: item.quantity - 1);
      notifyListeners();
    } else {
      removeFromCart(productId);
    }
  }

  void removeFromCart(String productId) {
    _items.removeWhere((i) => i.productId == productId);
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }

  // ───────────────────────── Synchronisation catalogue ─────────────────────────
  /// Aligne le panier sur le catalogue courant : produit supprimé ou épuisé →
  /// retiré ; stock réduit → quantité ajustée ; prix modifié → mis à jour.
  /// Retourne la liste des messages à montrer à l'utilisateur.
  List<String> syncWithProducts(List<ProductModel> products) {
    final messages = <String>[];
    final byId = <String, ProductModel>{for (final p in products) p.id: p};
    var changed = false;

    for (final item in List<CartItemModel>.from(_items)) {
      final product = byId[item.productId];

      if (product == null || product.stock <= 0) {
        _items.removeWhere((i) => i.productId == item.productId);
        messages.add(
          '"${item.productName}" n\'est plus disponible : retiré du panier.',
        );
        changed = true;
        continue;
      }

      final index = _items.indexWhere((i) => i.productId == item.productId);
      final newPriceBIF = CurrencyHelper.toBIF(product.price, product.currency);
      final newQuantity =
          item.quantity > product.stock ? product.stock : item.quantity;

      final needsUpdate = newQuantity != item.quantity ||
          product.stock != item.maxStock ||
          (newPriceBIF - item.unitPriceBIF).abs() > 0.0001;

      if (needsUpdate) {
        if (newQuantity != item.quantity) {
          messages.add(
            'Quantité de "${item.productName}" ajustée à $newQuantity (stock disponible).',
          );
        }
        if ((newPriceBIF - item.unitPriceBIF).abs() > 0.0001) {
          messages.add('Le prix de "${item.productName}" a été mis à jour.');
        }
        _items[index] = item.copyWith(
          quantity: newQuantity,
          maxStock: product.stock,
          unitPriceBIF: newPriceBIF,
        );
        changed = true;
      }
    }

    if (changed) notifyListeners();
    return messages;
  }
}
