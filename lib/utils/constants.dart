/// Constantes globales de l'application.
class AppConstants {
  AppConstants._();

  // ─────────────────────────── Devises ───────────────────────────
  static const List<String> currencies = ['BIF', 'USD', 'EUR'];

  /// TAUX DE CHANGE UTILISÉS PAR L'APPLICATION (simulés, pas d'API externe).
  /// Valeur = nombre de BIF pour 1 unité de la devise.
  ///   1 BIF = 1 BIF
  ///   1 USD = 2 850 BIF
  ///   1 EUR = 3 100 BIF
  static const Map<String, double> exchangeRates = {
    'BIF': 1.0,
    'USD': 2850.0,
    'EUR': 3100.0,
  };

  /// Frais de livraison fixes, exprimés en BIF (convertis dans la devise choisie).
  static const double deliveryFeeBIF = 5000.0;

  // ───────────────────── Collections Firestore ─────────────────────
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String categoriesCollection = 'categories';
  static const String ordersCollection = 'orders';

  // ───────────────────────────── Rôles ─────────────────────────────
  static const String roleClient = 'client';
  static const String roleSeller = 'seller';

  // ─────────────────────── Réception commande ───────────────────────
  static const String deliveryHome = 'delivery';
  static const String deliveryPickup = 'pickup';

  // ───────────────────────────── Paiement ─────────────────────────────
  static const String payMobileMoney = 'mobile_money';
  static const String payBankCard = 'bank_card';

  static const String paymentPaid = 'paid';
  static const String paymentFailed = 'failed';
  static const String paymentPending = 'pending';

  static const List<String> mobileMoneyOperators = [
    'Lumicash',
    'EcoCash',
    'Airtel Money',
  ];

  // ──────────────────────── Statuts de commande ────────────────────────
  static const String statusConfirmed = 'confirmed';
  static const String statusPreparing = 'preparing';
  static const String statusReady = 'ready';
  static const String statusDelivered = 'delivered';
  static const String statusCancelled = 'cancelled';

  /// Statuts que le vendeur peut appliquer à une commande.
  static const List<String> sellerOrderStatuses = [
    statusConfirmed,
    statusPreparing,
    statusReady,
    statusDelivered,
  ];

  // ─────────────────────────── Catégories ───────────────────────────
  /// Catégories par défaut (créées dans Firestore par le vendeur et utilisées
  /// en secours tant que la collection est vide).
  static const List<Map<String, String>> defaultCategories = [
    {
      'id': 'electronique',
      'name': 'Électronique',
      'description': 'Téléphones, ordinateurs, accessoires',
    },
    {
      'id': 'mode',
      'name': 'Mode',
      'description': 'Vêtements et accessoires',
    },
    {
      'id': 'maison',
      'name': 'Maison',
      'description': 'Meubles et décoration',
    },
    {
      'id': 'alimentation',
      'name': 'Alimentation',
      'description': 'Produits alimentaires',
    },
    {
      'id': 'autres',
      'name': 'Autres',
      'description': 'Divers',
    },
  ];

  /// Stock considéré comme "faible" dans le tableau de bord vendeur.
  static const int lowStockThreshold = 5;
}
