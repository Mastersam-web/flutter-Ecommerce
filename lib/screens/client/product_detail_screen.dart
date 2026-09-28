import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/auth_guard.dart';
import '../../utils/currency_helper.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_image.dart';
import '../../widgets/state_widgets.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final ProductModel product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  Future<void> _addToCart(ProductModel product) async {
    // Action protégée : un visiteur est redirigé vers la connexion.
    final allowed = await ensureClientAuthenticated(
      context,
      message: 'Connectez-vous ou créez un compte client pour acheter ce produit.',
    );
    if (!allowed || !mounted) return;

    final cart = context.read<CartProvider>();

    if (cart.belongsToOtherSeller(product)) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Panier d\'un autre vendeur'),
          content: Text(
            'Votre panier contient des produits de ${cart.sellerName}. '
            'Une commande ne concerne qu\'un seul vendeur. '
            'Vider le panier et ajouter ce produit ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Vider et ajouter'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
      cart.clear();
    }

    final result = cart.addToCart(product, quantity: _quantity);
    if (!mounted) return;

    switch (result) {
      case CartAddResult.outOfStock:
        showAppSnackBar(context, 'Produit en rupture de stock', isError: true);
        break;
      case CartAddResult.otherSeller:
        showAppSnackBar(context, 'Produit d\'un autre vendeur', isError: true);
        break;
      case CartAddResult.reachedStockLimit:
        showAppSnackBar(
          context,
          'Quantité limitée au stock disponible (${product.stock}).',
          isError: true,
        );
        break;
      case CartAddResult.added:
        showAppSnackBar(
          context,
          '${product.name} ajouté au panier',
          action: SnackBarAction(
            label: 'Voir le panier',
            textColor: Colors.white,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final currency = context.watch<CurrencyProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    // Version "live" du produit (stock / prix mis à jour, ou supprimé).
    final live = products.byId(widget.product.id);
    if (products.hasLoaded && live == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détail du produit')),
        body: const EmptyState(
          icon: Icons.remove_shopping_cart_outlined,
          title: 'Ce produit n\'est plus disponible',
          message: 'Il a été retiré du catalogue par le vendeur.',
        ),
      );
    }
    final product = live ?? widget.product;
    final maxQuantity = product.stock < 1 ? 1 : product.stock;
    if (_quantity > maxQuantity) _quantity = maxQuantity;

    return Scaffold(
      appBar: AppBar(title: const Text('Détail du produit')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: AppImage(
                    url: product.imageUrl,
                    fit: BoxFit.cover,
                    iconSize: 60,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currency.formatProduct(product),
                        style: TextStyle(
                          fontSize: 22,
                          color: primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (product.currency != currency.selected)
                        Text(
                          'Prix du vendeur : ${CurrencyHelper.format(product.price, product.currency)}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            product.isAvailable
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 18,
                            color:
                                product.isAvailable ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            product.isAvailable
                                ? 'En stock : ${product.stock} disponible(s)'
                                : 'Rupture de stock',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: product.isAvailable
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.store),
                              title: const Text('Vendeur'),
                              subtitle: Text(product.sellerName),
                            ),
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.category_outlined),
                              title: const Text('Catégorie'),
                              subtitle: Text(product.categoryName.isEmpty
                                  ? '—'
                                  : product.categoryName),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Description',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(product.description,
                          style: const TextStyle(height: 1.4)),
                      const SizedBox(height: 24),
                      if (product.isAvailable) ...[
                        const Text(
                          'Quantité',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              onPressed: _quantity < product.stock
                                  ? () => setState(() => _quantity++)
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: product.isAvailable ? () => _addToCart(product) : null,
              icon: const Icon(Icons.add_shopping_cart),
              label: Text(
                product.isAvailable ? 'Ajouter au panier' : 'Rupture de stock',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
