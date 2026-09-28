import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import 'product_form_screen.dart';

/// Écran « Modifier un produit » (formulaire partagé avec la création).
class EditProductScreen extends StatelessWidget {
  const EditProductScreen({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) => ProductFormScreen(product: product);
}
