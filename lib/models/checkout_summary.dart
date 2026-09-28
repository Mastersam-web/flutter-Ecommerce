import '../utils/currency_helper.dart';
import 'cart_item_model.dart';
import 'order_model.dart';

/// Récapitulatif d'une commande calculé à partir du panier, dans la devise choisie.
///
/// Les mêmes chiffres sont affichés à l'écran (panier, checkout, paiement)
/// et enregistrés dans Firestore : pas de divergence possible.
class CheckoutSummary {
  const CheckoutSummary({
    required this.currency,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.exchangeRate,
    required this.isDelivery,
  });

  final String currency;
  final List<OrderItem> items; // même ordre que le panier
  final double subtotal;
  final double deliveryFee;
  final double total;
  final double exchangeRate;
  final bool isDelivery;

  factory CheckoutSummary.fromCart({
    required List<CartItemModel> cart,
    required String currency,
    required bool isDelivery,
  }) {
    final items = cart.map((c) {
      final unit = CurrencyHelper.round(
        CurrencyHelper.fromBIF(c.unitPriceBIF, currency),
        currency,
      );
      return OrderItem(
        productId: c.productId,
        productName: c.productName,
        unitPrice: unit,
        quantity: c.quantity,
      );
    }).toList();

    final subtotal = CurrencyHelper.round(
      items.fold<double>(0.0, (sum, item) => sum + item.subtotal),
      currency,
    );
    final fee = isDelivery ? CurrencyHelper.deliveryFee(currency) : 0.0;
    final total = CurrencyHelper.round(subtotal + fee, currency);

    return CheckoutSummary(
      currency: currency,
      items: items,
      subtotal: subtotal,
      deliveryFee: fee,
      total: total,
      exchangeRate: CurrencyHelper.rate(currency),
      isDelivery: isDelivery,
    );
  }
}
