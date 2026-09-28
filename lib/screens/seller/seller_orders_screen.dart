import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../utils/constants.dart';
import '../../utils/currency_helper.dart';
import '../../utils/error_messages.dart';
import '../../utils/helpers.dart';
import '../../utils/labels.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/status_chip.dart';

/// Commandes reçues par le vendeur (uniquement celles qui le concernent).
class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  final OrderService _service = OrderService();
  Stream<List<OrderModel>>? _stream;
  int _retry = 0;

  Future<void> _changeStatus(OrderModel order, String status) async {
    if (status == order.orderStatus) return;
    try {
      await _service.updateOrderStatus(order.id, status);
      if (mounted) {
        showAppSnackBar(context, 'Statut mis à jour : ${Labels.orderStatus(status)}');
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, friendlyError(e), isError: true);
    }
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey[700])),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Commandes reçues')),
        body: const Center(child: Text('Utilisateur non connecté')),
      );
    }

    _stream ??= _service.watchSellerOrders(user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Commandes reçues')),
      body: StreamBuilder<List<OrderModel>>(
        key: ValueKey(_retry),
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(
              message: friendlyError(snapshot.error!),
              onRetry: () => setState(() {
                _stream = _service.watchSellerOrders(user.uid);
                _retry++;
              }),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data ?? const <OrderModel>[];
          if (orders.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Aucune commande reçue pour le moment',
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final c = order.currency;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      title: Text(order.id,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('${formatDateTime(order.createdAt)} • ${order.clientName}'),
                          Text(
                            CurrencyHelper.format(order.total, c),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
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
                      childrenPadding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const Text('Client',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        _line('Nom', order.clientName),
                        _line('Téléphone', order.clientPhone),
                        if (order.clientEmail.isNotEmpty)
                          _line('Email', order.clientEmail),
                        const SizedBox(height: 10),
                        const Text('Produits commandés',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        for (final item in order.items)
                          _line(
                            '${item.quantity} ×',
                            '${item.productName} — ${CurrencyHelper.format(item.unitPrice, c)}',
                          ),
                        const SizedBox(height: 10),
                        _line('Sous-total', CurrencyHelper.format(order.subtotal, c)),
                        _line(
                          'Livraison',
                          order.isDelivery
                              ? CurrencyHelper.format(order.deliveryFee, c)
                              : 'Aucun (retrait en boutique)',
                        ),
                        _line('Total', '${CurrencyHelper.format(order.total, c)}  (devise : $c)'),
                        const SizedBox(height: 10),
                        _line('Réception', Labels.deliveryOption(order.deliveryOption)),
                        if (order.isDelivery &&
                            (order.deliveryLocation ?? '').isNotEmpty)
                          _line('Adresse', order.deliveryLocation!),
                        _line(
                          'Paiement',
                          '${Labels.paymentMethod(order.paymentMethod)} — ${Labels.paymentStatus(order.paymentStatus)}',
                        ),
                        const SizedBox(height: 12),
                        const Text('Changer le statut',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: AppConstants.sellerOrderStatuses.map((s) {
                            return ChoiceChip(
                              label: Text(Labels.orderStatus(s)),
                              selected: order.orderStatus == s,
                              onSelected: (_) => _changeStatus(order, s),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
