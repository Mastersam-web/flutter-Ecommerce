import 'package:flutter/material.dart';

/// Carte sélectionnable (mode de réception, moyen de paiement…).
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? color : Colors.grey.shade300,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: selected ? color : Colors.grey),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: Icon(
          selected ? Icons.check_circle : Icons.radio_button_unchecked,
          color: selected ? color : Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
