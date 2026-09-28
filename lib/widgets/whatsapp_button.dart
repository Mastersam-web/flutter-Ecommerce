import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/order_model.dart';
import '../services/whatsapp_service.dart';
import '../utils/helpers.dart';

/// Bouton "Envoyer la commande via WhatsApp".
///
/// Si WhatsApp n'est pas installé (ou ne peut pas s'ouvrir), l'application ne
/// plante pas : un message explicatif est affiché, avec la possibilité de
/// copier le texte de la commande.
class WhatsAppOrderButton extends StatelessWidget {
  const WhatsAppOrderButton({
    super.key,
    required this.order,
    this.label = 'Envoyer la commande via WhatsApp',
  });

  final OrderModel order;
  final String label;

  Future<void> _send(BuildContext context) async {
    final result = await WhatsAppService.sendOrder(order);
    if (!context.mounted) return;

    switch (result) {
      case WhatsAppResult.opened:
        break;
      case WhatsAppResult.noSellerNumber:
        showAppSnackBar(
          context,
          'Le vendeur n\'a pas renseigné de numéro WhatsApp.',
          isError: true,
        );
        break;
      case WhatsAppResult.unavailable:
        await _showUnavailableDialog(context);
        break;
    }
  }

  Future<void> _showUnavailableDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.chat_bubble_outline,
          color: Color(0xFF25D366),
          size: 40,
        ),
        title: const Text('WhatsApp indisponible'),
        content: const Text(
          'WhatsApp n\'est pas installé (ou ne peut pas être ouvert) sur cet '
          'appareil.\n\nInstallez WhatsApp puis réessayez. Vous pouvez aussi '
          'copier le message et l\'envoyer manuellement au vendeur.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: WhatsAppService.buildOrderMessage(order)),
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (context.mounted) {
                showAppSnackBar(context, 'Message copié dans le presse-papiers');
              }
            },
            child: const Text('Copier le message'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () => _send(context),
        icon: const Icon(Icons.chat),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
