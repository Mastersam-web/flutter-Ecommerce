import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Convertit une valeur Firestore (Timestamp, String ISO…) en DateTime.
DateTime parseDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

double parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  return 0;
}

int parseInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Garde uniquement le "+" initial et les chiffres : "+257 79-12 34 56" → "+25779123456".
String normalizePhone(String raw) => raw.replaceAll(RegExp(r'[^\d+]'), '');

/// Garde uniquement les chiffres (format attendu par wa.me).
String digitsOnly(String raw) => raw.replaceAll(RegExp(r'\D'), '');

/// Génère un identifiant de commande lisible, ex : ORD-260919-4821.
String generateOrderId() {
  final date = DateFormat('yyMMdd').format(DateTime.now());
  final random = Random().nextInt(9000) + 1000;
  return 'ORD-$date-$random';
}

/// Génère une référence de paiement simulée, ex : SIM-83920417.
String generatePaymentReference() {
  final random = Random().nextInt(90000000) + 10000000;
  return 'SIM-$random';
}

String formatDateTime(DateTime date) =>
    DateFormat('dd/MM/yyyy HH:mm').format(date);

/// Affiche un SnackBar (vert par défaut, rouge si [isError]).
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  SnackBarAction? action,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      action: action,
    ),
  );
}
