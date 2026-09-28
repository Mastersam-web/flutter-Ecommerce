import 'package:flutter/material.dart';

import '../utils/labels.dart';

/// Pastille colorée (statut de paiement / de commande).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  factory StatusChip.payment(String status) {
    return StatusChip(
      label: 'Paiement : ${Labels.paymentStatus(status)}',
      color: Labels.paymentStatusColor(status),
    );
  }

  factory StatusChip.order(String status) {
    return StatusChip(
      label: Labels.orderStatus(status),
      color: Labels.orderStatusColor(status),
    );
  }

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
