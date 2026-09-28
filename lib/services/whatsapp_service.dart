import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

import '../models/order_model.dart';
import '../utils/constants.dart';
import '../utils/currency_helper.dart';
import '../utils/helpers.dart';

enum WhatsAppResult {
  /// WhatsApp (ou wa.me) a été ouvert avec le message prérempli.
  opened,

  /// Le vendeur n'a pas de numéro WhatsApp exploitable.
  noSellerNumber,

  /// WhatsApp n'est pas installé / ne peut pas être ouvert.
  unavailable,
}

/// Préparation et envoi d'une commande au vendeur via WhatsApp.
class WhatsAppService {
  WhatsAppService._();

  /// Construit le message au format demandé dans le cahier des charges.
  static String buildOrderMessage(OrderModel order) {
    final buffer = StringBuffer()
      ..writeln('NEW ORDER')
      ..writeln('Order ID: ${order.id}')
      ..writeln('Client: ${order.clientName}')
      ..writeln('Phone: ${order.clientPhone}')
      ..writeln('Products:');

    for (final item in order.items) {
      buffer.writeln('- ${item.productName} × ${item.quantity}');
    }

    final delivery = order.isDelivery
        ? CurrencyHelper.format(order.deliveryFee, order.currency)
        : '0 ${order.currency} (pickup)';

    buffer
      ..writeln(
          'Subtotal: ${CurrencyHelper.format(order.subtotal, order.currency)}')
      ..writeln('Delivery: $delivery')
      ..writeln('Total: ${CurrencyHelper.format(order.total, order.currency)}')
      ..writeln(
        'Delivery option: ${order.isDelivery ? 'Delivery' : 'Physical boutique pickup'}',
      );

    final location = order.deliveryLocation;
    if (order.isDelivery && location != null && location.trim().isNotEmpty) {
      buffer.writeln('Location: $location');
    }

    buffer
      ..writeln(
        'Payment: ${order.paymentMethod == AppConstants.payMobileMoney ? 'Mobile Money' : 'Bank Card'}',
      )
      ..write(
        'Payment status: ${order.paymentStatus == AppConstants.paymentPaid ? 'Paid' : order.paymentStatus}',
      );

    return buffer.toString();
  }

  /// Ouvre WhatsApp avec le message prérempli à destination du vendeur.
  ///
  /// Ne lève jamais d'exception : le résultat indique ce qui s'est passé.
  static Future<WhatsAppResult> sendOrder(OrderModel order) async {
    final phone = digitsOnly(order.sellerWhatsapp);
    if (phone.isEmpty) return WhatsAppResult.noSellerNumber;

    final text = Uri.encodeComponent(buildOrderMessage(order));

    try {
      final Uri uri = kIsWeb
          ? Uri.parse('https://wa.me/$phone?text=$text')
          : Uri.parse('whatsapp://send?phone=$phone&text=$text');

      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      return opened ? WhatsAppResult.opened : WhatsAppResult.unavailable;
    } catch (_) {
      return WhatsAppResult.unavailable;
    }
  }
}
