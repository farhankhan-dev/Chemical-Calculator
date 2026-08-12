import 'element_category.dart';

class ElementModel {
  final int atomicNumber;
  final String symbol;
  final String name;
  final double atomicMass;
  final ElementCategory category;
  final int group; // 1 to 18 (0 for Lanthanides/Actinides if unnumbered)
  final int period; // 1 to 7
  final String block; // s, p, d, f
  final String stateAtRoomTemp; // Solid, Liquid, Gas, Unknown
  final String electronConfiguration;
  final double? electronegativity;
  final String oxidationStates;
  final double? meltingPoint; // in °C
  final double? boilingPoint; // in °C
  final double? density; // g/cm³ or g/L
  final String discoveryYear;
  final String discoverer;
  final String description;
  final List<String> keyFacts;

  const ElementModel({
    required this.atomicNumber,
    required this.symbol,
    required this.name,
    required this.atomicMass,
    required this.category,
    required this.group,
    required this.period,
    required this.block,
    required this.stateAtRoomTemp,
    required this.electronConfiguration,
    this.electronegativity,
    required this.oxidationStates,
    this.meltingPoint,
    this.boilingPoint,
    this.density,
    required this.discoveryYear,
    required this.discoverer,
    required this.description,
    required this.keyFacts,
  });

  String get semanticLabel => '$name, symbol $symbol, atomic number $atomicNumber, category ${category.displayName}';
}
