import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/chemical_model.dart';

/// Loads the built-in chemical database from assets/data/chemicals.json.
///
/// Read-only datasource — no user-added chemicals supported.
class ChemicalLocalDatasource {
  List<ChemicalModel>? _cache;

  bool get hasCache => _cache != null;

  /// Loads all chemicals from the JSON asset. Results are cached after
  /// the first call.
  Future<List<ChemicalModel>> getAllChemicals() async {
    if (_cache != null) return _cache!;

    final jsonString =
        await rootBundle.loadString('assets/data/chemicals.json');
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

    _cache = jsonList
        .map((e) => ChemicalModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return _cache!;
  }

  /// Search chemicals by name (case-insensitive).
  /// Returns chemicals whose name starts with or contains the query.
  /// Prefix matches are ranked first.
  Future<List<ChemicalModel>> searchByName(String query) async {
    final all = await getAllChemicals();
    if (query.trim().isEmpty) return [];

    final q = query.trim().toLowerCase();

    final prefixMatches = <ChemicalModel>[];
    final containsMatches = <ChemicalModel>[];

    for (final chem in all) {
      final nameLower = chem.name.toLowerCase();
      if (nameLower.startsWith(q)) {
        prefixMatches.add(chem);
      } else if (nameLower.contains(q)) {
        containsMatches.add(chem);
      }
    }

    return [...prefixMatches, ...containsMatches];
  }

  /// Search chemicals by name or formula.
  Future<List<ChemicalModel>> search(String query) async {
    final all = await getAllChemicals();
    if (query.trim().isEmpty) return [];

    final q = query.trim().toLowerCase();

    final prefixMatches = <ChemicalModel>[];
    final containsMatches = <ChemicalModel>[];
    final formulaMatches = <ChemicalModel>[];

    for (final chem in all) {
      final nameLower = chem.name.toLowerCase();
      final formulaLower = chem.formula.toLowerCase();

      if (nameLower.startsWith(q)) {
        prefixMatches.add(chem);
      } else if (nameLower.contains(q)) {
        containsMatches.add(chem);
      } else if (formulaLower.contains(q)) {
        formulaMatches.add(chem);
      }
    }

    return [...prefixMatches, ...containsMatches, ...formulaMatches];
  }
}
