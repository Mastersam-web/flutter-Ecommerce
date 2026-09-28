import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../screens/auth/login_screen.dart';
import 'helpers.dart';

/// Vérifie qu'un CLIENT est connecté avant une action protégée (achat, panier…).
///
/// - visiteur → ouvre l'écran de connexion (puis retourne `true` si connecté)
/// - vendeur  → refuse (un vendeur ne passe pas de commande)
Future<bool> ensureClientAuthenticated(
  BuildContext context, {
  String message = 'Connectez-vous pour effectuer cet achat.',
}) async {
  final auth = context.read<AuthProvider>();

  if (!auth.isAuthenticated) {
    final loggedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => LoginScreen(message: message)),
    );
    if (loggedIn != true || !context.mounted) return false;
  }

  final refreshed = context.read<AuthProvider>();
  if (!refreshed.isAuthenticated) return false;

  if (refreshed.isSeller) {
    showAppSnackBar(
      context,
      'Les comptes vendeur ne peuvent pas passer de commande. '
      'Utilisez un compte client.',
      isError: true,
    );
    return false;
  }
  return true;
}

/// Déconnecte l'utilisateur, vide son panier et revient à l'écran racine.
Future<void> logoutAndReset(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  final cart = context.read<CartProvider>();
  final navigator = Navigator.of(context);

  await auth.logout();
  cart.clear();
  navigator.popUntil((route) => route.isFirst);
}
