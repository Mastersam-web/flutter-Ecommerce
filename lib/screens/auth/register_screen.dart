import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/form_helpers.dart';

/// Inscription client ou vendeur (Firebase Auth + profil Firestore).
/// Le vendeur doit obligatoirement fournir un numéro WhatsApp.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _whatsappController = TextEditingController();

  String _role = AppConstants.roleClient;
  bool _obscurePassword = true;

  bool get _isSeller => _role == AppConstants.roleSeller;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      phone: _phoneController.text,
      role: _role,
      whatsappNumber: _isSeller ? _whatsappController.text : null,
    );
    if (!mounted) return;

    if (success) {
      showAppSnackBar(context, 'Inscription réussie, bienvenue !');
      Navigator.of(context).pop(true);
    } else {
      showAppSnackBar(
        context,
        auth.errorMessage ?? 'Erreur d\'inscription',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: SafeArea(
        child: CenteredBox(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Créer un compte',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const Text('Je suis :',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: [
                      ChoiceChip(
                        avatar: const Icon(Icons.shopping_cart, size: 18),
                        label: const Text('Client'),
                        selected: !_isSeller,
                        onSelected: (_) =>
                            setState(() => _role = AppConstants.roleClient),
                      ),
                      ChoiceChip(
                        avatar: const Icon(Icons.store, size: 18),
                        label: const Text('Vendeur'),
                        selected: _isSeller,
                        onSelected: (_) =>
                            setState(() => _role = AppConstants.roleSeller),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: appInputDecoration(
                        label: 'Nom complet', icon: Icons.person),
                    validator: (v) => Validators.required(v, 'Le nom'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        appInputDecoration(label: 'Email', icon: Icons.email),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: appInputDecoration(
                        label: 'Téléphone', icon: Icons.phone),
                    validator: Validators.phone,
                  ),
                  const SizedBox(height: 16),
                  if (_isSeller) ...[
                    TextFormField(
                      controller: _whatsappController,
                      keyboardType: TextInputType.phone,
                      decoration: appInputDecoration(
                        label: 'Numéro WhatsApp *',
                        icon: Icons.chat,
                        hint: '+25779123456',
                      ),
                      validator: Validators.whatsapp,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Les clients vous enverront leurs commandes sur ce numéro '
                      '(format international avec « + »).',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: appInputDecoration(
                      label: 'Mot de passe',
                      icon: Icons.lock,
                      suffix: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'S\'inscrire',
                    isLoading: isLoading,
                    onPressed: _register,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
