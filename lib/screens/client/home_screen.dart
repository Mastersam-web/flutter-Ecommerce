import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/auth_guard.dart';
import '../../utils/constants.dart';
import '../../widgets/product_card.dart';
import '../../widgets/state_widgets.dart';
import '../auth/login_screen.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'product_detail_screen.dart';
import 'profile_screen.dart';

/// Catalogue public : accessible aux visiteurs, clients (et vendeurs en lecture).
/// Contient la recherche, le filtre par catégorie et le tri.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _sortLabel(ProductSort sort) {
    switch (sort) {
      case ProductSort.newest:
        return 'Plus récents';
      case ProductSort.priceAsc:
        return 'Prix croissant';
      case ProductSort.priceDesc:
        return 'Prix décroissant';
      case ProductSort.nameAsc:
        return 'Nom (A → Z)';
    }
  }

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  List<Widget> _buildActions(AuthProvider auth, CurrencyProvider currency) {
    return [
      PopupMenuButton<String>(
        tooltip: 'Changer de devise',
        initialValue: currency.selected,
        onSelected: (value) => context.read<CurrencyProvider>().select(value),
        itemBuilder: (context) => AppConstants.currencies
            .map((c) => PopupMenuItem<String>(value: c, child: Text(c)))
            .toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.currency_exchange, size: 20),
              const SizedBox(width: 4),
              Text(
                currency.selected,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      if (!auth.isSeller)
        Consumer<CartProvider>(
          builder: (context, cart, child) {
            return IconButton(
              tooltip: 'Panier',
              icon: Badge(
                isLabelVisible: cart.itemCount > 0,
                label: Text('${cart.itemCount}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
            );
          },
        ),
      if (!auth.isAuthenticated)
        IconButton(
          tooltip: 'Se connecter',
          icon: const Icon(Icons.login),
          onPressed: _openLogin,
        )
      else if (!auth.isSeller)
        PopupMenuButton<String>(
          tooltip: 'Mon compte',
          icon: const Icon(Icons.account_circle_outlined),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                break;
              case 'orders':
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                );
                break;
              case 'logout':
                logoutAndReset(context);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Text(
                auth.user?.name ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'profile',
              child: ListTile(
                leading: Icon(Icons.person_outline),
                title: Text('Mon profil'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'orders',
              child: ListTile(
                leading: Icon(Icons.receipt_long_outlined),
                title: Text('Mes commandes'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Déconnexion', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
    ];
  }

  Widget _buildBody(ProductProvider provider) {
    if (provider.errorMessage != null) {
      return ErrorState(
        message: provider.errorMessage!,
        onRetry: provider.retry,
      );
    }
    if (provider.isLoading && !provider.hasLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final products = provider.filteredProducts;

    if (products.isEmpty) {
      return EmptyState(
        icon: provider.hasActiveFilters
            ? Icons.search_off
            : Icons.inventory_2_outlined,
        title: provider.hasActiveFilters
            ? 'Aucun produit ne correspond à votre recherche'
            : 'Aucun produit disponible pour le moment',
        message: provider.hasActiveFilters
            ? null
            : 'Les vendeurs n\'ont pas encore ajouté de produits.',
        action: provider.hasActiveFilters
            ? TextButton(
                onPressed: () {
                  _searchController.clear();
                  provider.clearFilters();
                },
                child: const Text('Effacer les filtres'),
              )
            : null,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 230,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<ProductProvider>();
    final currency = context.watch<CurrencyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue'),
        actions: _buildActions(auth, currency),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              if (!auth.isAuthenticated)
                Container(
                  width: double.infinity,
                  color: Colors.deepPurple.shade50,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.visibility_outlined, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Vous naviguez en visiteur. Connectez-vous pour acheter.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: _openLogin,
                        child: const Text('Connexion'),
                      ),
                    ],
                  ),
                ),
              if (auth.isSeller)
                Container(
                  width: double.infinity,
                  color: Colors.orange.shade50,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: const Text(
                    'Vous consultez le catalogue public en tant que vendeur.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),

              // Recherche
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un produit...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: provider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearch('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: provider.setSearch,
                ),
              ),

              // Catégories
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Tous'),
                        selected: provider.selectedCategoryId == null,
                        onSelected: (_) => provider.setCategory(null),
                      ),
                    ),
                    ...provider.categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category.name),
                          selected: provider.selectedCategoryId == category.id,
                          onSelected: (_) => provider.setCategory(category.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Compteur + tri
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${provider.filteredProducts.length} produit(s)',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    PopupMenuButton<ProductSort>(
                      tooltip: 'Trier',
                      initialValue: provider.sort,
                      onSelected: provider.setSort,
                      itemBuilder: (context) => ProductSort.values
                          .map((s) => PopupMenuItem<ProductSort>(
                                value: s,
                                child: Text(_sortLabel(s)),
                              ))
                          .toList(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sort, size: 20),
                          const SizedBox(width: 4),
                          Text(_sortLabel(provider.sort)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(child: _buildBody(provider)),
            ],
          ),
        ),
      ),
    );
  }
}
