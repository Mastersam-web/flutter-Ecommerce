import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/product_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/error_messages.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/app_image.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/form_helpers.dart';

/// Formulaire de création (product == null) ou de modification d'un produit.
/// Utilisé par CreateProductScreen et EditProductScreen.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final ProductModel? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;

  final ProductService _productService = ProductService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  String _imageMime = 'image/jpeg';
  String? _categoryId;
  String? _categoryName;
  String _currency = 'BIF';
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(
      text: p == null
          ? ''
          : (p.price == p.price.roundToDouble()
              ? p.price.toStringAsFixed(0)
              : p.price.toString()),
    );
    _stockController = TextEditingController(text: p?.stock.toString() ?? '');
    _categoryId = p?.categoryId;
    _categoryName = p?.categoryName;
    _currency = p?.currency ?? 'BIF';

    // Crée les catégories par défaut dans Firestore si besoin (sans bloquer).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _productService.seedDefaultCategories().catchError((Object e) {
        debugPrint('Catégories par défaut non créées : $e');
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 75,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      final mime = picked.mimeType;
      setState(() {
        _imageBytes = bytes;
        _imageMime =
            (mime != null && mime.startsWith('image/')) ? mime : 'image/jpeg';
      });
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Impossible de sélectionner l\'image : $e',
          isError: true);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().user;
    if (user == null || !user.isSeller) {
      showAppSnackBar(context, 'Seul un vendeur connecté peut gérer des produits.',
          isError: true);
      return;
    }
    final existing = widget.product;
    if (existing != null && existing.sellerId != user.uid) {
      showAppSnackBar(
          context, 'Vous ne pouvez pas modifier le produit d\'un autre vendeur.',
          isError: true);
      return;
    }
    if ((user.whatsappNumber ?? '').isEmpty) {
      showAppSnackBar(
          context, 'Renseignez d\'abord votre numéro WhatsApp dans votre profil.',
          isError: true);
      return;
    }
    if (!_isEdit && _imageBytes == null) {
      showAppSnackBar(context, 'Veuillez sélectionner une image du produit.',
          isError: true);
      return;
    }
    if (_categoryId == null) {
      showAppSnackBar(context, 'Veuillez choisir une catégorie.', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      var imageUrl = existing?.imageUrl ?? '';
      var usedFallback = false;

      if (_imageBytes != null) {
        final result = await _storageService.uploadProductImage(
          bytes: _imageBytes!,
          sellerId: user.uid,
          contentType: _imageMime,
        );
        imageUrl = result.url;
        usedFallback = result.usedFallback;
      }

      final price = double.parse(_priceController.text.trim().replaceAll(',', '.'));
      final stock = int.parse(_stockController.text.trim());

      if (existing == null) {
        await _productService.createProduct(ProductModel(
          id: '',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          currency: _currency,
          categoryId: _categoryId!,
          categoryName: _categoryName ?? '',
          stock: stock,
          imageUrl: imageUrl,
          sellerId: user.uid,
          sellerName: user.name,
          sellerWhatsapp: user.whatsappNumber ?? '',
          createdAt: DateTime.now(),
        ));
      } else {
        await _productService.updateProduct(existing.id, {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': price,
          'currency': _currency,
          'categoryId': _categoryId,
          'categoryName': _categoryName ?? '',
          'stock': stock,
          'imageUrl': imageUrl,
        });
        if (_imageBytes != null && existing.imageUrl != imageUrl) {
          await _storageService.deleteImage(existing.imageUrl);
        }
      }

      if (!mounted) return;
      showAppSnackBar(
        context,
        _isEdit ? 'Produit mis à jour avec succès' : 'Produit créé avec succès !',
      );
      if (usedFallback) {
        showAppSnackBar(
          context,
          'Firebase Storage indisponible : l\'image a été enregistrée directement dans Firestore.',
        );
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, friendlyError(e), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _imagePicker() {
    Widget content;
    if (_imageBytes != null) {
      content = Image.memory(_imageBytes!, fit: BoxFit.cover);
    } else if (_isEdit && widget.product!.imageUrl.isNotEmpty) {
      content = AppImage(url: widget.product!.imageUrl, fit: BoxFit.cover);
    } else {
      content = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text('Ajouter une image', style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    return Center(
      child: GestureDetector(
        onTap: _saving ? null : _pickImage,
        child: Container(
          width: 180,
          height: 180,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: content,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductProvider>().categories;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier le produit' : 'Nouveau produit'),
      ),
      body: SafeArea(
        child: CenteredBox(
          maxWidth: 640,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _imagePicker(),
                  if (_isEdit)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Center(
                        child: Text('Touchez l\'image pour la changer',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                    ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: appInputDecoration(
                        label: 'Nom du produit *', icon: Icons.shopping_bag),
                    validator: (v) => Validators.required(v, 'Le nom'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    enabled: !_saving,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: appInputDecoration(
                        label: 'Description *', icon: Icons.description),
                    validator: (v) => Validators.required(v, 'La description'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,\-]')),
                          ],
                          decoration: appInputDecoration(
                              label: 'Prix *', icon: Icons.attach_money),
                          validator: Validators.price,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
                          ],
                          decoration: appInputDecoration(
                              label: 'Stock *', icon: Icons.inventory),
                          validator: Validators.stock,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Devise du prix',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: AppConstants.currencies.map((c) {
                      return ChoiceChip(
                        label: Text(c),
                        selected: _currency == c,
                        onSelected:
                            _saving ? null : (_) => setState(() => _currency = c),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Catégorie *',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: categories.map((cat) {
                      return ChoiceChip(
                        label: Text(cat.name),
                        selected: _categoryId == cat.id,
                        onSelected: _saving
                            ? null
                            : (_) => setState(() {
                                  _categoryId = cat.id;
                                  _categoryName = cat.name;
                                }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  CustomButton(
                    text: _isEdit ? 'Enregistrer les modifications' : 'Créer le produit',
                    icon: Icons.save,
                    isLoading: _saving,
                    onPressed: _save,
                  ),
                  if (_saving)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Center(
                        child: Text('Enregistrement en cours (envoi de l\'image)…',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
