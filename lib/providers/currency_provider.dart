import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import '../utils/constants.dart';
import '../utils/currency_helper.dart';

/// Devise choisie par l'utilisateur (BIF, USD ou EUR).
class CurrencyProvider with ChangeNotifier {
  String _selected = AppConstants.currencies.first;

  String get selected => _selected;

  void select(String currency) {
    if (!AppConstants.currencies.contains(currency) || currency == _selected) {
      return;
    }
    _selected = currency;
    notifyListeners();
  }

  /// Prix d'un produit converti dans la devise choisie.
  String formatProduct(ProductModel product) {
    return CurrencyHelper.formatConverted(
      product.price,
      from: product.currency,
      to: _selected,
    );
  }

  /// Formate un montant déjà exprimé dans la devise choisie.
  String format(double amount) => CurrencyHelper.format(amount, _selected);
}
