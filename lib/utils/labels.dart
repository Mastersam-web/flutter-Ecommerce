import 'package:flutter/material.dart';

import 'constants.dart';

/// Libellés et couleurs affichés pour les statuts / options.
class Labels {
  Labels._();

  static String deliveryOption(String value) =>
      value == AppConstants.deliveryHome
          ? 'Livraison à domicile'
          : 'Retrait en boutique';

  static String paymentMethod(String value) {
    switch (value) {
      case AppConstants.payMobileMoney:
        return 'Mobile Money';
      case AppConstants.payBankCard:
        return 'Carte bancaire';
      default:
        return value.isEmpty ? '—' : value;
    }
  }

  static String paymentStatus(String value) {
    switch (value) {
      case AppConstants.paymentPaid:
        return 'Payé';
      case AppConstants.paymentFailed:
        return 'Échoué';
      default:
        return 'En attente';
    }
  }

  static Color paymentStatusColor(String value) {
    switch (value) {
      case AppConstants.paymentPaid:
        return Colors.green;
      case AppConstants.paymentFailed:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  static String orderStatus(String value) {
    switch (value) {
      case AppConstants.statusConfirmed:
        return 'Confirmée';
      case AppConstants.statusPreparing:
        return 'En préparation';
      case AppConstants.statusReady:
        return 'Prête';
      case AppConstants.statusDelivered:
        return 'Livrée';
      case AppConstants.statusCancelled:
        return 'Annulée';
      default:
        return 'En attente';
    }
  }

  static Color orderStatusColor(String value) {
    switch (value) {
      case AppConstants.statusConfirmed:
        return Colors.blue;
      case AppConstants.statusPreparing:
        return Colors.orange;
      case AppConstants.statusReady:
        return Colors.teal;
      case AppConstants.statusDelivered:
        return Colors.green;
      case AppConstants.statusCancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
