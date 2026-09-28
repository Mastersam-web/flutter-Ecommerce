import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Affiche une image de produit, quelle que soit sa source :
///  - URL https (Firebase Storage),
///  - "data URL" base64 (mode secours quand Storage est indisponible),
///  - chaîne vide → icône par défaut.
///
/// Ne plante jamais : en cas d'erreur, une icône est affichée.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.iconSize = 36,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double iconSize;

  static final Map<String, Uint8List> _memoryCache = <String, Uint8List>{};

  Uint8List? _decodeDataUrl() {
    final cached = _memoryCache[url];
    if (cached != null) return cached;
    try {
      final comma = url.indexOf(',');
      if (comma < 0) return null;
      final bytes = base64Decode(url.substring(comma + 1));
      if (_memoryCache.length > 80) {
        _memoryCache.remove(_memoryCache.keys.first);
      }
      _memoryCache[url] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Widget _placeholder(IconData icon) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder(Icons.image_outlined);

    if (url.startsWith('data:')) {
      final bytes = _decodeDataUrl();
      if (bytes == null) return _placeholder(Icons.broken_image_outlined);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            _placeholder(Icons.broken_image_outlined),
      );
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade100,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) =>
          _placeholder(Icons.image_not_supported_outlined),
    );
  }
}
