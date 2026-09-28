import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../utils/auth_guard.dart';
import '../../utils/constants.dart';
import '../../utils/currency_helper.dart';
import '../client/home_screen.dart';
import '../client/profile_screen.dart';
import 'create_product_screen.dart';
import 'my_products_screen.dart';
import 'seller_orders_screen.dart';

/// Tableau de bord du vendeur : statistiques + accès aux fonctions vendeur.
class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  Stream<List<ProductModel>>? _productsStream;
  Stream<List<OrderModel>>? _ordersStream;
  String? _streamsFor;

  @override
  void initState() {
    super.initState();
    // Crée les catégories par défaut dans Firestore (une seule fois).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ProductService().seedDefaultCategories().catchError((Object e) {
        debugPrint('Catégories par défaut non créées : $e');
      });
    });
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user != null && _streamsFor != user.uid) {
      _streamsFor = user.uid;
      _productsStream = ProductService().watchSellerProducts(user.uid);
      _ordersStream = OrderService().watchSellerOrders(user.uid);
    }

    final missingWhatsapp = (user?.whatsappNumber ?? '').isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Vendeur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => logoutAndReset(context),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Bonjour ${user?.name ?? ''} 👋',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'WhatsApp : ${missingWhatsapp ? 'Non renseigné' : user!.whatsappNumber}',
                style: TextStyle(color: Colors.grey[700]),
              ),
              if (missingWhatsapp)
                Card(
                  color: Colors.orange.shade50,
                  margin: const EdgeInsets.only(top: 12),
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber, color: Colors.orange),
                    title: const Text('Ajoutez votre numéro WhatsApp'),
                    subtitle: const Text(
                        'Il est nécessaire pour recevoir les commandes des clients.'),
                    onTap: () => _push(const ProfileScreen()),
                  ),
                ),
              const SizedBox(height: 16),

              // ─── Statistiques ───
              StreamBuilder<List<ProductModel>>(
                stream: _productsStream,
                builder: (context, productsSnap) {
                  return StreamBuilder<List<OrderModel>>(
                    stream: _ordersStream,
                    builder: (context, ordersSnap) {
                      final products = productsSnap.data;
                      final orders = ordersSnap.data;

                      final lowStock = products
                          ?.where((p) =>
                              p.stock <= AppConstants.lowStockThreshold)
                          .length;
                      final revenueBIF = orders
                          ?.where((o) =>
                              o.paymentStatus == AppConstants.paymentPaid)
                          .fold<double>(
                              0.0,
                              (sum, o) =>
                                  sum +
                                  CurrencyHelper.toBIF(o.total, o.currency));

                      return Wrap(
                        spacing: 8,
                        runSpacing: 0,
                        children: [
                          _statCard('Produits', '${products?.length ?? '—'}',
                              Icons.inventory_2, Colors.orange),
                          _statCard('Stock faible / rupture', '${lowStock ?? '—'}',
                              Icons.warning_amber, Colors.red),
                          _statCard('Commandes', '${orders?.length ?? '—'}',
                              Icons.receipt_long, Colors.green),
                          _statCard(
                            'Chiffre d\'affaires',
                            revenueBIF == null
                                ? '—'
                                : CurrencyHelper.format(
                                    revenueBIF.roundToDouble(), 'BIF'),
                            Icons.payments,
                            Colors.deepPurple,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              _menuTile(
                icon: Icons.add,
                color: Colors.deepPurple,
                title: 'Créer un produit',
                subtitle: 'Ajouter un nouveau produit au catalogue',
                onTap: () => _push(const CreateProductScreen()),
              ),
              _menuTile(
                icon: Icons.inventory_2,
                color: Colors.orange,
                title: 'Mes produits',
                subtitle: 'Modifier, gérer le stock, supprimer',
                onTap: () => _push(const MyProductsScreen()),
              ),
              _menuTile(
                icon: Icons.receipt_long,
                color: Colors.green,
                title: 'Commandes reçues',
                subtitle: 'Voir et suivre les commandes de mes produits',
                onTap: () => _push(const SellerOrdersScreen()),
              ),
              _menuTile(
                icon: Icons.person,
                color: Colors.blue,
                title: 'Mon profil / WhatsApp',
                subtitle: 'Gérer mes informations et mon numéro WhatsApp',
                onTap: () => _push(const ProfileScreen()),
              ),
              _menuTile(
                icon: Icons.storefront,
                color: Colors.teal,
                title: 'Voir le catalogue public',
                subtitle: 'Voir mes produits tels que les clients les voient',
                onTap: () => _push(const HomeScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
