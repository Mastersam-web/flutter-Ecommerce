import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../utils/constants.dart';

/// Accès Firestore aux produits et aux catégories.
///
/// Les requêtes évitent volontairement `where + orderBy` (qui exigent un index
/// composite) : le tri est fait côté application.
class ProductService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection(AppConstants.productsCollection);

  CollectionReference<Map<String, dynamic>> get _categories =>
      _db.collection(AppConstants.categoriesCollection);

  List<ProductModel> _sortNewestFirst(List<ProductModel> list) {
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // ───────────────────────────── Lecture ─────────────────────────────

  /// Catalogue public : tous les produits (temps réel).
  Stream<List<ProductModel>> watchProducts() {
    return _products.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
      return _sortNewestFirst(list);
    });
  }

  /// Produits d'un vendeur (temps réel).
  Stream<List<ProductModel>> watchSellerProducts(String sellerId) {
    return _products
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
      return _sortNewestFirst(list);
    });
  }

  Stream<List<CategoryModel>> watchCategories() {
    return _categories.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  // ───────────────────────────── Écriture ─────────────────────────────

  Future<String> createProduct(ProductModel product) async {
    final ref = await _products.add(product.toMap());
    return ref.id;
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> data) {
    final payload = Map<String, dynamic>.from(data);
    payload['updatedAt'] = Timestamp.now();
    return _products.doc(productId).update(payload);
  }

  Future<void> deleteProduct(String productId) {
    return _products.doc(productId).delete();
  }

  /// Recopie le nom / WhatsApp du vendeur sur tous ses produits
  /// (ces champs sont dupliqués dans chaque produit).
  Future<void> updateSellerInfo({
    required String sellerId,
    required String sellerName,
    required String sellerWhatsapp,
  }) async {
    final snapshot =
        await _products.where('sellerId', isEqualTo: sellerId).get();
    if (snapshot.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'sellerName': sellerName,
        'sellerWhatsapp': sellerWhatsapp,
      });
    }
    await batch.commit();
  }

  /// Crée les catégories par défaut si la collection est vide (idempotent :
  /// les documents ont des identifiants fixes).
  Future<void> seedDefaultCategories() async {
    final existing = await _categories.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final category in AppConstants.defaultCategories) {
      batch.set(_categories.doc(category['id']), {
        'name': category['name'],
        'description': category['description'],
      });
    }
    await batch.commit();
  }
}
