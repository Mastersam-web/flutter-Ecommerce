import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Ligne d'une commande. Les montants sont exprimés dans la devise de la commande.
class OrderItem {
  const OrderItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  double get subtotal => unitPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'unitPrice': unitPrice,
      'quantity': quantity,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: (map['productId'] as String?) ?? '',
      productName: (map['productName'] as String?) ?? '',
      unitPrice: parseDouble(map['unitPrice']),
      quantity: parseInt(map['quantity']),
    );
  }
}

/// Commande stockée dans `orders/{orderId}` (id du type ORD-260919-4821).
class OrderModel {
  const OrderModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.clientEmail,
    required this.sellerId,
    required this.sellerName,
    required this.sellerWhatsapp,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.currency,
    required this.exchangeRate,
    required this.deliveryOption,
    this.deliveryLocation,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paymentReference,
    required this.orderStatus,
    required this.createdAt,
  });

  final String id;

  // Client
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String clientEmail;

  // Vendeur
  final String sellerId;
  final String sellerName;
  final String sellerWhatsapp;

  // Contenu et montants (dans [currency])
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String currency;

  /// Taux utilisé : nombre de BIF pour 1 unité de [currency] (traçabilité).
  final double exchangeRate;

  // Réception
  final String deliveryOption; // 'delivery' ou 'pickup'
  final String? deliveryLocation;

  // Paiement (simulé)
  final String paymentMethod; // 'mobile_money' ou 'bank_card'
  final String paymentStatus; // 'paid', 'failed', 'pending'
  final String paymentReference;

  final String orderStatus;
  final DateTime createdAt;

  bool get isDelivery => deliveryOption == AppConstants.deliveryHome;

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientEmail': clientEmail,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerWhatsapp': sellerWhatsapp,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'currency': currency,
      'exchangeRate': exchangeRate,
      'deliveryOption': deliveryOption,
      'deliveryLocation': deliveryLocation,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentReference': paymentReference,
      'orderStatus': orderStatus,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String docId) {
    final rawItems = (map['items'] as List<dynamic>?) ?? const <dynamic>[];
    return OrderModel(
      id: docId,
      clientId: (map['clientId'] as String?) ?? '',
      clientName: (map['clientName'] as String?) ?? '',
      clientPhone: (map['clientPhone'] as String?) ?? '',
      clientEmail: (map['clientEmail'] as String?) ?? '',
      sellerId: (map['sellerId'] as String?) ?? '',
      sellerName: (map['sellerName'] as String?) ?? '',
      sellerWhatsapp: (map['sellerWhatsapp'] as String?) ?? '',
      items: rawItems
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      subtotal: parseDouble(map['subtotal']),
      deliveryFee: parseDouble(map['deliveryFee']),
      total: parseDouble(map['total']),
      currency: (map['currency'] as String?) ?? 'BIF',
      exchangeRate: map['exchangeRate'] == null
          ? 1.0
          : parseDouble(map['exchangeRate']),
      deliveryOption:
          (map['deliveryOption'] as String?) ?? AppConstants.deliveryPickup,
      deliveryLocation: map['deliveryLocation'] as String?,
      paymentMethod: (map['paymentMethod'] as String?) ?? '',
      paymentStatus:
          (map['paymentStatus'] as String?) ?? AppConstants.paymentPending,
      paymentReference: (map['paymentReference'] as String?) ?? '',
      orderStatus:
          (map['orderStatus'] as String?) ?? AppConstants.statusConfirmed,
      createdAt: parseDate(map['createdAt']),
    );
  }
}
