/// Data model representing a user's custom chemical entry in the personal notebook.
class CustomChemicalModel {
  final String id;
  final String name;
  final String formula;
  final double molecularWeight;
  final DateTime createdAt;
  final bool isPinned;
  final Map<String, String> customFields;

  const CustomChemicalModel({
    required this.id,
    required this.name,
    required this.formula,
    required this.molecularWeight,
    required this.createdAt,
    this.isPinned = false,
    this.customFields = const {},
  });

  factory CustomChemicalModel.fromJson(Map<String, dynamic> json) {
    return CustomChemicalModel(
      id: json['id'] as String,
      name: json['name'] as String,
      formula: json['formula'] as String,
      molecularWeight: (json['molecularWeight'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
      customFields: json['customFields'] != null
          ? Map<String, String>.from(json['customFields'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'formula': formula,
      'molecularWeight': molecularWeight,
      'createdAt': createdAt.toIso8601String(),
      'isPinned': isPinned,
      'customFields': customFields,
    };
  }

  CustomChemicalModel copyWith({
    String? id,
    String? name,
    String? formula,
    double? molecularWeight,
    DateTime? createdAt,
    bool? isPinned,
    Map<String, String>? customFields,
  }) {
    return CustomChemicalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      formula: formula ?? this.formula,
      molecularWeight: molecularWeight ?? this.molecularWeight,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
      customFields: customFields ?? this.customFields,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomChemicalModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
