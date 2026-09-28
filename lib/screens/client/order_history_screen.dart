import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../utils/currency_helper.dart';
import '../../utils/error_messages.dart';
import '../../utils/helpers.dart';
import '../../utils/labels.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/status_chip.dart';
import 'order_detail_screen.dart';

/// Historique des commandes du client connecté (lu depuis Firestore).
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  Stream<List<OrderModel>>? _stream;
  int _retry = 0;

  Stream<List<OrderModel>> _buildStream(String uid) =>
      OrderService().watchClientOrders(uid);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mes commandes')),
        body: const EmptyState(
          icon: Icons.lock_outline,
          title: 'Connectez-vous pour voir vos commandes',
        ),
      );
    }

    _stream ??= _buildStream(user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes commandes')),
      body: StreamBuilder<List<OrderModel>>(
        key: ValueKey(_retry),
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(
              message: friendlyError(snapshot.error!),
              onRetry: () => setState(() {
                _stream = _buildStream(user.uid);
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
              title: 'Aucune commande pour le moment',
              message: 'Vos commandes apparaîtront ici après votre premier achat.',
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
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(order: order),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    order.id,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  CurrencyHelper.format(
                                      order.total, order.currency),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(formatDateTime(order.createdAt),
                                style: TextStyle(color: Colors.grey[700])),
                            const SizedBox(height: 4),
                            Text(
                              order.items
                                  .map((i) => '${i.productName} × ${i.quantity}')
                                  .join(', '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(Labels.deliveryOption(order.deliveryOption),
                                style: TextStyle(color: Colors.grey[700])),
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
