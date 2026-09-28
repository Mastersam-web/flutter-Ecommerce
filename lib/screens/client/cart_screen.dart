import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/checkout_summary.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/auth_guard.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_image.dart';
import '../../widgets/currency_selector.dart';
import '../../widgets/state_widgets.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncWithCatalogue());
  }

  /// Retire les produits supprimés / épuisés et ajuste les quantités au stock.
  void _syncWithCatalogue() {
    if (!mounted) return;
    final products = context.read<ProductProvider>();
    if (!products.hasLoaded) return;

    final messages =
        context.read<CartProvider>().syncWithProducts(products.allProducts);
    if (messages.isNotEmpty) {
      showAppSnackBar(context, messages.join('\n'), isError: true);
    }
  }

  Future<void> _confirmClear(CartProvider cart) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Vider le panier'),
        content: const Text('Voulez-vous vraiment vider tout le panier ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Vider', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) cart.clear();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final currency = context.watch<CurrencyProvider>();

    // Action protégée : le panier est réservé aux clients connectés.
    if (!auth.isAuthenticated || auth.isSeller) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mon panier')),
        body: EmptyState(
          icon: Icons.lock_outline,
          title: auth.isSeller
              ? 'Les vendeurs n\'ont pas de panier'
              : 'Connectez-vous pour voir votre panier',
          message: auth.isSeller
              ? 'Connectez-vous avec un compte client pour acheter.'
              : 'Vous devez avoir un compte client pour passer commande.',
          action: auth.isSeller
              ? null
              : ElevatedButton(
                  onPressed: () => ensureClientAuthenticated(context),
                  child: const Text('Se connecter'),
                ),
        ),
      );
    }

    final summary = CheckoutSummary.fromCart(
      cart: cart.items,
      currency: currency.selected,
      isDelivery: false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon panier'),
        actions: [
          if (!cart.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Vider le panier',
              onPressed: () => _confirmClear(cart),
            ),
        ],
      ),
      body: cart.isEmpty
          ? const EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Votre panier est vide',
              message: 'Ajoutez des produits depuis le catalogue.',
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: Row(
                        children: [
                          const Text('Devise :',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 12),
                          const Expanded(child: CurrencySelector()),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Vendeur : ${cart.sellerName ?? ''}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: cart.items.length,
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          final line = summary.items[index];
                          final atMax = item.quantity >= item.maxStock;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: AppImage(
                                      url: item.imageUrl,
                                      width: 70,
                                      height: 70,
                                      iconSize: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${currency.format(line.unitPrice)} / unité',
                                          style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 13),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            IconButton(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              tooltip: 'Diminuer',
                                              onPressed: () => cart
                                                  .decreaseQuantity(
                                                      item.productId),
                                              icon: const Icon(Icons
                                                  .remove_circle_outline),
                                            ),
                                            Text(
                                              '${item.quantity}',
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            IconButton(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              tooltip: 'Augmenter',
                                              onPressed: () {
                                                if (!cart.increaseQuantity(
                                                    item.productId)) {
                                                  showAppSnackBar(
                                                    context,
                                                    'Stock maximum atteint (${item.maxStock}).',
                                                    isError: true,
                                                  );
                                                }
                                              },
                                              icon: Icon(
                                                Icons.add_circle_outline,
                                                color: atMax
                                                    ? Colors.grey
                                                    : null,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              currency.format(line.subtotal),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ],
                                        ),
                                        if (atMax)
                                          Text(
                                            'Stock maximum atteint',
                                            style: TextStyle(
                                                color: Colors.orange.shade800,
                                                fontSize: 12),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Retirer',
                                    onPressed: () =>
                                        cart.removeFromCart(item.productId),
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Sous-total',
                                    style: TextStyle(fontSize: 16)),
                                Text(
                                  currency.format(summary.subtotal),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  _syncWithCatalogue();
                                  if (context.read<CartProvider>().isEmpty) {
                                    return;
                                  }
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const CheckoutScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Passer la commande',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
