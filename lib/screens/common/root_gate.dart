import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../client/home_screen.dart';
import '../seller/seller_dashboard.dart';
import 'splash_screen.dart';

/// Écran racine : choisit l'interface selon l'état d'authentification.
///  - session en cours de restauration → chargement
///  - vendeur connecté → espace vendeur
///  - visiteur ou client → catalogue public (le visiteur n'a PAS besoin de compte)
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.initialized) return const SplashScreen();
    if (auth.isSeller) return const SellerDashboard();
    return const HomeScreen();
  }
}
