import 'dart:async';

import 'package:firebase_core/firebase_core.dart' show FirebaseException;

import 'app_exception.dart';

/// Transforme n'importe quelle erreur en message compréhensible pour l'utilisateur.
String friendlyError(Object error) {
  if (error is AppException) return error.message;

  if (error is TimeoutException) {
    return 'Le serveur met trop de temps à répondre. Vérifiez votre connexion internet.';
  }

  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'Accès refusé par Firebase. Vérifiez que les règles de sécurité '
            '(firestore.rules / storage.rules) sont bien publiées et que vous '
            'êtes connecté avec le bon rôle.';
      case 'unauthenticated':
        return 'Vous devez être connecté pour effectuer cette action.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Réseau indisponible. Vérifiez votre connexion internet puis réessayez.';
      case 'not-found':
        return 'Élément introuvable (il a peut-être été supprimé).';
      case 'failed-precondition':
        return 'Opération impossible pour le moment (index ou configuration Firestore manquant).';
      case 'aborted':
        return 'L\'opération a été interrompue, veuillez réessayer.';
      default:
        return 'Erreur Firebase (${error.code}) : ${error.message ?? 'inconnue'}';
    }
  }

  return 'Une erreur est survenue : $error';
}
