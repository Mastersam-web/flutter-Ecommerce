import 'package:intl/intl.dart';

import 'constants.dart';

/// Conversion et formatage des montants entre BIF, USD et EUR.
class CurrencyHelper {
  CurrencyHelper._();

  /// Nombre de BIF pour 1 unité de [currency].
  static double rate(String currency) =>
      AppConstants.exchangeRates[currency] ?? 1.0;

  /// Convertit [amount] de la devise [from] vers la devise [to].
  static double convert(
    double amount, {
    required String from,
    required String to,
  }) {
    if (from == to) return amount;
    return amount * rate(from) / rate(to);
  }

  static double toBIF(double amount, String from) =>
      convert(amount, from: from, to: 'BIF');

  static double fromBIF(double amountBIF, String to) =>
      convert(amountBIF, from: 'BIF', to: to);

  /// Arrondit un montant selon la devise (BIF : entier, USD/EUR : 2 décimales).
  static double round(double value, String currency) {
    if (currency == 'BIF') return value.roundToDouble();
    return (value * 100).roundToDouble() / 100;
  }

  /// Formate un montant déjà exprimé dans [currency].
  static String format(double amount, String currency) {
    final formatter =
        currency == 'BIF' ? NumberFormat('#,##0') : NumberFormat('#,##0.00');
    return '${formatter.format(amount)} $currency';
  }

  /// Convertit puis formate.
  static String formatConverted(
    double amount, {
    required String from,
    required String to,
  }) {
    final converted = round(convert(amount, from: from, to: to), to);
    return format(converted, to);
  }

  /// Frais de livraison exprimés dans la devise choisie.
  static double deliveryFee(String currency) =>
      round(fromBIF(AppConstants.deliveryFeeBIF, currency), currency);

  /// Texte décrivant les taux utilisés (affiché au client).
  static String ratesDescription() {
    final usd = format(AppConstants.exchangeRates['USD'] ?? 0, 'BIF');
    final eur = format(AppConstants.exchangeRates['EUR'] ?? 0, 'BIF');
    return '1 USD = $usd  •  1 EUR = $eur';
  }
}
