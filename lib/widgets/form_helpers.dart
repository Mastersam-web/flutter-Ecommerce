import 'package:flutter/material.dart';

/// Décoration standard des champs de formulaire.
InputDecoration appInputDecoration({
  required String label,
  IconData? icon,
  String? hint,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon),
    suffixIcon: suffix,
    border: const OutlineInputBorder(),
  );
}

/// Limite la largeur du contenu (formulaires lisibles sur grand écran / navigateur).
class CenteredBox extends StatelessWidget {
  const CenteredBox({super.key, required this.child, this.maxWidth = 520});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
