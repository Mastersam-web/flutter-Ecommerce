import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/checkout_summary.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/constants.dart';
import '../../utils/currency_helper.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/currency_selector.dart';
import '../../widgets/form_helpers.dart';
import '../../widgets/option_tile.dart';
import 'payment_screen.dart';

/// Checkout : devise, mode de réception (livraison / boutique), informations de
/// livraison et récapitulatif complet avant le paiement.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  String _deliveryOption = AppConstants.deliveryPickup;

  bool get _isDelivery => _deliveryOption == AppConstants.deliveryHome;

  @override
  void initState() {
    super.initState();
    _phoneController.text = context.read<AuthProvider>().user?.phone ?? '';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _goToPayment() {
    if (!_formKey.currentState!.validate()) return;

    final cart = context.read<CartProvider>();
    final products = context.read<ProductProvider>();

    // Dernière vérification du stock / des prix avant le paiement.
    if (products.hasLoaded) {
      final messages = cart.syncWithProducts(products.allProducts);
      if (messages.isNotEmpty) {
        showAppSnackBar(
          context,
          '${messages.join('\n')}\nVérifiez le récapitulatif puis continuez.',
          isError: true,
        );
        return;
      }
    }
    if (cart.isEmpty) {
      showAppSnackBar(context, 'Votre panier est vide.', isError: true);
      return;
    }

    final summary = CheckoutSummary.fromCart(
      cart: cart.items,
      currency: context.read<CurrencyProvider>().selected,
      isDelivery: _isDelivery,
    );

    var location = _addressController.text.trim();
    final notes = _notesController.text.trim();
    if (_isDelivery && notes.isNotEmpty) location = '$location ($notes)';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          summary: summary,
          deliveryOption: _deliveryOption,
          deliveryLocation: _isDelivery ? location : null,
          clientPhone: _phoneController.text.trim(),
        ),
      ),
    );
  }

  Widget _amountRow(String label, String value,
      {bool bold = false, Color? color}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 17 : 14,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 8),
          Text(value, style: style),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final currency = context.watch<CurrencyProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    final summary = CheckoutSummary.fromCart(
      cart: cart.items,
      currency: currency.selected,
      isDelivery: _isDelivery,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Commande')),
      body: CenteredBox(
        maxWidth: 700,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Devise',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const CurrencySelector(),
                const SizedBox(height: 4),
                Text(
                  'Taux utilisés : ${CurrencyHelper.ratesDescription()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 22),

                const Text('Mode de réception',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                OptionTile(
                  icon: Icons.storefront,
                  title: 'Retrait en boutique',
                  subtitle: 'Gratuit — aucun frais de livraison',
                  selected: !_isDelivery,
                  onTap: () => setState(
                      () => _deliveryOption = AppConstants.deliveryPickup),
                ),
                OptionTile(
                  icon: Icons.delivery_dining,
                  title: 'Livraison à domicile',
                  subtitle:
                      'Frais : ${CurrencyHelper.format(CurrencyHelper.deliveryFee(currency.selected), currency.selected)}',
                  selected: _isDelivery,
                  onTap: () => setState(
                      () => _deliveryOption = AppConstants.deliveryHome),
                ),
                const SizedBox(height: 16),

                // Coordonnées (téléphone toujours demandé) + adresse si livraison
                const Text('Vos coordonnées',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: appInputDecoration(
                      label: 'Téléphone *', icon: Icons.phone),
                  validator: Validators.phone,
                ),
                if (_isDelivery) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: appInputDecoration(
                      label: 'Adresse / lieu de livraison *',
                      icon: Icons.location_on,
                      hint: 'Ex : Bujumbura, Rohero, avenue de la Paix n°12',
                    ),
                    validator: (value) => Validators.required(
                        value, 'L\'adresse de livraison'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: appInputDecoration(
                      label: 'Précisions (facultatif)',
                      icon: Icons.notes,
                      hint: 'Point de repère, étage…',
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                const Text('Récapitulatif de la commande',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vendeur : ${cart.sellerName ?? ''}',
                            style: TextStyle(color: Colors.grey[700])),
                        const Divider(),
                        for (final item in summary.items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                _amountRow(
                                  '${item.quantity} × ${currency.format(item.unitPrice)}',
                                  currency.format(item.subtotal),
                                ),
                              ],
                            ),
                          ),
                        const Divider(),
                        _amountRow('Sous-total',
                            currency.format(summary.subtotal)),
                        _amountRow(
                          'Réception',
                          _isDelivery
                              ? 'Livraison à domicile'
                              : 'Retrait en boutique',
                        ),
                        _amountRow(
                          'Frais de livraison',
                          _isDelivery
                              ? currency.format(summary.deliveryFee)
                              : 'Aucun (0 ${currency.selected})',
                        ),
                        const Divider(),
                        _amountRow('Total à payer',
                            currency.format(summary.total),
                            bold: true, color: primary),
                        Text('Devise : ${currency.selected}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: cart.isEmpty ? null : _goToPayment,
                    child: const Text('Continuer vers le paiement',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
