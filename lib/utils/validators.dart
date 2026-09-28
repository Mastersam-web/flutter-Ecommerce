import 'helpers.dart';

/// Validateurs réutilisables pour les formulaires.
class Validators {
  Validators._();

  static String? required(String? value, [String field = 'Ce champ']) {
    if (value == null || value.trim().isEmpty) {
      return '$field est obligatoire';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'email est obligatoire';
    }
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value.trim())) return 'Email invalide';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est obligatoire';
    }
    if (value.length < 6) return 'Minimum 6 caractères';
    return null;
  }

  /// Numéro simple (au moins 8 chiffres).
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro de téléphone est obligatoire';
    }
    if (digitsOnly(value).length < 8) return 'Numéro de téléphone invalide';
    return null;
  }

  /// Numéro WhatsApp au format international : +25779123456.
  static String? whatsapp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro WhatsApp est obligatoire pour un vendeur';
    }
    final normalized = normalizePhone(value);
    if (!RegExp(r'^\+\d{8,15}$').hasMatch(normalized)) {
      return 'Format international requis, ex : +25779123456';
    }
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le prix est obligatoire';
    }
    final price = double.tryParse(value.trim().replaceAll(',', '.'));
    if (price == null || price.isNaN || price.isInfinite) {
      return 'Prix invalide (nombre attendu)';
    }
    if (price <= 0) return 'Le prix doit être supérieur à 0';
    if (price > 1000000000) return 'Prix trop élevé';
    return null;
  }

  static String? stock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le stock est obligatoire';
    }
    final stock = int.tryParse(value.trim());
    if (stock == null) return 'Stock invalide (nombre entier attendu)';
    if (stock < 0) return 'Le stock ne peut pas être négatif';
    if (stock > 1000000) return 'Stock trop élevé';
    return null;
  }
}
