import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/currency_provider.dart';
import '../utils/constants.dart';

/// Sélecteur de devise (BIF / USD / EUR) partagé par tout le panier.
class CurrencySelector extends StatelessWidget {
  const CurrencySelector({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<CurrencyProvider>().selected;

    return Wrap(
      spacing: 8,
      children: AppConstants.currencies.map((currency) {
        return ChoiceChip(
          label: Text(currency),
          selected: selected == currency,
          onSelected: (_) => context.read<CurrencyProvider>().select(currency),
        );
      }).toList(),
    );
  }
}
