import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/product_provider.dart';
import 'screens/common/firebase_setup_screen.dart';
import 'screens/common/root_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var notConfigured = false;
  String? errorDetails;

  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (_looksLikePlaceholder(options)) {
      notConfigured = true;
    } else if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: options)
          .timeout(const Duration(seconds: 20));
    }
  } catch (e) {
    errorDetails = e.toString();
  }

  // Au lieu d'un écran blanc silencieux, on affiche toujours quelque chose.
  if (notConfigured || errorDetails != null) {
    runApp(FirebaseSetupApp(
      notConfigured: notConfigured,
      details: errorDetails,
    ));
    return;
  }

  runApp(const MyApp());
}

bool _looksLikePlaceholder(FirebaseOptions options) {
  return options.apiKey.startsWith('YOUR_') ||
      options.appId.startsWith('YOUR_') ||
      options.projectId.startsWith('YOUR_');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
          lazy: false,
        ),
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => ProductProvider()..start(),
          lazy: false,
        ),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ChangeNotifierProvider<CurrencyProvider>(
          create: (_) => CurrencyProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Boutique Firebase',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true),
        ),
        home: const RootGate(),
      ),
    );
  }
}
