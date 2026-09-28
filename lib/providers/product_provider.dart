import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../utils/constants.dart';
import '../utils/currency_helper.dart';

enum ProductSort { newest, priceAsc, priceDesc, nameAsc }

/// Catalogue public : une seule écoute Firestore, la recherche / le filtre / le
/// tri sont appliqués localement (rapide, sans index Firestore).
class ProductProvider with ChangeNotifier {
  ProductProvider({ProductService? service})
      : _service = service ?? ProductService();

  final ProductService _service;

  StreamSubscription<List<ProductModel>>? _productsSub;
  StreamSubscription<List<CategoryModel>>? _categoriesSub;

  List<ProductModel> _products = [];
  List<CategoryModel> _remoteCategories = [];
  bool _isLoading = true;
  bool _hasLoaded = false;
  bool _disposed = false;
  String? _errorMessage;

  String _searchQuery = '';
  String? _selectedCategoryId;
  ProductSort _sort = ProductSort.newest;

  // ─────────────────────────── Getters ───────────────────────────
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedCategoryId => _selectedCategoryId;
  ProductSort get sort => _sort;
  List<ProductModel> get allProducts => List.unmodifiable(_products);

  bool get hasActiveFilters =>
      _searchQuery.trim().isNotEmpty || _selectedCategoryId != null;

  /// Catégories Firestore, ou catégories par défaut tant que la collection est vide.
  List<CategoryModel> get categories {
    if (_remoteCategories.isNotEmpty) return _remoteCategories;
    return AppConstants.defaultCategories
        .map((c) => CategoryModel(
              id: c['id']!,
              name: c['name']!,
              description: c['description'],
            ))
        .toList();
  }

  List<ProductModel> get filteredProducts {
    final query = _searchQuery.trim().toLowerCase();

    final result = _products.where((product) {
      if (_selectedCategoryId != null &&
          product.categoryId != _selectedCategoryId) {
        return false;
      }
      if (query.isNotEmpty && !product.name.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    switch (_sort) {
      case ProductSort.newest:
        break; // déjà trié du plus récent au plus ancien
      case ProductSort.priceAsc:
        result.sort((a, b) => CurrencyHelper.toBIF(a.price, a.currency)
            .compareTo(CurrencyHelper.toBIF(b.price, b.currency)));
        break;
      case ProductSort.priceDesc:
        result.sort((a, b) => CurrencyHelper.toBIF(b.price, b.currency)
            .compareTo(CurrencyHelper.toBIF(a.price, a.currency)));
        break;
      case ProductSort.nameAsc:
        result.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }
    return result;
  }

  ProductModel? byId(String id) {
    for (final product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  // ─────────────────────────── Chargement ───────────────────────────

  /// Démarre l'écoute temps réel des produits et des catégories.
  void start() {
    _productsSub?.cancel();
    _categoriesSub?.cancel();

    _isLoading = true;
    _errorMessage = null;

    _productsSub = _service.watchProducts().listen(
      (products) {
        _products = products;
        _isLoading = false;
        _hasLoaded = true;
        _errorMessage = null;
        _notify();
      },
      onError: (Object error) {
        debugPrint('Erreur chargement produits : $error');
        _errorMessage = 'Impossible de charger les produits. Vérifiez votre '
            'connexion internet et les règles de sécurité Firestore.';
        _isLoading = false;
        _notify();
      },
    );

    _categoriesSub = _service.watchCategories().listen(
      (categories) {
        _remoteCategories = categories;
        _notify();
      },
      onError: (Object error) {
        debugPrint('Erreur chargement catégories : $error');
      },
    );
  }

  void retry() {
    start();
    _notify();
  }

  // ─────────────────────────── Filtres ───────────────────────────
  void setSearch(String query) {
    _searchQuery = query;
    _notify();
  }

  void setCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    _notify();
  }

  void setSort(ProductSort sort) {
    _sort = sort;
    _notify();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _productsSub?.cancel();
    _categoriesSub?.cancel();
    super.dispose();
  }
}
