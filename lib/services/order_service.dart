import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_model.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Accès Firestore aux commandes.
class OrderService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(AppConstants.ordersCollection);

  List<OrderModel> _sortNewestFirst(List<OrderModel> list) {
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Enregistre la commande ET décrémente les stocks dans UNE seule transaction :
  /// soit tout réussit, soit rien n'est modifié.
  ///
  /// Lève une [AppException] si un produit n'existe plus ou si le stock est insuffisant.
  Future<void> placeOrder(OrderModel order) async {
    final orderRef = _orders.doc(order.id);

    await _db.runTransaction<void>((transaction) async {
      // 1) Lectures (toutes les lectures doivent précéder les écritures)
      final stocks = <String, int>{};
      for (final item in order.items) {
        final productRef =
            _db.collection(AppConstants.productsCollection).doc(item.productId);
        final snapshot = await transaction.get(productRef);

        if (!snapshot.exists) {
          throw AppException(
            '"${item.productName}" n\'est plus disponible. '
            'Retirez-le du panier pour continuer.',
          );
        }

        final stock = parseInt(snapshot.data()?['stock']);
        if (stock <= 0) {
          throw AppException('"${item.productName}" est en rupture de stock.');
        }
        if (item.quantity > stock) {
          throw AppException(
            'Stock insuffisant pour "${item.productName}" '
            '(disponible : $stock, demandé : ${item.quantity}).',
          );
        }
        stocks[item.productId] = stock;
      }

      // 2) Écritures
      for (final item in order.items) {
        final productRef =
            _db.collection(AppConstants.productsCollection).doc(item.productId);
        transaction.update(productRef, {
          'stock': (stocks[item.productId] ?? 0) - item.quantity,
        });
      }
      transaction.set(orderRef, order.toMap());
    });
  }

  /// Commandes d'un client (temps réel).
  Stream<List<OrderModel>> watchClientOrders(String clientId) {
    return _orders
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) => _sortNewestFirst(
              snapshot.docs
                  .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
                  .toList(),
            ));
  }

  /// Commandes reçues par un vendeur (temps réel).
  Stream<List<OrderModel>> watchSellerOrders(String sellerId) {
    return _orders
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) => _sortNewestFirst(
              snapshot.docs
                  .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
                  .toList(),
            ));
  }

  /// Suivi d'une seule commande (temps réel).
  Stream<OrderModel?> watchOrder(String orderId) {
    return _orders.doc(orderId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return OrderModel.fromMap(data, snapshot.id);
    });
  }

  /// Le vendeur met à jour le statut (seul champ modifiable d'après les règles).
  Future<void> updateOrderStatus(String orderId, String status) {
    return _orders.doc(orderId).update({'orderStatus': status});
  }
}
