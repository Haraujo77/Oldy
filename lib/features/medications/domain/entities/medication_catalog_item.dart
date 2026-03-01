class MedicationCatalogItem {
  final String id;
  final String name;
  final String? activeIngredient;
  final List<String> presentations;
  final bool isGeneric;

  const MedicationCatalogItem({
    required this.id,
    required this.name,
    this.activeIngredient,
    this.presentations = const [],
    this.isGeneric = false,
  });

  factory MedicationCatalogItem.fromMap(Map<String, dynamic> map) {
    return MedicationCatalogItem(
      id: map['id'] as String,
      name: map['name'] as String,
      activeIngredient: map['activeIngredient'] as String?,
      presentations: List<String>.from(map['presentations'] ?? []),
      isGeneric: map['isGeneric'] as bool? ?? false,
    );
  }
}
