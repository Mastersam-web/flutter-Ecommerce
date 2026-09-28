import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import '../../services/storage_service.dart';
import '../../utils/currency_helper.dart';
import '../../utils/error_messages.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/app_image.dart';
import '../../widgets/state_widgets.dart';
import 'create_product_screen.dart';
import 'edit_product_screen.dart';

/// Liste des produits du vendeur connecté : modifier, gérer le stock, supprimer.
class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  final ProductService _service = ProductService();
  Stream<List<ProductModel>>? _stream;
  int _retry = 0;

  Future<void> _delete(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le produit'),
        content: Text('Voulez-vous vraiment supprimer « ${product.name} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _service.deleteProduct(product.id);
      await StorageService().deleteImage(product.imageUrl);
      if (mounted) showAppSnackBar(context, 'Produit supprimé');
    } catch (e) {
      if (mounted) showAppSnackBar(context, friendlyError(e), isError: true);
    }
  }

  Future<void> _editStock(ProductModel product) async {
    final newStock = await showDialog<int>(
      context: context,
      builder: (_) => _StockDialog(product: product),
    );
    if (newStock == null) return;

    try {
      await _service.updateProduct(product.id, {'stock': newStock});
      if (mounted) showAppSnackBar(context, 'Stock mis à jour : $newStock');
    } catch (e) {
      if (mounted) showAppSnackBar(context, friendlyError(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mes produits')),
        body: const Center(child: Text('Utilisateur non connecté')),
      );
    }

    _stream ??= _service.watchSellerProducts(user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes produits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nouveau produit',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateProductScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        key: ValueKey(_retry),
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(
              message: friendlyError(snapshot.error!),
              onRetry: () => setState(() {
                _stream = _service.watchSellerProducts(user.uid);
                _retry++;
              }),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data ?? const <ProductModel>[];
          if (products.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Vous n\'avez encore aucun produit',
              action: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const CreateProductScreen()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Créer mon premier produit'),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final lowStock = product.stock <= 5;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AppImage(
                          url: product.imageUrl,
                          width: 60,
                          height: 60,
                          iconSize: 26,
                        ),
                      ),
                      title: Text(product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(CurrencyHelper.format(
                              product.price, product.currency)),
                          Text(
                            product.stock == 0
                                ? 'Rupture de stock'
                                : 'Stock : ${product.stock}${lowStock ? ' (faible)' : ''}',
                            style: TextStyle(
                              color: product.stock == 0
                                  ? Colors.red
                                  : (lowStock ? Colors.orange : Colors.green),
                              fontSize: 13,
                            ),
                          ),
                          Text(product.categoryName,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditProductScreen(product: product),
                                ),
                              );
                              break;
                            case 'stock':
                              _editStock(product);
                              break;
                            case 'delete':
                              _delete(product);
                              break;
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Modifier'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'stock',
                            child: ListTile(
                              leading: Icon(Icons.inventory),
                              title: Text('Gérer le stock'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red),
                              title: Text('Supprimer',
                                  style: TextStyle(color: Colors.red)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Boîte de dialogue de modification rapide du stock.
class _StockDialog extends StatefulWidget {
  const _StockDialog({required this.product});

  final ProductModel product;

  @override
  State<_StockDialog> createState() => _StockDialogState();
}

class _StockDialogState extends State<_StockDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller =
      TextEditingController(text: widget.product.stock.toString());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(int.parse(_controller.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Stock : ${widget.product.name}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nouvelle quantité en stock',
            border: OutlineInputBorder(),
          ),
          validator: Validators.stock,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Enregistrer')),
      ],
    );
  }
}
