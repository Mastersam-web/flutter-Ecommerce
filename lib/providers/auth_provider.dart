import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../utils/constants.dart';
import '../utils/error_messages.dart';

/// État d'authentification de l'application.
///
/// S'appuie sur `FirebaseAuth.authStateChanges()` : la session est restaurée
/// automatiquement au redémarrage (Web et mobile).
class AuthProvider with ChangeNotifier {
  AuthProvider({AuthService? authService, ProductService? productService})
      : _authService = authService ?? AuthService(),
        _productService = productService ?? ProductService() {
    _listenToAuthChanges();
  }

  final AuthService _authService;
  final ProductService _productService;

  StreamSubscription<User?>? _subscription;
  Timer? _initTimeout;

  UserModel? _user;
  bool _initialized = false;
  bool _isLoading = false;
  bool _busy = false; // connexion / inscription en cours : on ignore le stream
  bool _disposed = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get initialized => _initialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isSeller => _user?.isSeller ?? false;
  bool get isClient => _user?.isClient ?? false;

  void _listenToAuthChanges() {
    _subscription = _authService.authStateChanges.listen(
      _onAuthChanged,
      onError: (Object error) {
        debugPrint('Erreur authStateChanges : $error');
        _markInitialized();
      },
    );

    // Sécurité : si Firebase ne répond pas, on affiche quand même l'application.
    _initTimeout = Timer(const Duration(seconds: 8), _markInitialized);
  }

  void _markInitialized() {
    if (_initialized || _disposed) return;
    _initialized = true;
    notifyListeners();
  }

  Future<void> _onAuthChanged(User? firebaseUser) async {
    if (_busy) return; // login()/register() mettent à jour l'état eux-mêmes

    if (firebaseUser == null) {
      _user = null;
    } else {
      try {
        _user = await _authService.fetchProfile(firebaseUser);
      } catch (e) {
        debugPrint('Impossible de charger le profil : $e');
        _user = null;
      }
    }

    if (_disposed) return;
    _initialized = true;
    notifyListeners();
  }

  // ───────────────────────────── Inscription ─────────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    String? whatsappNumber,
  }) async {
    _busy = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
        whatsappNumber: whatsappNumber,
      );
      return true;
    } catch (e) {
      _errorMessage = friendlyError(e);
      return false;
    } finally {
      _busy = false;
      _isLoading = false;
      _initialized = true;
      if (!_disposed) notifyListeners();
    }
  }

  // ───────────────────────────── Connexion ─────────────────────────────
  Future<bool> login({required String email, required String password}) async {
    _busy = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.login(email: email, password: password);
      return true;
    } catch (e) {
      _errorMessage = friendlyError(e);
      return false;
    } finally {
      _busy = false;
      _isLoading = false;
      _initialized = true;
      if (!_disposed) notifyListeners();
    }
  }

  // ───────────────────────────── Déconnexion ─────────────────────────────
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  // ───────────────────────────── Profil ─────────────────────────────
  Future<bool> updateProfile({
    required String name,
    required String phone,
    String? whatsappNumber,
  }) async {
    final current = _user;
    if (current == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _authService.updateProfile(
        current,
        name: name,
        phone: phone,
        whatsappNumber: whatsappNumber,
      );

      // Les produits d'un vendeur contiennent une copie de son nom / WhatsApp.
      if (updated.role == AppConstants.roleSeller) {
        await _productService.updateSellerInfo(
          sellerId: updated.uid,
          sellerName: updated.name,
          sellerWhatsapp: updated.whatsappNumber ?? '',
        );
      }

      _user = updated;
      return true;
    } catch (e) {
      _errorMessage = friendlyError(e);
      return false;
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _initTimeout?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
