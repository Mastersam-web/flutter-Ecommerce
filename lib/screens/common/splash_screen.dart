import 'package:flutter/material.dart';

/// Écran de chargement affiché pendant la restauration de la session Firebase.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag, size: 80, color: Colors.deepPurple),
            SizedBox(height: 20),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement...'),
          ],
        ),
      ),
    );
  }
}
