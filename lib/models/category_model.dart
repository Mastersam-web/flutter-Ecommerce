/// Catégorie de produits (`categories/{id}`).
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
  });

  final String id;
  final String name;
  final String? description;

  Map<String, dynamic> toMap() {
    return {'name': name, 'description': description};
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, String docId) {
    return CategoryModel(
      id: docId,
      name: (map['name'] as String?) ?? '',
      description: map['description'] as String?,
    );
  }
}
