import 'package:flutter/material.dart';

import '../../models/order_model.dart';
import '../../utils/currency_helper.dart';
import '../../utils/labels.dart';
import '../../widgets/form_helpers.dart';
import '../../widgets/whatsapp_button.dart';
import 'order_history_screen.dart';

/// Confirmation affichée après un paiement réussi et l'enregistrement de la
/// commande dans Firestore. Permet d'envoyer la commande au vendeur via WhatsApp.
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commande confirmée'),
        automaticallyImplyLeading: false,
      ),
      body: CenteredBox(
        maxWidth: 600,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 90),
              const SizedBox(height: 12),
              const Text(
                'Merci pour votre commande !',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              SelectableText('N° ${order.id}',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vendeur : ${order.sellerName}'),
                      const SizedBox(height: 6),
                      for (final item in order.items)
                        Text('• ${item.productName} × ${item.quantity}'),
                      const Divider(),
                      Text(Labels.deliveryOption(order.deliveryOption)),
                      if (order.isDelivery &&
                          (order.deliveryLocation ?? '').isNotEmpty)
                        Text('Adresse : ${order.deliveryLocation}'),
                      Text(
                        order.isDelivery
                            ? 'Frais de livraison : ${CurrencyHelper.format(order.deliveryFee, order.currency)}'
                            : 'Aucun frais de livraison',
                      ),
                      const Divider(),
                      Text(
                          'Paiement : ${Labels.paymentMethod(order.paymentMethod)} — ${Labels.paymentStatus(order.paymentStatus)}'),
                      const SizedBox(height: 8),
                      Text(
                        'Total payé : ${CurrencyHelper.format(order.total, order.currency)}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              WhatsAppOrderButton(order: order),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const OrderHistoryScreen()),
                  ),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Voir mes commandes'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () => Navigator.of(context)
                      .popUntil((route) => route.isFirst),
                  child: const Text('Retour à l\'accueil'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
