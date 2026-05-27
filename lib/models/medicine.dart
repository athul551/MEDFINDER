class Medicine {
  Medicine({
    required this.medicineId,
    required this.name,
    required this.category,
    required this.description,
  });

  final String medicineId;
  final String name;
  final String category;
  final String description;

  factory Medicine.fromMap(Map<String, dynamic> map, {String? id}) {
    return Medicine(
      medicineId: id ?? map['medicineId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicineId,
      'name': name,
      'category': category,
      'description': description,
    };
  }
}
