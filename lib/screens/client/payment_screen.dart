import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/checkout_summary.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/order_service.dart';
import '../../utils/constants.dart';
import '../../utils/currency_helper.dart';
import '../../utils/error_messages.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/form_helpers.dart';
import '../../widgets/option_tile.dart';
import 'order_confirmation_screen.dart';

/// Paiement SIMULÉ (aucune transaction réelle, aucune donnée bancaire envoyée
/// ni enregistrée). Le résultat du paiement est associé à la commande créée.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.summary,
    required this.deliveryOption,
    required this.clientPhone,
    this.deliveryLocation,
  });

  final CheckoutSummary summary;
  final String deliveryOption;
  final String clientPhone;
  final String? deliveryLocation;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  String _method = AppConstants.payMobileMoney;
  String _operator = AppConstants.mobileMoneyOperators.first;
  bool _forceFailure = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _mobileController.text = widget.clientPhone;
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _processing = true);

    // Simulation du traitement du paiement.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (_forceFailure) {
      setState(() => _processing = false);
      await _showFailureDialog();
      return;
    }

    await _placeOrder();
  }

  Future<void> _showFailureDialog() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 44),
        title: const Text('Paiement échoué'),
        content: const Text(
          'Le paiement simulé a été refusé. Aucune somme n\'a été débitée et '
          'aucune commande n\'a été créée.\n\nVous pouvez réessayer ou changer '
          'de moyen de paiement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    final products = context.read<ProductProvider>();
    final user = auth.user;

    if (user == null || cart.isEmpty) {
      setState(() => _processing = false);
      showAppSnackBar(context, 'Session expirée ou panier vide.', isError: true);
      return;
    }

    final summary = widget.summary;
    final seller = cart.items.first;

    final order = OrderModel(
      id: generateOrderId(),
      clientId: user.uid,
      clientName: user.name,
      clientPhone: widget.clientPhone,
      clientEmail: user.email,
      sellerId: seller.sellerId,
      sellerName: seller.sellerName,
      sellerWhatsapp: seller.sellerWhatsapp,
      items: summary.items,
      subtotal: summary.subtotal,
      deliveryFee: summary.deliveryFee,
      total: summary.total,
      currency: summary.currency,
      exchangeRate: summary.exchangeRate,
      deliveryOption: widget.deliveryOption,
      deliveryLocation: widget.deliveryLocation,
      paymentMethod: _method,
      paymentStatus: AppConstants.paymentPaid,
      paymentReference: generatePaymentReference(),
      orderStatus: AppConstants.statusConfirmed,
      createdAt: DateTime.now(),
    );

    try {
      // Enregistre la commande et décrémente les stocks (transaction Firestore).
      await OrderService().placeOrder(order);
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded,
              color: Colors.orange, size: 44),
          title: const Text('Commande non enregistrée'),
          content: Text(
            '${friendlyError(e)}\n\nAucun paiement n\'a été validé. '
            'Vérifiez votre panier.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Retour au panier'),
            ),
          ],
        ),
      );
      if (!mounted) return;

      if (products.hasLoaded) cart.syncWithProducts(products.allProducts);
      final navigator = Navigator.of(context);
      navigator.pop(); // paiement
      if (navigator.canPop()) navigator.pop(); // checkout → retour au panier
      return;
    }

    cart.clear();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: order)),
      (route) => route.isFirst,
    );
  }

  Widget _mobileMoneyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Opérateur'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: AppConstants.mobileMoneyOperators.map((op) {
            return ChoiceChip(
              label: Text(op),
              selected: _operator == op,
              onSelected:
                  _processing ? null : (_) => setState(() => _operator = op),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          enabled: !_processing,
          decoration: appInputDecoration(
            label: 'Numéro Mobile Money',
            icon: Icons.phone_android,
          ),
          validator: Validators.phone,
        ),
      ],
    );
  }

  Widget _cardForm() {
    return Column(
      children: [
        TextFormField(
          controller: _cardHolderController,
          enabled: !_processing,
          textCapitalization: TextCapitalization.characters,
          decoration:
              appInputDecoration(label: 'Titulaire de la carte', icon: Icons.person),
          validator: (v) => Validators.required(v, 'Le titulaire'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cardNumberController,
          enabled: !_processing,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
          ],
          decoration: appInputDecoration(
            label: 'Numéro de carte (16 chiffres)',
            icon: Icons.credit_card,
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Le numéro de carte est obligatoire';
            }
            if (v.length != 16) return 'Le numéro doit contenir 16 chiffres';
            return null;
          },
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                enabled: !_processing,
                keyboardType: TextInputType.datetime,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                  LengthLimitingTextInputFormatter(5),
                ],
                decoration: appInputDecoration(
                  label: 'Expiration',
                  icon: Icons.date_range,
                  hint: 'MM/AA',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Obligatoire';
                  if (!RegExp(r'^(0[1-9]|1[0-2])/\d{2}$').hasMatch(v.trim())) {
                    return 'Format MM/AA';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                enabled: !_processing,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: appInputDecoration(label: 'CVV', icon: Icons.lock),
                validator: (v) {
                  if (v == null || v.length != 3) return '3 chiffres';
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: CenteredBox(
        maxWidth: 640,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          const Text('Montant à payer'),
                          const SizedBox(height: 6),
                          Text(
                            CurrencyHelper.format(
                                summary.total, summary.currency),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.deliveryOption == AppConstants.deliveryHome
                                ? 'Livraison incluse : ${CurrencyHelper.format(summary.deliveryFee, summary.currency)}'
                                : 'Retrait en boutique : aucun frais de livraison',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.science_outlined, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Paiement simulé : aucun argent réel n\'est débité.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Moyen de paiement',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                OptionTile(
                  icon: Icons.phone_android,
                  title: 'Mobile Money',
                  subtitle: 'Lumicash, EcoCash, Airtel Money…',
                  selected: _method == AppConstants.payMobileMoney,
                  onTap: _processing
                      ? null
                      : () => setState(
                          () => _method = AppConstants.payMobileMoney),
                ),
                OptionTile(
                  icon: Icons.credit_card,
                  title: 'Carte bancaire',
                  subtitle: 'Visa, Mastercard…',
                  selected: _method == AppConstants.payBankCard,
                  onTap: _processing
                      ? null
                      : () =>
                          setState(() => _method = AppConstants.payBankCard),
                ),
                const SizedBox(height: 12),
                if (_method == AppConstants.payMobileMoney)
                  _mobileMoneyForm()
                else
                  _cardForm(),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Simuler un paiement échoué'),
                  subtitle: const Text('Option de démonstration pour tester l\'échec'),
                  value: _forceFailure,
                  onChanged: _processing
                      ? null
                      : (value) => setState(() => _forceFailure = value),
                ),
                const SizedBox(height: 16),
                if (_processing)
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Traitement du paiement en cours...'),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _pay,
                      icon: const Icon(Icons.lock_outline),
                      label: Text(
                        'Payer ${CurrencyHelper.format(summary.total, summary.currency)}',
                        style: const TextStyle(fontSize: 16),
                      ),
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
