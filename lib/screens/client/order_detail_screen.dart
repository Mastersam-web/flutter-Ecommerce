import 'package:flutter/material.dart';

import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../utils/currency_helper.dart';
import '../../utils/helpers.dart';
import '../../utils/labels.dart';
import '../../widgets/form_helpers.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/whatsapp_button.dart';

/// Détail d'une commande (suivi en temps réel du statut).
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.order});

  final OrderModel order;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final Stream<OrderModel?> _stream =
      OrderService().watchOrder(widget.order.id);

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 16 : 14,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 8),
          Flexible(child: Text(value, style: style, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail de la commande')),
      body: StreamBuilder<OrderModel?>(
        stream: _stream,
        initialData: widget.order,
        builder: (context, snapshot) {
          final order = snapshot.data ?? widget.order;
          final c = order.currency;
          final primary = Theme.of(context).colorScheme.primary;

          return CenteredBox(
            maxWidth: 700,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText('N° ${order.id}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text('Date : ${formatDateTime(order.createdAt)}'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              StatusChip.payment(order.paymentStatus),
                              StatusChip.order(order.orderStatus),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  _section('Articles', [
                    for (final item in order.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            _row(
                              '${item.quantity} × ${CurrencyHelper.format(item.unitPrice, c)}',
                              CurrencyHelper.format(item.subtotal, c),
                            ),
                          ],
                        ),
                      ),
                  ]),
                  _section('Réception', [
                    Text(Labels.deliveryOption(order.deliveryOption),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (order.isDelivery &&
                        (order.deliveryLocation ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Adresse : ${order.deliveryLocation}'),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Téléphone : ${order.clientPhone}'),
                    ),
                  ]),
                  _section('Paiement (simulé)', [
                    _row('Moyen', Labels.paymentMethod(order.paymentMethod)),
                    _row('Statut', Labels.paymentStatus(order.paymentStatus)),
                    if (order.paymentReference.isNotEmpty)
                      _row('Référence', order.paymentReference),
                  ]),
                  _section('Vendeur', [
                    Text(order.sellerName),
                  ]),
                  const SizedBox(height: 16),
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _row('Sous-total',
                              CurrencyHelper.format(order.subtotal, c)),
                          _row(
                            'Livraison',
                            order.isDelivery
                                ? CurrencyHelper.format(order.deliveryFee, c)
                                : 'Aucun frais (retrait)',
                          ),
                          const Divider(),
                          _row('Total', CurrencyHelper.format(order.total, c),
                              bold: true, color: primary),
                          _row('Devise', c),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  WhatsAppOrderButton(
                    order: order,
                    label: 'Envoyer / renvoyer via WhatsApp',
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
