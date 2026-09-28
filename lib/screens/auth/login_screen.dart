import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/form_helpers.dart';
import 'register_screen.dart';

/// Connexion (Firebase Authentication).
/// Se ferme avec `true` quand la connexion réussit ; l'écran racine
/// (RootGate) affiche ensuite l'interface correspondant au rôle.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.message});

  /// Message d'information (ex. « Connectez-vous pour acheter »).
  final String? message;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      showAppSnackBar(
        context,
        auth.errorMessage ?? 'Erreur de connexion',
        isError: true,
      );
    }
  }

  Future<void> _openRegister() async {
    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (registered == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: SafeArea(
        child: CenteredBox(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Icon(Icons.shopping_bag, size: 72, color: primary),
                  const SizedBox(height: 12),
                  const Text(
                    'Bienvenue',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Connectez-vous pour continuer',
                    style: TextStyle(color: Colors.grey),
                  ),
                  if (widget.message != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(child: Text(widget.message!)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration:
                        appInputDecoration(label: 'Email', icon: Icons.email),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
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
                    onFieldSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Se connecter',
                    isLoading: isLoading,
                    onPressed: _login,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: isLoading ? null : _openRegister,
                    child: const Text('Pas encore de compte ? S\'inscrire'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Continuer sans compte'),
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
