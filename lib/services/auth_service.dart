import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';
import '../utils/error_messages.dart';
import '../utils/helpers.dart';

/// Authentification (Firebase Auth) + profil utilisateur (Cloud Firestore).
class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(AppConstants.usersCollection);

  /// Émet l'utilisateur Firebase courant à chaque connexion / déconnexion.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ───────────────────────────── Inscription ─────────────────────────────
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role, // 'client' ou 'seller'
    String? whatsappNumber,
  }) async {
    UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AppException(_authMessage(e));
    } catch (e) {
      throw AppException(friendlyError(e));
    }

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw const AppException('Création du compte impossible.');
    }

    final isSeller = role == AppConstants.roleSeller;
    final profile = UserModel(
      uid: firebaseUser.uid,
      name: name.trim(),
      email: email.trim(),
      phone: normalizePhone(phone),
      role: role,
      whatsappNumber: (isSeller && whatsappNumber != null)
          ? normalizePhone(whatsappNumber)
          : null,
      createdAt: DateTime.now(),
    );

    try {
      await _users.doc(firebaseUser.uid).set(profile.toMap());
    } catch (e) {
      // On annule la création du compte Auth pour que l'utilisateur puisse réessayer.
      try {
        await firebaseUser.delete();
      } catch (_) {}
      throw AppException(friendlyError(e));
    }

    return profile;
  }

  // ───────────────────────────── Connexion ─────────────────────────────
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    UserCredential credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AppException(_authMessage(e));
    } catch (e) {
      throw AppException(friendlyError(e));
    }

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw const AppException('Connexion impossible.');
    }

    try {
      return await fetchProfile(firebaseUser);
    } catch (e) {
      await _auth.signOut();
      throw AppException(friendlyError(e));
    }
  }

  Future<void> logout() => _auth.signOut();

  // ───────────────────────────── Profil ─────────────────────────────
  /// Lit le profil Firestore. S'il n'existe pas (inscription interrompue),
  /// un profil client de base est créé automatiquement.
  Future<UserModel> fetchProfile(User firebaseUser) async {
    final ref = _users.doc(firebaseUser.uid);
    final snapshot = await ref.get();
    final data = snapshot.data();

    if (snapshot.exists && data != null) {
      return UserModel.fromMap(data, snapshot.id);
    }

    final email = firebaseUser.email ?? '';
    final profile = UserModel(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ??
          (email.isNotEmpty ? email.split('@').first : 'Client'),
      email: email,
      phone: '',
      role: AppConstants.roleClient,
      createdAt: DateTime.now(),
    );
    await ref.set(profile.toMap());
    return profile;
  }

  Future<UserModel> updateProfile(
    UserModel current, {
    required String name,
    required String phone,
    String? whatsappNumber,
  }) async {
    final data = <String, dynamic>{
      'name': name.trim(),
      'phone': normalizePhone(phone),
    };
    String? newWhatsapp;
    if (current.isSeller) {
      newWhatsapp =
          whatsappNumber == null ? null : normalizePhone(whatsappNumber);
      data['whatsappNumber'] = newWhatsapp;
    }

    try {
      await _users.doc(current.uid).update(data);
    } catch (e) {
      throw AppException(friendlyError(e));
    }

    return current.copyWith(
      name: name.trim(),
      phone: normalizePhone(phone),
      whatsappNumber: newWhatsapp,
    );
  }

  // ───────────────────────── Messages d'erreur Auth ─────────────────────────
  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'weak-password':
        return 'Mot de passe trop faible (minimum 6 caractères).';
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Email ou mot de passe incorrect.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez dans quelques minutes.';
      case 'network-request-failed':
        return 'Réseau indisponible. Vérifiez votre connexion internet.';
      case 'operation-not-allowed':
        return 'La connexion par email/mot de passe n\'est pas activée dans '
            'Firebase Authentication (console Firebase → Authentication → Sign-in method).';
      case 'api-key-not-valid':
      case 'invalid-api-key':
        return 'Clé API Firebase invalide. Vérifiez lib/firebase_options.dart.';
      default:
        return 'Erreur d\'authentification (${e.code}) : ${e.message ?? ''}';
    }
  }
}
