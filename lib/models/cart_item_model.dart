/// Ligne du panier (stocké en mémoire côté client).
///
/// Le prix unitaire est converti en BIF à l'ajout au panier : c'est la devise
/// de référence pour tous les calculs (voir `CurrencyHelper`).
class CartItemModel {
  const CartItemModel({
    required this.productId,
    required this.productName,
    required this.unitPriceBIF,
    required this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    required this.sellerWhatsapp,
    required this.quantity,
    required this.maxStock,
  });

  final String productId;
  final String productName;
  final double unitPriceBIF;
  final String imageUrl;
  final String sellerId;
  final String sellerName;
  final String sellerWhatsapp;
  final int quantity;
  final int maxStock;

  double get subtotalBIF => unitPriceBIF * quantity;

  CartItemModel copyWith({
    double? unitPriceBIF,
    int? quantity,
    int? maxStock,
  }) {
    return CartItemModel(
      productId: productId,
      productName: productName,
      unitPriceBIF: unitPriceBIF ?? this.unitPriceBIF,
      imageUrl: imageUrl,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerWhatsapp: sellerWhatsapp,
      quantity: quantity ?? this.quantity,
      maxStock: maxStock ?? this.maxStock,
    );
  }
}
