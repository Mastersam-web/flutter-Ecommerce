import 'package:flutter/material.dart';

/// Application minimale affichée quand Firebase n'est pas (correctement)
/// configuré, à la place d'un écran blanc.
class FirebaseSetupApp extends StatelessWidget {
  const FirebaseSetupApp({
    super.key,
    required this.notConfigured,
    this.details,
  });

  final bool notConfigured;
  final String? details;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Configuration Firebase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FirebaseSetupScreen(notConfigured: notConfigured, details: details),
    );
  }
}

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({
    super.key,
    required this.notConfigured,
    this.details,
  });

  final bool notConfigured;
  final String? details;

  Widget _step(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 12, child: Text(number, style: const TextStyle(fontSize: 12))),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.settings_suggest, size: 64, color: Colors.deepPurple),
                  const SizedBox(height: 16),
                  Text(
                    notConfigured
                        ? 'Firebase n\'est pas encore configuré'
                        : 'Impossible d\'initialiser Firebase',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notConfigured
                        ? 'Le fichier lib/firebase_options.dart contient encore les '
                            'valeurs d\'exemple « YOUR_... ». Renseignez celles de votre projet :'
                        : 'Vérifiez votre connexion internet et les valeurs de '
                            'lib/firebase_options.dart :',
                  ),
                  const SizedBox(height: 16),
                  _step('1', 'Console Firebase → ⚙ Paramètres du projet → Général → Vos applications → ajoutez (ou ouvrez) l\'application Web </>.'),
                  _step('2', 'Copiez apiKey, appId, messagingSenderId, projectId, authDomain et storageBucket dans lib/firebase_options.dart (ou lancez « flutterfire configure »).'),
                  _step('3', 'Activez Authentication → Sign-in method → Email/Mot de passe, créez la base Firestore et publiez firestore.rules.'),
                  _step('4', 'Arrêtez complètement l\'application puis relancez-la (flutter run -d chrome). Un simple hot reload ne suffit pas.'),
                  if (details != null) ...[
                    const SizedBox(height: 16),
                    const Text('Détail technique :', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(details!, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
