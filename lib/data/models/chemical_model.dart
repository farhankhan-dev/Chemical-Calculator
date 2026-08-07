/// Chemical data model with JSON serialization.
///
/// Maps directly to entries in assets/data/chemicals.json.
class ChemicalModel {
  final int id;
  final String name;
  final String formula;
  final double molecularWeight;
  final double? equivalentWeight;
  final double? density;
  final double? meltingPoint;
  final double? boilingPoint;
  final String? casNumber;
  final String category;

  const ChemicalModel({
    required this.id,
    required this.name,
    required this.formula,
    required this.molecularWeight,
    this.equivalentWeight,
    this.density,
    this.meltingPoint,
    this.boilingPoint,
    this.casNumber,
    required this.category,
  });

  factory ChemicalModel.fromJson(Map<String, dynamic> json) {
    return ChemicalModel(
      id: json['id'] as int,
      name: json['name'] as String,
      formula: json['formula'] as String,
      molecularWeight: (json['molecularWeight'] as num).toDouble(),
      equivalentWeight: json['equivalentWeight'] != null
          ? (json['equivalentWeight'] as num).toDouble()
          : null,
      density: json['density'] != null
          ? (json['density'] as num).toDouble()
          : null,
      meltingPoint: json['meltingPoint'] != null
          ? (json['meltingPoint'] as num).toDouble()
          : null,
      boilingPoint: json['boilingPoint'] != null
          ? (json['boilingPoint'] as num).toDouble()
          : null,
      casNumber: json['casNumber'] as String?,
      category: json['category'] as String? ?? 'Other',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'formula': formula,
      'molecularWeight': molecularWeight,
      'equivalentWeight': equivalentWeight,
      'density': density,
      'meltingPoint': meltingPoint,
      'boilingPoint': boilingPoint,
      'casNumber': casNumber,
      'category': category,
    };
  }

  @override
  String toString() => 'ChemicalModel($name, $formula)';
}
