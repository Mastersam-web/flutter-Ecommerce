import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../utils/app_exception.dart';

/// Résultat d'un envoi d'image.
class ImageUploadResult {
  const ImageUploadResult({required this.url, required this.usedFallback});

  /// URL https Firebase Storage, ou "data URL" base64 en mode secours.
  final String url;

  /// `true` si Firebase Storage n'était pas disponible et que l'image a été
  /// stockée directement dans le document Firestore du produit.
  final bool usedFallback;
}

/// Envoi des images de produits.
///
/// Fonctionne sur le Web ET sur mobile (on envoie des octets, pas un `File`).
class StorageService {
  static const int _maxFallbackBytes = 600 * 1024;
  final Uuid _uuid = const Uuid();

  /// Envoie l'image dans Firebase Storage (`products/{sellerId}/{uuid}.jpg`).
  ///
  /// Si Storage est indisponible (ex. projet sans plan Blaze, règles non
  /// publiées, hors-ligne), l'image est enregistrée en base64 dans Firestore
  /// afin que le produit reste persistant et visible après redémarrage.
  Future<ImageUploadResult> uploadProductImage({
    required Uint8List bytes,
    required String sellerId,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final extension = contentType == 'image/png' ? 'png' : 'jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('products/$sellerId/${_uuid.v4()}.$extension');

      final task = ref.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );

      final snapshot = await task.timeout(
        const Duration(seconds: 25),
        onTimeout: () {
          task.cancel();
          throw TimeoutException('Envoi de l\'image trop long');
        },
      );
      final url = await snapshot.ref.getDownloadURL();
      return ImageUploadResult(url: url, usedFallback: false);
    } catch (_) {
      if (bytes.length > _maxFallbackBytes) {
        throw const AppException(
          'Firebase Storage est indisponible et l\'image est trop volumineuse '
          'pour le mode de secours (max 600 Ko). Choisissez une image plus légère.',
        );
      }
      final dataUrl = 'data:$contentType;base64,${base64Encode(bytes)}';
      return ImageUploadResult(url: dataUrl, usedFallback: true);
    }
  }

  /// Supprime une image du Storage (sans effet pour les images de secours).
  Future<void> deleteImage(String imageUrl) async {
    if (!imageUrl.startsWith('https://') && !imageUrl.startsWith('gs://')) {
      return;
    }
    try {
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
    } catch (_) {
      // L'image n'existe peut-être plus : on ignore.
    }
  }
}
